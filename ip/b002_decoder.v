`timescale 1 ns / 1 ps

module b002_decoder(
    input  wire        clk_50MHz,
    input  wire        resetn,

    input  wire [63:0] counter_in,
    input  wire        irig_in,

    output wire [163:0] m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
    );

    localparam STATE_WAITING    = 3'b000;
    localparam STATE_PI_1       = 3'b001;
    localparam STATE_PROCESSING = 3'b010;

    localparam IRIG_0   = 2'b00;
    localparam IRIG_1   = 2'b01;
    localparam IRIG_PI  = 2'b10;
    localparam IRIG_ERR = 2'b11;

    localparam IRIG_TIMER_0  = 20'd175000; // 3.5 ms
    localparam IRIG_TIMER_1  = 20'd325000; // 6.5 ms
    localparam IRIG_TIMER_PI = 20'd614400; // max

    reg [2:0]  state;       // state for the state machine below
    reg        irig_buf;
    reg        pw_proc;     // indicates pulse width measurement going on
    reg        pw_proc_buf; // its buffer
    reg [19:0] pulse_width; // pulse width
    reg [63:0] rising_edge, falling_edge, sync_edge;
    wire       rising, falling;
    wire       pw_valid;    // pulse width valid
    reg [1:0]  pulse_type;

    reg [7:0]  bit_position;
    reg [3:0]  sub_position;
    reg [99:0] output_buf;

    // irig_bufer
    always @(posedge clk) begin
        irig_buf <= irig_in;
    end

    // rising edge
    assign rising = (irig_in == 1) & (irig_buf == 0);
    // falling edge
    assign falling = (irig_in == 0) & (irig_buf == 1);

    // pulse width
    always @(posedge clk) begin
        if (~resetn) begin
            pw_proc <= 1'b0;
            pulse_width <= 20'b0;
        end begin
            if (rising) begin
                rising_edge <= counter_in;
                pulse_width <= 20'b0;
                pw_proc <= 1'b1;
            end else if (falling) begin
                falling_edge <= counter_in;
                pulse_width <= pulse_width + 1;
                pw_proc <= 1'b0;
            end else if (pw_proc) begin
                pulse_width <= pulse_width + 1;
            end else begin
                ;
            end
        end
    end

    assign pw_valid = (pw_proc == 0) & (pw_proc_buf == 1);

    // pulse type
    always @(*) begin
        if (pulse_width < IRIG_TIMER_0) begin
            pulse_type = IRIG_0;
        end else if ((IRIG_TIMER_0 <= pulse_width) && (pulse_width < IRIG_TIMER_1)) begin
            pulse_type = IRIG_1;
        end else if ((IRIG_TIMER_1 <= pulse_width) && (pulse_width < IRIG_TIMER_PI)) begin
            pulse_type = IRIG_PI;
        end else begin
            pulse_type = IRIG_ERR;
        end
    end

    // state machine
    always @(posedge clk) begin
        if (~resetn) begin
            state <= STATE_WAITING;
            bit_position <= 8'b1;
            sub_position <= 4'b1;
        end else begin
            if (pw_valid) begin
                case (state)
                    STATE_WAITING: begin
                        if (pulse_type == IRIG_PI) begin
                            state <= STATE_PI_1;
                        end
                    end
                    STATE_PI_1: begin
                        if (pulse_type == IRIG_PI) begin
                            state <= STATE_PROCESSING;
                            sync_edge <= rising_edge;
                            bit_position <= 8'b1;
                            sub_position <= 4'b1;
                        end else begin
                            state <= STATE_WAITING;
                        end
                    end
                    STATE_PROCESSING: begin
                        if (bit_position == 99) begin
                            case (pulse_type)
                                IRIG_PI: state <= STATE_PI_1;
                                default: state <= STATE_WAITING;
                            endcase
                        end else if (sub_position == 4'd9) begin
                            case (pulse_type)
                                IRIG_PI: ;
                                default: state <= STATE_WAITING;
                            endcase
                            sub_position <= 4'b0;
                            bit_position <= bit_position + 1;
                        end else begin
                            output_buf[bit_position] <= (pulse_type == IRIG_1)?1'b1:1'b0;
                            bit_position <= bit_position + 1;
                            sub_position <= sub_position + 1;
                        end
                    end
                endcase
            end
        end
    end

    // AXI stream
    // TODO: data should be split into 32/64 bit for efficent use of resources
    assign m_axis_tvalid = (pw_valid) & (bit_position == 99) & (pulse_type == IRIG_PI);
    assign m_axis_tlast = m_axis_tvalid;
    assign m_axis_tdata = {sync_edge, output_buf};

endmodule