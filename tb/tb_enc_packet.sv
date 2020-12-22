`timescale 1ns / 1ps

module tb_enc_packet();
    
    localparam STEP_SYS = 20;

    // input
    logic clk;
    logic aresetn;

    logic [63:0] s_axis_tdata;
    logic [ 0:0] s_axis_tuser;
    logic        s_axis_tready;
    logic        s_axis_tvalid;
    logic        s_axis_tlast;

    logic [31:0] m_axis_tdata;
    logic        m_axis_tready;
    logic        m_axis_tvalid;
    logic        m_axis_tlast;

    enc_packet p_inst(.*);

    task clk_gen();
        clk = 0;
        forever #(STEP_SYS/2) clk = ~clk;
    endtask
    
    task rst_gen();
        aresetn = 1;
        s_axis_tdata = 64'b0;
        s_axis_tuser = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 0;

        @(posedge clk);
        aresetn = 0;
        repeat(10) @(posedge clk);
        aresetn = 1;
    endtask
    
        
    initial begin
        fork
            clk_gen();
            rst_gen();
        join_none
        repeat(20) @(posedge clk)
        @(posedge clk);
        s_axis_tdata <= 64'b1;
        s_axis_tuser <= 1'b1;
        s_axis_tvalid <= 1'b1;
        @(posedge clk);
        s_axis_tvalid <= 1'b0;

        repeat(10) @(posedge clk);
        m_axis_tready <= 1'b1;
        @(posedge clk);
        m_axis_tready <= 1'b0;
        repeat(2) @(posedge clk);
        m_axis_tready <= 1'b1;
        @(posedge clk);
        m_axis_tready <= 1'b0;
        @(posedge clk);
        m_axis_tready <= 1'b1;
        @(posedge clk);
        s_axis_tvalid <= 1'b1;
        @(posedge clk);
        s_axis_tvalid <= 1'b0;
        repeat(10) @(posedge clk);
        m_axis_tready <= 1'b0;

        repeat(100) @(posedge clk);
        $finish;
    end
        
endmodule
