// Header file for AXI_IRIG_READER
// 2021-03-19 Created by J. Suzuki

#ifndef IRIG_H
#define IRIG_H

#include "xil_io.h"

#define IRIG_SR_OFFSET 0x00000000
#define IRIG_DATA_0    0x00000004
#define IRIG_DATA_1    0x00000008
#define IRIG_DATA_2    0x0000000C
#define IRIG_DATA_3    0x00000010
#define IRIG_DATA_4    0x00000014
#define IRIG_DATA_5    0x0000001C

// Irig reader device
typedef struct IrigReader {
    UINTPTR BaseAddress;
} IrigReader;

// Packet: 15 bytes
#pragma pack(1)
typedef struct IrigInfo {
    u8 header;
    u32 ts_lsb;
    u32 ts_msb;
    u8 sec;
    u8 min;
    u8 hour;
    u16 day;
    u8 footer;
} IrigInfo;
#pragma pack()

#define Irig_ReadReg(BaseAddress, RegOffset) \
    (Xil_In32((BaseAddress) + (RegOffset)))

u32 IsReady(IrigReader *inst);
u32 GetIrigData(IrigReader *inst, void* buf_ptr);
u32 InterpretIrig(u32* buf_ptr, IrigInfo* info);

#endif
