`timescale 1ns / 1ps

module enc_reader(
    input         clk,
    input         aresetn,
    input         enc_in,
    input  [63:0] counter_in,

    output [63:0] m_axis_tdata, // count
    output [ 0:0] m_axis_tuser, // state
    input         m_axis_tready,
    output        m_axis_tvalid,
    output        m_axis_tlast
);

    reg enc_buf_0;
    reg enc_buf_1;

    reg [63:0] counter_buf;

    // buffering
    always @(posedge clk) begin
        enc_buf_0 <= enc_in;
        enc_buf_1 <= enc_buf_0;
        counter_buf <= counter_in;
    end

    wire changed = (enc_buf_0 != enc_buf_1);
    wire state   = enc_buf_0;

    assign m_axis_tdata = counter_buf;
    assign m_axis_tuser = state;
    assign m_axis_tvalid = changed;
    assign m_axis_tlast = changed;

endmodule