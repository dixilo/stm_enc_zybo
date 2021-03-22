// Code for AXI_IRIG_READER
// 2021-03-19 Created by J. Suzuki

#include "axi_irig_reader.h"
#include "xil_assert.h"
#include "xstatus.h"


u32 IsReady(IrigReader *inst)
{
    Xil_AssertNonvoid(inst);

    return Irig_ReadReg(inst->BaseAddress,
                        IRIG_SR_OFFSET);
}

u32 GetIrigData(IrigReader *inst, void* buf_ptr)
{
    u32 *buf_ptr_idx = (u32 *)buf_ptr;

    Xil_AssertNonvoid(inst);

    buf_ptr_idx[0] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_0);
    buf_ptr_idx[1] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_1);
    buf_ptr_idx[2] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_2);
    buf_ptr_idx[3] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_3);
    buf_ptr_idx[4] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_4);
    buf_ptr_idx[5] = Irig_ReadReg(inst->BaseAddress, IRIG_DATA_5);

    return XST_SUCCESS;
}

u32 InterpretIrig(u32* buf_ptr, IrigInfo* info)
{
    // Seconds
    info->sec  =  (buf_ptr[0] & 0b00000000000000000000000000011110) >> 1;
    info->sec += ((buf_ptr[0] & 0b00000000000000000000000111000000) >> 6)*10;

    // Minutes
    info->min  =  (buf_ptr[0] & 0b00000000000000000011110000000000) >> 10;
    info->min += ((buf_ptr[0] & 0b00000000000000111000000000000000) >> 15)*10;

    // Hour
    info->hour  =  (buf_ptr[0] & 0b00000000111100000000000000000000) >> 20;
    info->hour += ((buf_ptr[0] & 0b00000110000000000000000000000000) >> 25)*10;

    // Day of year
    info->day  =  (buf_ptr[0] & 0b11000000000000000000000000000000) >> 30;
    info->day += ((buf_ptr[1] & 0b00000000000000000000000000000011) >> 0)*4;
    info->day += ((buf_ptr[1] & 0b00000000000000000000000001111000) >> 3)*10;
    info->day += ((buf_ptr[1] & 0b00000000000000000000001100000000) >> 8)*100;

    // Timestamp
    info->ts_lsb  = (buf_ptr[3] & 0b11111111111111111111111111110000) >> 4;
    info->ts_lsb += (buf_ptr[4] & 0b00000000000000000000000000001111) << 28;
    info->ts_msb  = (buf_ptr[4] & 0b11111111111111111111111111110000) >> 4;
    info->ts_msb += (buf_ptr[5] & 0b00000000000000000000000000001111) << 28;

    info->header = 0x55;
    info->footer = 0xAA;

    return XST_SUCCESS;
}
