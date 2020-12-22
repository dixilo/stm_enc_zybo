`timescale 1ns / 1ps

module enc_packet(
    input         clk,
    input         aresetn,

    input [63:0] s_axis_tdata, // count
    input [ 0:0] s_axis_tuser, // state
    output       s_axis_tready,
    input        s_axis_tvalid,
    input        s_axis_tlast,

    output [31:0] m_axis_tdata,
    input         m_axis_tready,
    output        m_axis_tvalid,
    output        m_axis_tlast
);

    reg [1:0] stage;
    reg [63:0] ts_buf;
    reg state_buf;
    reg [31:0] tdata_buf;

    assign m_axis_tvalid = ((stage == 2'b00) & s_axis_tvalid) | (stage != 2'b00);
    assign s_axis_tready = (stage == 2'b00);

    // Stage manipulation
    always @(posedge clk) begin
        if (~aresetn) begin
            stage <= 2'b00;
        end else begin
            case(stage)
            2'b00: begin
                if (s_axis_tvalid) begin
                    if (m_axis_tready) begin
                        stage <= 2'b10;
                    end else begin
                        stage <= 2'b01;
                    end
                end
            end
            2'b01: begin // 1
                if (m_axis_tready) begin
                    stage <= 2'b10;
                end
            end
            2'b10: begin // 2
                if (m_axis_tready) begin
                    stage <= 2'b11;
                end
            end
            2'b11: begin // 3
                if (m_axis_tready) begin
                    stage <= 2'b00;
                end
            end
            endcase
        end
    end

    assign m_axis_tlast = (stage == 2'b11);

    // Data buffering
    always @(posedge clk) begin
        if (~aresetn) begin
            ts_buf <= 64'b0;
            state_buf <= 1'b0;
        end else begin
            if ((stage == 2'b00) & s_axis_tvalid) begin
                ts_buf <= s_axis_tdata;
                state_buf <= s_axis_tuser;
            end
        end
    end
    
    // TDATA
    always @(*) begin
        case(stage)
        2'b00: begin // little endian
            tdata_buf <= s_axis_tdata[31:0];
        end
        2'b01: begin
            tdata_buf <= ts_buf[31:0];
        end
        2'b10: begin
            tdata_buf <= ts_buf[63:32];
        end
        2'b11: begin
            tdata_buf <= {31'b0, state_buf};
        end
        endcase
    end

    assign m_axis_tdata = tdata_buf;

endmodule