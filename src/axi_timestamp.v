`timescale 1 ns / 1 ps

module axi_timestamp(
    input  wire        s_axi_aclk,
    input  wire        s_axi_arestn,

    input  wire [ 3:0] s_axi_awaddr,
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

    input  wire [ 3:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready

    output wire [63:0] counter_out;
    );

    reg [63:0] counter_reg;
    wire counter_set;
    wire [63:0] counter_set_val;

    always @(posedge s_axi_aclk) begin
        if (~s_axi_arestn) begin
            counter_reg <= {(COUNTER_LENGTH){1'b0}};
        end else if (counter_set) begin
            counter_reg <= counter_set_val;
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

    assign counter_out = counter_reg;

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
    reg [3:0] axi_awaddr_buf;

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

    reg [63:0] counter_set_val_reg;
    reg        counter_set_trigger;

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            counter_set_val_reg <= 64'b0;
            counter_set_trigger <= 1'b0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr_buf[3:2])
                3'h2: begin
                    counter_set_val_reg[31:0] <= s_axi_wdata[31:0];
                    counter_set_trigger <= 1'b0;
                end
                3'h3: begin
                    counter_set_val_reg[63:32] <= s_axi_wdata[31:0];
                    counter_set_trigger <= 1'b1;
                end
                default: begin
                    counter_set_val_reg <= counter_set_val_reg;
                    counter_set_trigger <= 1'b0;
                end
            end else begin
                if (counter_set_trigger) begin
                    counter_set_trigger <= 1'b0;
                end
            end
        end
    end
    assign counter_set = counter_set_trigger;
    assign counter_set_val = counter_set_val_reg;

    // write response
    reg axi_bvalid_buf;
    reg [1:0] axi_bresp_buf;
    assign s_axi_bvalid = axi_bvalid_buf;
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
    reg [3:0] axi_araddr_buf;
    assign s_axi_arready = axi_arready_buf;
    assign s_axi_araddr = axi_araddr_buf;
    // read address
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready_buf && s_axi_arvalid) begin
                axi_arready_buf <= 1'b1;
                axi_araddr_buf  <= s_axi_araddr;
            end else begin
                axi_arready_buf <= 1'b0;
            end
        end
    end


    reg axi_rvalid_buf;
    reg axi_rresp_buf;
    assign s_axi_rvalid = axi_rvalid_buf;
    assign s_axi_rresp = axi_rresp_buf;

    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_rvalid_buf <= 0;
            axi_rresp_buf  <= 0;
        end else begin
            if (axi_arready_buf && s_axi_arvalid && ~axi_rvalid_buf) begin
                axi_rvalid_buf <= 1'b1;
                axi_rresp_buf  <= 2'b0;
            end else if (axi_rvalid_buf && s_axi_rready) begin
                axi_rvalid_buf <= 1'b0;
            end
        end
    end

    wire slv_reg_rden = axi_arready_buf & s_axi_arvalid & ~axi_rvalid_buf;
    reg [3:0] axi_rdata_buf;
    reg [3:0] reg_data_out;
    assign s_axi_rdata = axi_rdata_buf;

    always @(*) begin
        case (axi_araddr_buf[3:2])
        2'h0   : reg_data_out <= counter_reg[31:0];
        2'h1   : reg_data_out <= counter_reg[63:32];
        2'h2   : reg_data_out <= counter_set_val_reg[31:0];
        2'h3   : reg_data_out <= counter_set_val_reg[63:32];
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

endmodule;
