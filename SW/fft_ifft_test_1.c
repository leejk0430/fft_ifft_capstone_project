
#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"  // To measure of processing time

#define AXI_DATA_BYTE 8 // 64 / 8

// REG MAP
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
#define ROOT2_DIV_2 0.70710678118
void test_hw_memcpy(void* dest, const void* source, size_t num){
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
void FFT(s8* source, float* X_real, float* X_imag) {
    X_real[0] = source[0] + source[1] + source[2] + source[3] + source[4] + source[5] + source[6] + source[7];
    X_imag[0] = 0;
    X_real[1] = source[0] - source[4] + (source[1] - source[3] - source[5] + source[7]) * ROOT2_DIV_2;
    X_imag[1] = source[6] - source[2] + (source[5] - source[1] - source[3] + source[7]) * ROOT2_DIV_2;
    X_real[2] = source[0] - source[2] + source[4] - source[6];
    X_imag[2] = source[3] - source[1] + source[7] - source[5];
    X_real[3] = source[0] - source[4] + (-source[1] + source[3] + source[5] - source[7]) * ROOT2_DIV_2;
    X_imag[3] = source[2] - source[6] + (source[5] - source[1] - source[3] + source[7]) * ROOT2_DIV_2;
    X_real[4] = source[0] - source[1] + source[2] - source[3] + source[4] - source[5] + source[6] - source[7];
    X_imag[4] = 0;
    X_real[5] = source[0] - source[4] + (-source[1] + source[3] + source[5] - source[7]) * ROOT2_DIV_2;
    X_imag[5] = source[6] - source[2] + (-source[5] + source[1] + source[3] - source[7]) * ROOT2_DIV_2;
    X_real[6] = source[0] - source[2] + source[4] - source[6];
    X_imag[6] = -source[3] + source[1] - source[7] + source[5];
    X_real[7] = source[0] - source[4] + (source[1] - source[3] - source[5] + source[7]) * ROOT2_DIV_2;
    X_imag[7] = source[2] - source[6] + (-source[5] + source[1] + source[3] - source[7]) * ROOT2_DIV_2;
}
void IFFT(s8* x, float* X_real, float* X_imag) {
    x[0] = (s8)((X_real[0] + X_real[1] + X_real[2] + X_real[3] + X_real[4] + X_real[5] + X_real[6] + X_real[7]) / 8.0);
    x[4] = (s8)((X_real[0] - X_real[1] + X_real[2] - X_real[3] + X_real[4] - X_real[5] + X_real[6] - X_real[7]) / 8.0);
    x[2] = (s8)((X_real[0] - X_imag[1] - X_real[2] + X_imag[3] + X_real[4] - X_imag[5] - X_real[6] + X_imag[7]) / 8.0);
    x[6] = (s8)((X_real[0] + X_imag[1] - X_real[2] - X_imag[3] + X_real[4] + X_imag[5] - X_real[6] - X_imag[7]) / 8.0);
    x[1] = (s8)(((X_real[0] - X_imag[2] - X_real[4] + X_imag[6]) + ((X_real[1] - X_real[5] - X_imag[1] + X_imag[5] + X_real[7] - X_real[3] + X_imag[7] - X_imag[3]) * ROOT2_DIV_2)) / 8.0);
    x[5] = (s8)(((X_real[0] - X_imag[2] - X_real[4] + X_imag[6]) + ((-X_real[1] + X_real[5] + X_imag[1] - X_imag[5] - X_real[7] + X_real[3] - X_imag[7] + X_imag[3]) * ROOT2_DIV_2)) / 8.0);
    x[3] = (s8)(((X_real[0] + X_imag[2] - X_real[4] - X_imag[6]) + ((-X_real[1] + X_real[5] - X_imag[1] + X_imag[5] - X_real[7] + X_real[3] + X_imag[7] - X_imag[3]) * ROOT2_DIV_2)) / 8.0);
    x[7] = (s8)(((X_real[0] + X_imag[2] - X_real[4] - X_imag[6]) + ((X_real[1] - X_real[5] + X_imag[1] - X_imag[5] + X_real[7] - X_real[3] - X_imag[7] + X_imag[3]) * ROOT2_DIV_2)) / 8.0);
}

int main() {
    u32 transfer_cnt;
    XTime tStart, tEnd;
    while (1) {
///////////////////////////////////////////////////////////////////////
//////////// HW fft_ifft //////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
    	printf("======= mem_copy_test ======\n");
    	do{
        	printf("plz input transfer_cnt\n");
        	scanf("%u",&transfer_cnt);
    	}while( !( (0 < transfer_cnt) && (transfer_cnt%AXI_DATA_BYTE == 0) && (transfer_cnt <= 67108864) ) ); // 64 *(2^20) = 64 MBytes // max count 32-6 = 26. 2^26 = 64MBytes

    	u8* rdma_baseaddr = (u8*) BASE_ADDR;
    	u8* wdma_baseaddr = (u8*) (BASE_ADDR + transfer_cnt);

    	// init data.
    	for(int addr = 0; addr < transfer_cnt; addr++){
			s8 data;
			if(addr %2 == 0){
    			data = 1;
			}
			else{
				data = -1;
			}
    		rdma_baseaddr[addr] = data;
    	}
    	Xil_DCacheDisable(); // flush to external mem.
    	float transfer_bytes_display = transfer_cnt/1024/1024;
    	printf("rdma_baseaddr : 0x%x\n", rdma_baseaddr);
    	printf("wdma_baseaddr : 0x%x\n", wdma_baseaddr);
    	printf("transfer_cnt size : %f Mbytes\n", transfer_bytes_display);

    	Xil_Out32((XPAR_DMA_IP_TOP_0_BASEADDR) + ADDR_AXI00_PTR0_DATA_0, (u32)(0x00000000)); // base addr no use now.

    	XTime_GetTime(&tStart);
    	test_hw_memcpy(wdma_baseaddr, rdma_baseaddr, transfer_cnt);
    	XTime_GetTime(&tEnd);
		printf("HW Mem Copy function Time %.2f us.\n",
		       1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
///////////////////////////////////////////////////////////////////////
//////////// SW fft_ifft //////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
    	XTime_GetTime(&tStart);
		float X_real[8];
        float X_imag[8];
        s8 x[8];
		for(int addr = 0; addr < transfer_cnt; addr += 8){
        	FFT(rdma_baseaddr + addr,X_real, X_imag);
        	IFFT(x, X_real, X_imag);
		}
    	XTime_GetTime(&tEnd);
		printf("SW fft_ifft function Time %.2f us.\n",
		       1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));
    }
    return 0;
}
