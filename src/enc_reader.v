`timescale 1ns / 1ps

module enc_reader(
    input         clk,
    input         aresetn,
    input         enc_in,
    input  [63:0] counter_in,

    output [63:0] m_axis_tdata, // count
    output [ 0:0] m_axis_tuser, // state
    input         m_axis_tready,
    output        m_axis_tvalid
);

    reg enc_buf;
    always @(posedge clk) begin
        enc_buf <= enc_in;
    end

    wire changed = (enc_buf == enc_in);
    wire state   = enc_in;

    assign m_axis_tdata = counter_in;
    assign m_axis_tuser = state;
    assign m_axis_tvalid = changed;

endmodule;