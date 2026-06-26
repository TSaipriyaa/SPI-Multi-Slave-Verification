//Multi-slave: CPOL, CPHA, clk_div and assertion.  

module spi_master #(
    parameter int NUM_SLAVES = 3,
    parameter int DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [DATA_WIDTH-1:0] tx_data,
    input  logic [NUM_SLAVES-1:0] ss_sel,

    input  logic cpol,
    input  logic cpha,

    //  NEW
    input  logic [7:0] clkdiv_cfg [NUM_SLAVES],

    output logic [DATA_WIDTH-1:0] rx_data,
    output logic done,
    output logic sck,
    output logic mosi,
    input  logic miso,
    output logic [NUM_SLAVES-1:0] ss_n
);

    typedef enum logic [1:0] {IDLE, ACTIVE, DONE_ST} state_t;

    logic [NUM_SLAVES-1:0] ss_sel_latch;
    state_t state;

    logic [2:0] bit_cnt;
    logic [7:0] clk_cnt, clk_div_sel;
    logic sck_r;

    logic [DATA_WIDTH-1:0] shift_tx, shift_rx;

    logic leading_edge, trailing_edge;
    logic sample_edge, shift_edge;

    assign ss_n = ~ss_sel_latch;
    assign sck  = sck_r;

    //  SELECT CLK DIV PER SLAVE
    integer i;
    always_comb begin
        clk_div_sel = 2; // default
        for (i = 0; i < NUM_SLAVES; i++) begin
            if (ss_sel_latch[i])
                clk_div_sel = clkdiv_cfg[i];
        end
    end

    // Clock generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
            sck_r   <= 0;
        end else if (state == ACTIVE) begin
            if (clk_cnt == clk_div_sel-1) begin
                clk_cnt <= 0;
                sck_r   <= ~sck_r;
            end else
                clk_cnt <= clk_cnt + 1;
        end else begin
            clk_cnt <= 0;
            sck_r   <= cpol;
        end
    end

    logic sck_next;
    assign sck_next = ~sck_r;

    assign leading_edge  = (state == ACTIVE) && (clk_cnt == clk_div_sel-1) && (sck_next != cpol);
    assign trailing_edge = (state == ACTIVE) && (clk_cnt == clk_div_sel-1) && (sck_next == cpol);

    assign sample_edge = cpha ? trailing_edge : leading_edge;
    assign shift_edge  = cpha ? leading_edge  : trailing_edge;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ss_sel_latch <= 0;
            mosi <= 0;
            done <= 0;
        end else begin
            done <= 0;

            case(state)

            IDLE: begin
                if (start) begin
                    ss_sel_latch <= ss_sel;
                    shift_tx <= tx_data;
                    shift_rx <= 0;
                    bit_cnt  <= DATA_WIDTH-1;

                    if (!cpha)
                        mosi <= tx_data[DATA_WIDTH-1];

                    state <= ACTIVE;
                end else begin
                    ss_sel_latch <= 0;
                end
            end

            ACTIVE: begin
                if (shift_edge)
                    mosi <= shift_tx[bit_cnt];

                if (sample_edge) begin
                    shift_rx <= {shift_rx[DATA_WIDTH-2:0], miso};

                    if (bit_cnt == 0)
                        state <= DONE_ST;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            DONE_ST: begin
                rx_data <= shift_rx;
                done <= 1;
                ss_sel_latch <= 0;
                state <= IDLE;
            end

            endcase
        end
    end

endmodule

module spi_slave #(
    parameter int DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  sck,
    input  logic                  mosi,
    output logic                  miso_out,
    input  logic                  ss_n_i,

    input  logic                  cpol,
    input  logic                  cpha,

    input  logic [DATA_WIDTH-1:0] slave_tx,
    output logic [DATA_WIDTH-1:0] slave_rx,
    output logic                  rx_valid
);

    localparam int BIT_CTR_W = $clog2(DATA_WIDTH);

    logic [BIT_CTR_W-1:0] bit_cnt;
    logic [DATA_WIDTH-1:0] shift_rx, shift_tx;

    logic sck_prev;
    logic active;

    logic leading_edge, trailing_edge;
    logic sample_edge, shift_edge;

    assign active = ~ss_n_i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sck_prev <= cpol;
        else
            sck_prev <= sck;
    end

    assign leading_edge  = active && (sck_prev == cpol) && (sck != cpol);
    assign trailing_edge = active && (sck_prev != cpol) && (sck == cpol);

    assign sample_edge = cpha ? trailing_edge : leading_edge;
    assign shift_edge  = cpha ? leading_edge  : trailing_edge;

    assign miso_out = active ? shift_tx[bit_cnt] : 1'b0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt  <= DATA_WIDTH-1;
            shift_rx <= 0;
            shift_tx <= 0;
            slave_rx <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 0;

            if (!active) begin
                bit_cnt  <= DATA_WIDTH-1;
                shift_tx <= slave_tx;
            end else begin
                if (sample_edge) begin
                    shift_rx <= {shift_rx[DATA_WIDTH-2:0], mosi};

                    if (bit_cnt == 0) begin
                        slave_rx <= {shift_rx[DATA_WIDTH-2:0], mosi};
                        rx_valid <= 1;
                        bit_cnt  <= DATA_WIDTH-1;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end
        end
    end

endmodule

