#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"
#include "short_3khz_noise_c.h"



#define ADDR_AP_CTRL                    0x00
//#define ADDR_GIE                        0x04
//#define ADDR_IER                        0x08
//#define ADDR_ISR                        0x0c
#define ADDR_RDMA_TRANSFER_BYTE_DATA_0  0x10
#define ADDR_RDMA_MEM_PTR_DATA_0        0x14
#define ADDR_WDMA_TRANSFER_BYTE_DATA_0  0x18
#define ADDR_WDMA_MEM_PTR_DATA_0        0x1c
#define ADDR_AXI00_PTR0_DATA_0          0x20

#define CTRL_DONE_MASK                  0x00000002
#define CTRL_IDLE_MASK                  0x00000004

#define BASE_ADDR 0x10000000



void test_filter(void* dest, const void* source, size_t num){
    u32 read_data;
	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_RDMA_TRANSFER_BYTE_DATA_0, (u32)num);
	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_RDMA_MEM_PTR_DATA_0, (u32) source );
	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_WDMA_TRANSFER_BYTE_DATA_0, (u32)num);
	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_WDMA_MEM_PTR_DATA_0, (u32) dest);

	while(1) {
		read_data = Xil_In32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_AP_CTRL);
	    if( (read_data & CTRL_IDLE_MASK) == CTRL_IDLE_MASK ) // IDLE
	    	break;
	}
	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_AP_CTRL, (u32)(0x00000001)); // Start !!

 	while(1) {
		read_data = Xil_In32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_AP_CTRL);
	    if( (read_data & CTRL_DONE_MASK) == CTRL_DONE_MASK ) // DONE
	    	break;
    }
}

int main() {
    u32 transfer_cnt;
    XTime tStart, tEnd;
    transfer_cnt = short_save_noisy_file_3khz_noise_wav_size - 44;
    printf("=========audio 3khz filter test============\n");

    char confirm;
    do{
        printf("The size of audio file you are trying to filter is %u(bytes)\n", transfer_cnt);
        printf("If that is right ,please type y:\n");
        scanf(" %c", &confirm);     
    }while(!(confirm=='y'));


    s8* rdma_baseaddr = (s8*) BASE_ADDR;
    s8* wdma_baseaddr = (s8*) (BASE_ADDR + transfer_cnt);
    
    ////////////initial data///////////////////////////

    for(u32 i = 0; i < transfer_cnt; i++) {
        rdma_baseaddr[i] = (signed char)(short_save_noisy_file_3khz_noise_wav[i + 44] - 128);
    }

    ///////////////////////////////////////


    Xil_DCacheDisable(); // flush to external mem.
    float transfer_bytes_display = transfer_cnt/1024.0/1024.0;
    printf("rdma_baseaddr : 0x%x\n", rdma_baseaddr);
    printf("wdma_baseaddr : 0x%x\n", wdma_baseaddr);
    printf("transfer_cnt size : %f Mbytes\n", transfer_bytes_display);

    Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_AXI00_PTR0_DATA_0, (u32)(0x00000000)); // base addr no use now.

    XTime_GetTime(&tStart);
    test_filter(wdma_baseaddr, rdma_baseaddr, transfer_cnt);
    XTime_GetTime(&tEnd);
	printf("HW fft_ifft_filter function Time %.2f us.\n",
	1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));





    Xil_DCacheInvalidateRange((INTPTR)wdma_baseaddr, transfer_cnt); // Invalidate cache for read consistency

    //////////////read the data//////////////////////////////////
    signed char wave_data_array_signed[transfer_cnt];
    
    for(u32 i = 0 ; i <  transfer_cnt; i++) {
        wave_data_array_signed[i] = wdma_baseaddr[i];
    }
    printf("read the filtered file");


 
    /////////////////change to unsigned//////////////////////////   
    unsigned char wav_data_unsigned[transfer_cnt];

    for(u32 i = 0; i < transfer_cnt; i++) {
       wav_data_unsigned[i] = (unsigned char)(wave_data_array_signed[i] + 128);
    }

    printf("changed read file to unsigned");

    ///////////////c file write/////////////////////////////////



    FILE *c_file = fopen("short_3khz_filtered_data.c", "w");
    if (c_file == NULL) {
        printf("Error opening c_file\n");
        return 1;
    }

    unsigned char wav_header[44] = {
        0x52, 0x49, 0x46, 0x46, 0x03, 0x20, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
        0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x40, 0x1F, 0x00, 0x00, 0x40, 0x1F, 0x00, 0x00,
        0x01, 0x00, 0x08, 0x00, 0x64, 0x61, 0x74, 0x61, 0xDF, 0x1F, 0x00, 0x00
    };

    fprintf(c_file, "const long int short_3khz_filtered_data_wave_size = %u;\n", transfer_cnt + 44);
    fprintf(c_file, "unsigned char short_3khz_filtered_data_wave[%u] = {\n", transfer_cnt+ 44);

    for (u32 i = 0; i < transfer_cnt + 44; i++) {
        if (i < 44 ) {
            fprintf(c_file, "0x%02x, ", wav_header[i]);
            if ((i+1) % 16 == 0) {
                fprintf(c_file, "\n");
            }
        }
        else {
            fprintf(c_file, "0x%02x ", wav_data_unsigned[i - 44]);
            if (i < transfer_cnt + 44 - 1) {  
                fprintf(c_file, ", ");
            }
            if ((i + 1) % 16 == 0) {
                fprintf(c_file, "\n   ");
            }
        }
    }

    fprintf(c_file, "\n};\n");
    fclose(c_file);

    printf("finished writing c file\n");

    //////////////////header file write//////////////////////////////////

    FILE *h_file = fopen("short_3khz_filtered_data.h", "w");
    if (h_file == NULL) {
        printf("Error opening h_file\n");
        return 1;
    }
    fprintf(h_file, "#/* Generated by bin2c, do not edit manually */\n");
    fprintf(h_file, "#ifndef __short_3khz_filtered_data_h_included\n");
    fprintf(h_file, "#define __short_3khz_filtered_data_h_included\n\n");
    fprintf(h_file, "/* Contents of file short_3khz_filtered_data.wav */\n");
    fprintf(h_file, "extern const long int short_3khz_filtered_data_wav_size;\n");
    fprintf(h_file, "extern const unsigned char short_3khz_filtered_data_wav[%u];\n\n", transfer_cnt + 44);
    fprintf(h_file, "#endif    /* __short_3khz_filtered_data_h_included */");

    printf("finsished writing h file\n");
    ///////////////////////////////////////////////



    return 0;
}
