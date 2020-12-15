/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xaxidma.h"
#include "sleep.h"

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#define DDR_BASE_ADDR XPAR_PS7_DDR_0_S_AXI_BASEADDR
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x01000000)

#define RX_BD_SPACE_BASE (MEM_BASE_ADDR + 0x00001000)
#define RX_BD_SPACE_HIGH (MEM_BASE_ADDR + 0x00001FFF)

#define RX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH (MEM_BASE_ADDR + 0x004FFFFF)

#define PACKET_LENGTH 128

XAxiDma AxiDma;

static int RxSetup(XAxiDma* AxiDmaInstPtr);

int main()
{
	int status;
	int i = 0;
	XAxiDma_Config* dma_conf;
	XAxiDma_Bd* bd_ptr = (XAxiDma_Bd*) RX_BD_SPACE_BASE;


    init_platform();

    printf("Hello World\r\n");

    // DMA configuration
    dma_conf = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!dma_conf) {
    	printf("No config found for %d\r\n", DMA_DEV_ID);
    	return XST_FAILURE;
    }

    status = XAxiDma_CfgInitialize(&AxiDma, dma_conf);
    if (status != XST_SUCCESS){
    	printf("Initialization failed %d\r\n", status);
    	return XST_FAILURE;
    }

    // RX initialization
    status = RxSetup(&AxiDma);
    if (status != XST_SUCCESS){
    	printf("RX setup failure %d\r\n", status);
    	return XST_FAILURE;
    }

    printf("BD info\r\n");
    for(i=0; i < 10; i++){
    	printf("%02d: %08x\n", i, Xil_In32(RX_BD_SPACE_BASE + 4*i));
    }

    printf("DEBUG 0x30: %08x\n", Xil_In32(XPAR_AXIDMA_0_BASEADDR + 0x30));
    printf("DEBUG 0x34: %08x\n", Xil_In32(XPAR_AXIDMA_0_BASEADDR + 0x34));

    while (1) {
    	getchar();
    	Xil_Out32(XPAR_AXI_GPIO_0_BASEADDR, 0xFFFFFFFF);
    	printf("STATUS: 0x%x\n", Xil_In32(RX_BD_SPACE_BASE + 4*7));
    	getchar();
    	Xil_Out32(XPAR_AXI_GPIO_0_BASEADDR, 0x00000000);
    	printf("STATUS: 0x%x\n", Xil_In32(RX_BD_SPACE_BASE + 4*7));
    }

    cleanup_platform();
    return 0;
}

static int RxSetup(XAxiDma* AxiDmaInstPtr){
	XAxiDma_BdRing* rx_ring_ptr;
	int delay = 0;
	int coalesce = 1;
	int status;

	XAxiDma_Bd bd_template;
	XAxiDma_Bd* bd_ptr;
	XAxiDma_Bd* bd_cur_ptr;

	u32 bd_count;
	u32 free_bd_count;
	UINTPTR rx_buffer_ptr;

	int index;

	rx_ring_ptr = XAxiDma_GetRxRing(&AxiDma);

	XAxiDma_BdRingIntDisable(rx_ring_ptr, XAXIDMA_IRQ_ALL_MASK);

	XAxiDma_BdRingSetCoalesce(rx_ring_ptr, coalesce, delay);

	// bd_count = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT,
    //  							     RX_BD_SPACE_HIGH - RX_BD_SPACE_BASE + 1);

	status = XAxiDma_BdRingCreate(rx_ring_ptr,
								  RX_BD_SPACE_BASE,
								  RX_BD_SPACE_BASE,
								  XAXIDMA_BD_MINIMUM_ALIGNMENT,
								  1);

	if (status != XST_SUCCESS){
		printf("RX create BD ring failed %d\r\n", status);
		return XST_FAILURE;
	}

	XAxiDma_BdClear(&bd_template);
	status = XAxiDma_BdRingClone(rx_ring_ptr, &bd_template);

	if (status != XST_SUCCESS){
		printf("RX clone BD ring failed %d\r\n", status);
		return XST_FAILURE;
	}

	status = XAxiDma_BdRingAlloc(rx_ring_ptr, 1, &bd_ptr);

	if (status != XST_SUCCESS){
		printf("RX allocate BD ring failed %d\r\n", status);
		return XST_FAILURE;
	}

	XAxiDma_BdRingEnableCyclicDMA(rx_ring_ptr);
    XAxiDma_SelectCyclicMode(AxiDmaInstPtr, XAXIDMA_DEVICE_TO_DMA, 1);

    // BD setup
    status = XAxiDma_BdSetBufAddr(bd_ptr, RX_BUFFER_BASE);
    if (status != XST_SUCCESS) {
		printf("XAxiDma_BdSetBufAddr failed %d\r\n", status);
		return XST_FAILURE;
    }


    status = XAxiDma_BdSetLength(bd_ptr, PACKET_LENGTH, rx_ring_ptr->MaxTransferLen);
	if (status != XST_SUCCESS) {
		printf("Rx set length %d on BD %x failed %d\r\n",
		       PACKET_LENGTH, (UINTPTR)RX_BUFFER_BASE, status);
		return XST_FAILURE;
	}

	XAxiDma_BdSetCtrl(bd_ptr, 0);
	XAxiDma_BdSetId(bd_ptr, RX_BUFFER_BASE);

	memset((void*) RX_BUFFER_BASE, 0, PACKET_LENGTH);

	status = XAxiDma_BdRingToHw(rx_ring_ptr, 1, bd_ptr);
	if (status != XST_SUCCESS) {
		printf("Rx start hw failed %d\r\n", status);
		return XST_FAILURE;
	}

	status = XAxiDma_BdRingStart(rx_ring_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("RX start hw failed %d\r\n", status);
		return XST_FAILURE;
	}


	return XST_SUCCESS;
}
