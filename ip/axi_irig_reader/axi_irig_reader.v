`timescale 1 ns / 1 ps

module axi_irig_reader(
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [ 4:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [ 4:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    input  wire [63:0] counter_in,
    input  wire        irig_in
    );

    // decoder data
    wire [163:0] decoder_data;
    reg  [163:0] decoder_data_buf;
    reg  [163:0] decoder_data_latch;
    wire         decoder_valid;
    wire         decoder_tlast;
    reg          data_available_buf;

    // AXI
    reg axi_awready_buf;
    reg axi_wready_buf;
    reg axi_bvalid_buf;
    reg aw_en;

    assign s_axi_bvalid  = axi_bvalid_buf;
    assign s_axi_awready = axi_awready_buf;
    assign s_axi_wready  = axi_wready_buf;

    // AWREADY & WREADY signal
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awready_buf <= 1'b0;
            axi_wready_buf <= 1'b0;
        end else begin
            if (~axi_awready_buf && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awready_buf <= 1'b1;
                axi_wready_buf <= 1'b1;
            end else begin
                axi_awready_buf <= 1'b0;
                axi_wready_buf <= 1'b0;
            end
        end
    end

    // AW ENABLE
    always @( posedge s_axi_aclk ) begin
        if (~s_axi_aresetn) begin
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready_buf && s_axi_awvalid && s_axi_wvalid && aw_en)
                aw_en <= 1'b0;
            else if (s_axi_bready && axi_bvalid_buf)
                aw_en <= 1'b1;
        end
    end

    // AXI AWADDR
    reg [4:0] axi_awaddr_buf;

    always @( posedge s_axi_aclk ) begin
        if (~s_axi_aresetn) begin
            axi_awaddr_buf <= 0;
        end else begin
            if (~axi_awready_buf && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awaddr_buf <= s_axi_awaddr;
            end
        end
    end


    // Write action
    wire slv_reg_wren = axi_wready_buf && s_axi_wvalid && axi_awready_buf && s_axi_awvalid;

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            ;
        end else begin
            if (slv_reg_wren) begin
                ;
            end else begin
                ;
            end
        end
    end

    // write response
    reg [1:0] axi_bresp_buf;
    assign s_axi_bresp = axi_bvalid_buf;

    always @( posedge s_axi_aclk ) begin
        if ( s_axi_aresetn == 1'b0 ) begin
            axi_bvalid_buf  <= 0;
            axi_bresp_buf   <= 2'b0;
        end else begin
            if (axi_awready_buf && s_axi_awvalid && ~axi_bvalid_buf && axi_wready_buf && s_axi_wvalid) begin
                axi_bvalid_buf <= 1'b1;
                axi_bresp_buf  <= 2'b0; // 'OKAY' response 
            end else begin
                if (s_axi_bready && axi_bvalid_buf)
                    axi_bvalid_buf <= 1'b0;
            end
        end
    end

    reg axi_arready_buf;
    reg [4:0] axi_araddr_buf;
    reg axi_rvalid_buf;
    reg axi_rresp_buf;

    assign s_axi_arready = axi_arready_buf;

    wire slv_reg_rden = axi_arready_buf & s_axi_arvalid & ~axi_rvalid_buf;
    
    assign s_axi_rvalid = axi_rvalid_buf;
    assign s_axi_rresp = axi_rresp_buf;

    // read address
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_arready_buf <= 1'b0;
            axi_araddr_buf  <= 32'b0;
        end else begin
            if (~axi_arready_buf && s_axi_arvalid) begin
                axi_arready_buf <= 1'b1;
                axi_araddr_buf  <= s_axi_araddr;
            end else begin
                axi_arready_buf <= 1'b0;
            end
        end
    end

    // data latching
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            data_available_buf <= 1'b0;
            decoder_data_latch <= 164'b0;
        end else begin
            if ((axi_araddr_buf == 32'b0) && slv_reg_rden ) begin
                // data latching occurs when read access to the 0th register happens
                if (decoder_valid) begin
                    // read and b002 output happen at the same time
                    decoder_data_latch <= decoder_data;
                    data_available_buf <= 1'b0;
                end else if (data_available_buf) begin
                    // new data is available
                    decoder_data_latch <= decoder_data_buf;
                    data_available_buf <= 1'b0;
                end else begin
                    ;
                end
            end else begin
                if (decoder_valid) begin
                    data_available_buf <= 1'b1;
                end
            end
        end
    end

    

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_rvalid_buf <= 0;
            axi_rresp_buf  <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rvalid_buf <= 1'b1;
                axi_rresp_buf  <= 2'b0;
            end else if (axi_rvalid_buf && s_axi_rready) begin
                axi_rvalid_buf <= 1'b0;
            end
        end
    end

    
    reg [31:0] axi_rdata_buf;
    reg [31:0] reg_data_out;
    assign s_axi_rdata = axi_rdata_buf;

    always @(*) begin
        case (axi_araddr_buf[4:2])
        3'h0   : reg_data_out <= {31'b0, data_available_buf | decoder_valid};
        3'h1   : reg_data_out <= decoder_data_latch[31:0];
        3'h2   : reg_data_out <= decoder_data_latch[63:32];
        3'h3   : reg_data_out <= decoder_data_latch[95:64];
        3'h4   : reg_data_out <= decoder_data_latch[127:96];
        3'h5   : reg_data_out <= decoder_data_latch[159:128];
        3'h6   : reg_data_out <= {28'b0, decoder_data_latch[163:160]};
        default: reg_data_out <= 0;
        endcase
    end

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_rdata_buf <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata_buf <= reg_data_out;
            end
        end
    end

    b002_decoder decoder_inst(
        .clk_50MHz    (s_axi_aclk),
        .resetn       (s_axi_aresetn),
        .counter_in   (counter_in),
        .irig_in      (irig_in),
        .m_axis_tdata (decoder_data),
        .m_axis_tvalid(decoder_valid),
        .m_axis_tready(1'b1),
        .m_axis_tlast (decoder_tlast)
    );

    // data buffering
    always @(posedge s_axi_aclk) begin
        if (decoder_valid) begin
            decoder_data_buf <= decoder_data;
        end
    end

endmodule
