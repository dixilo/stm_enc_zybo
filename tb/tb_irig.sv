`timescale 1ns / 1ps

module tb_irig();
    
    localparam STEP_SYS = 20;
    string pattern = "000pp01100010p001000000p111001000p100100110p000000000p000000000p000000000p000000000p000000000p000000000pp01100010p001000000p1110";
    
    // input
    logic clk;
    logic aresetn;

    logic [63:0] counter_in;
    logic        irig_in;

    logic [163:0] m_axis_tdata;
    logic        m_axis_tready;
    logic        m_axis_tvalid;
    logic        m_axis_tlast;

    b002_decoder p_inst(
        .clk_50MHz(clk),             
        .resetn(aresetn),
        .counter_in(counter_in),    
        .irig_in(irig_in),
        .m_axis_tdata(m_axis_tdata), 
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)  
    );

    task clk_gen();
        clk = 0;
        forever #(STEP_SYS/2) clk = ~clk;
    endtask
    
    task rst_gen();
        aresetn = 1;
        irig_in = 0;
        m_axis_tready = 1;

        @(posedge clk);
        aresetn = 0;
        repeat(10) @(posedge clk);
        aresetn = 1;
    endtask

    always@(posedge clk) begin
        if (~aresetn) begin
            counter_in <= 64'b0;
        end else begin
            counter_in <= counter_in + 1;
        end
    end

    task gen(input byte irig_type);
        case (irig_type)
        "0": begin
            irig_in <= 1;
            repeat(100000) @(posedge clk);
            irig_in <= 0;
            repeat(400000) @(posedge clk);
        end
        "1": begin
            irig_in <= 1;
            repeat(250000) @(posedge clk);
            irig_in <= 0;
            repeat(250000) @(posedge clk);
        end
        "p": begin
            irig_in <= 1;
            repeat(400000) @(posedge clk);
            irig_in <= 0;
            repeat(100000) @(posedge clk);
        end
        endcase
    endtask

    initial begin
        fork
            clk_gen();
            rst_gen();
        join_none
        repeat(20) @(posedge clk);
        @(posedge clk);
        irig_in <= 1;
        @(posedge clk);
        irig_in <= 0;
        
        repeat(20) @(posedge clk);
        for(int i = 0; i < 128; i++) begin
            gen(pattern[i]);
        end
        repeat(20) @(posedge clk);
        $finish;
    end
        
endmodule
