#include <stdio.h>
#include <string.h>
#include "sleep.h"

#include "lwip/err.h"
#include "lwip/tcp.h"

#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xllfifo.h"
#include "xstatus.h"

#include "axi_irig_reader.h"

#define DATA_LENGTH 2048
#define SLEEP_TIME_US 100000


static struct tcp_pcb *c_pcb;
IrigReader* IrigInstance;

#pragma pack(1)
typedef struct EncData{
    u8 header;
    u32 ts_lsb;
    u32 ts_msb;
    u32 status;
    u8 filler;
    u8 footer;
} EncData;
#pragma pack()

err_t tcp_prt(struct tcp_pcb *pcb, const char* prt_char){
    return tcp_write(pcb, prt_char, strlen(prt_char), 1);
}

err_t transfer_data() {
    u32 read_length;
    int i;
    int j = 0;
    EncData enc_data[DATA_LENGTH];
    IrigInfo* irig_info;
    u32 irig_buf[6];

    u32 ret_val;
    u32 tmp_len;
    u32 RxWord;
    u32 uart_count = 0;

    if (c_pcb == NULL) {
        return ERR_CONN;
    }

    // Sleep 
    usleep(SLEEP_TIME_US);

    while(1){ // Wait until at least one successful receive has completed
        // Interrupt Status Register
        ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);
        if(ret_val & (1<<26)){ // Interrupt pending
            // RC clear & RFPE clear
            Xil_Out32(XPAR_AXI_FIFO_0_BASEADDR + 0x00, (1<<26) + (1<<19));
            break;
        }
    }

    ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x00);

    // Receive Data FIFO Occupancy Register
    ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x1C);
    // Data packet [TS LSB][TS MSB][STATE]: 3*4 bytes
    read_length = ret_val/3;

    for( i=0; i < read_length; i++ ){
        // Recieve Length Register
        ret_val = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x24);
        // Each AXIS packet has [TS LSB][TS MSB][STATE]: 3*4 bytes
        if( ret_val != 12 ){ 
            break;
        }

        enc_data[i].ts_lsb = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);
        enc_data[i].ts_msb = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);
        enc_data[i].status = Xil_In32(XPAR_AXI_FIFO_0_BASEADDR + 0x20);
        enc_data[i].filler = 0x00;
        enc_data[i].header = 0x99;
        enc_data[i].footer = 0x66;
    }

    tcp_write(c_pcb, enc_data, read_length*sizeof(EncData), 1);

    if (IsReady(IrigInstance) & 0x00000001){
        ret_val = GetIrigData(IrigInstance, irig_buf);
        ret_val = InterpretIrig(irig_buf, irig_info);
        tcp_write(c_pcb, irig_info, sizeof(IrigInfo), 1);
    }

    return ERR_OK;
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
    IrigInfo* irig_info;
    u32 irig_buf[6];


    /* do not read the packet if we are not in ESTABLISHED state */
    if (!p) {
        tcp_close(tpcb);
        tcp_recv(tpcb, NULL);
        return ERR_OK;
    }

    /* indicate that the packet has been received */
    tcp_recved(tpcb, p->len);
    if (strcmp(p->payload, "e#irig") == 0){
        xil_printf("Read irig info");
        GetIrigData(IrigInstance, irig_buf);
        InterpretIrig(irig_buf, irig_info);

        tcp_write(tpcb, irig_buf, sizeof(IrigInfo), 1);
    } else  {
        xil_printf("^_^;\r\n");
    }

    /* free the received pbuf */
    pbuf_free(p);

    return ERR_OK;
}

// TCP connection close
static void tcp_enc_close(struct tcp_pcb *pcb)
{
    err_t err;

    if (pcb != NULL) {
        tcp_recv(pcb, NULL);
        tcp_err(pcb, NULL);
        err = tcp_close(pcb);
        if (err != ERR_OK) {
            tcp_abort(pcb);
        }
    }
}

/** Error callback, tcp session aborted */
static void tcp_enc_err(void *arg, err_t err)
{
    LWIP_UNUSED_ARG(err);
    tcp_enc_close(c_pcb);
    c_pcb = NULL;
    xil_printf("TCP connection aborted\n\r");
}


err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{	
    static int connection = 1;
    u32 ret_val;

    // callback registration
    tcp_recv(newpcb, recv_callback);
    c_pcb = newpcb;
    tcp_err(c_pcb, tcp_enc_err);

    connection++;
    
    // FIFO initialization
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

    return ERR_OK;
}


int start_application()
{
    struct tcp_pcb *pcb;
    err_t err;
    unsigned port = 7;

    IrigInstance->BaseAddress = XPAR_AXI_IRIG_READER_BASEADDR;

    // TCP protocol control block (PCB)
    pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
    if (!pcb) {
        xil_printf("tcp_new_ip_type error. quit. \n\r");
        return -1;
    }

    // TCP bind (port configuration)
    err = tcp_bind(pcb, IP_ANY_TYPE, port);
    if (err != ERR_OK) {
        xil_printf("Error on tcp_bind to port %d: err = %d\n\r", port, err);
        return -2;
    }

    tcp_arg(pcb, NULL);

    // TCP listen
    pcb = tcp_listen(pcb);
    if (!pcb) {
        xil_printf("Out of memory while tcp_listen\n\r");
        return -3;
    }

    // LISTEN callback registration
    tcp_accept(pcb, accept_callback);

    xil_printf("TCP service started: port %d\n\r", port);
    return 0;
}
