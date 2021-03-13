#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

#define IRIG_BASEADDR XPAR_AXI_IRIG_READER_BASEADDR

int main()
{
	u32 ret_val, x04;
	int i, sec, min, hr;
    init_platform();

    print("Hello World\n\r");

	while(1) {
		ret_val = Xil_In32(IRIG_BASEADDR);
		//xil_printf("[00]: %08x\r\n", ret_val);

		if (ret_val & 1) {// packet received
			x04 = Xil_In32(IRIG_BASEADDR + 4);
			sec =   (x04 & 0b00000000000000000000000000011110) >> 1;
			sec += ((x04 & 0b00000000000000000000000111000000) >> 6)*10;
			min =   (x04 & 0b00000000000000000011110000000000) >> 10;
			min += ((x04 & 0b00000000000000111000000000000000) >> 15)*10;
			hr  =   (x04 & 0b00000000111100000000000000000000) >> 20;
			hr  += ((x04 & 0b00000110000000000000000000000000) >> 25)*10;

			xil_printf("%02d:%02d:%02d\r\n", hr, min, sec);
		}

		usleep(100000);
	}

    cleanup_platform();
    return 0;
}
