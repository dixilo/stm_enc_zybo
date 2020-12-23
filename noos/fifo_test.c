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
#include "xil_io.h"
#include "sleep.h"


#pragma pack(1)
typedef struct {
    u32 ts_1;
    u32 ts_0;
    u32 state;
} tcp_data;
#pragma pack()

int main()
{
	u32 ret_val;
	u32 read_length;
	u32 tmp_st;
	int i;
	int kai;
	tcp_data data[2048];

    init_platform();

    print("Hello World\n\r");
    Xil_Out32(XPAR_AXI_GPIO_BASEADDR, 0);
    xil_printf("Fifo initialization.\r\n");
	ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);
	xil_printf("[ISR ]: %08x\r\n", ret_val);
	Xil_Out32(XPAR_AXI_FIFO_0_BASEADDR + 0x00, 0xFFFFFFFF);
	ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);
	xil_printf("[ISR ]: %08x\r\n", ret_val);
	ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x04);
	xil_printf("[IER ]: %08x\r\n", ret_val);
	ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x1C);
	xil_printf("[RDFO]: %08x\r\n", ret_val);

    xil_printf("FIFO reset\r\n");
    Xil_Out32(XPAR_AXI_FIFO_0_BASEADDR + 0x18, 0x000000A5);
    while(1){
        ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);
        if(ret_val & (1<<23)){
            Xil_Out32(XPAR_AXI_FIFO_0_BASEADDR + 0x00, (1<<23) + (1<<19));
            break;
        }
    }
    xil_printf("FIFO reset fin.\r\n");

    kai = 0;

    while (1){
    	if ((kai % 10 ) == 0) {
    		tmp_st = Xil_In32(XPAR_AXI_GPIO_BASEADDR);
    		xil_printf("fire!\r\n");
    		Xil_Out32(XPAR_AXI_GPIO_BASEADDR, tmp_st + 1);
    	}
    	kai++;

		while(1){ // Wait until at least one successful receive has completed
			ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00); // Interrupt Status Register
			if(ret_val & (1<<26)){ // Interrupt pending
				Xil_Out32(XPAR_AXI_FIFO_0_BASEADDR + 0x00, (1<<26) + (1<<19)); // RC clear & RFPE clear
				break;
			}
		}

		ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);
		ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x1C); // Receive Data FIFO Occupancy Register
		read_length = ret_val/3; // timestamp (coarse) & data (fine)

		for( i=0; i < read_length; i++ ){
			ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x24); // Recieve Length Register
			if( ret_val != 12 ){ // Each AXIS packet has 32 bit (timestamp) + 32 bit (data) = 64 bit = 8 bytes length
				break;
			}

			data[i].ts_1 = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);
			data[i].ts_0 = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);
			data[i].state = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);

			xil_printf("data[%d]: %08x\r\n",i, data[i].ts_0);
		}
		usleep(1000);
    }



    cleanup_platform();
    return 0;
}
