// multi_slave_tb

`timescale 1ns/1ps

module tb_spi_multi_slave;

    localparam int NUM_SLAVES = 3;
    localparam int DATA_WIDTH = 8;
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;
    logic start;

    logic [DATA_WIDTH-1:0] tx_data;
    logic [DATA_WIDTH-1:0] rx_data;

    logic [NUM_SLAVES-1:0] ss_sel;
    logic [NUM_SLAVES-1:0] ss_n;

    logic sck, mosi, miso;
    logic done;

    logic cpol, cpha;

    logic [7:0] clkdiv_cfg [NUM_SLAVES];

    logic [DATA_WIDTH-1:0] slave_tx [NUM_SLAVES];
    logic [DATA_WIDTH-1:0] slave_rx [NUM_SLAVES];
    logic [NUM_SLAVES-1:0] miso_s;
    logic [NUM_SLAVES-1:0] slave_rx_valid;

    assign miso = (!ss_n[0]) ? miso_s[0] :
                  (!ss_n[1]) ? miso_s[1] :
                  (!ss_n[2]) ? miso_s[2] : 1'b0;

    // MASTER
    spi_master #(
        .NUM_SLAVES(NUM_SLAVES),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_master (
        .clk(clk), .rst_n(rst_n), .start(start),
        .tx_data(tx_data), .ss_sel(ss_sel),
        .cpol(cpol), .cpha(cpha),
        .clkdiv_cfg(clkdiv_cfg),
        .rx_data(rx_data), .done(done),
        .sck(sck), .mosi(mosi), .miso(miso),
        .ss_n(ss_n)
    );

    // SLAVES
    genvar i;
    generate
        for (i = 0; i < NUM_SLAVES; i++) begin : SLAVES
            spi_slave #(.DATA_WIDTH(DATA_WIDTH)) u_slave (
                .clk(clk), .rst_n(rst_n),
                .sck(sck), .mosi(mosi),
                .miso_out(miso_s[i]),
                .ss_n_i(ss_n[i]),
                .cpol(cpol), .cpha(cpha),
                .slave_tx(slave_tx[i]),
                .slave_rx(slave_rx[i]),
                .rx_valid(slave_rx_valid[i])
            );
        end
    endgenerate

    // CLOCK
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //================================================
    // ASSERTIONS
    //================================================

    // Only one slave selected
    always @(posedge clk) begin
        if (start) begin
            assert ($onehot(ss_sel))
            else $error("ERROR: ss_sel is not one-hot!");
        end
    end

    // MISO should not be X/Z during transfer
    always @(posedge clk) begin
        if (!ss_n && (start || !done)) begin
            assert (^miso !== 1'bx)
            else $error("ERROR: MISO is unknown!");
        end
    end

    // DONE must eventually come
    property done_eventually;
        @(posedge clk) start |-> ##[1:200] done;
    endproperty

    assert property (done_eventually)
        else $error("ERROR: DONE not asserted in time!");

    //================================================
    //  SCOREBOARD
    //================================================
    int pass_count = 0;
    int fail_count = 0;

    task automatic check_result(
        input int idx,
        input logic [7:0] master_tx,
        input logic [7:0] expected_rx
    );
        if ((rx_data == expected_rx) &&
            (slave_rx[idx] == master_tx)) begin
            $display("PASS");
            pass_count++;
        end else begin
            $display("FAIL");
            fail_count++;
        end
    endtask

    //================================================
    // TEST TASK
    //================================================
    task automatic run_test(
        input int idx,
        input logic [7:0] master_tx,
        input logic [7:0] expected_rx
    );
        logic [NUM_SLAVES-1:0] sel;

        sel = '0;
        sel[idx] = 1;

        slave_tx[idx] = expected_rx;
        repeat(4) @(posedge clk);

        @(posedge clk);
        tx_data = master_tx;
        ss_sel  = sel;
        start   = 1;

        @(posedge clk);
        start = 0;

        @(posedge done);
        @(posedge clk);

        $display("-----------------------------------------");
        $display("Mode CPOL=%0d CPHA=%0d | Slave %0d", cpol, cpha, idx);
        $display("CLK_DIV = %0d", clkdiv_cfg[idx]);
        $display("Master TX = %h | Master RX = %h", master_tx, rx_data);
        $display("Slave  RX = %h | Slave  TX = %h", slave_rx[idx], expected_rx);

        check_result(idx, master_tx, expected_rx);

        repeat(5) @(posedge clk);
    endtask

    //================================================
    // MAIN
    //================================================
    initial begin

        $dumpfile("spi_multi_slave.vcd");
        $dumpvars(0, tb_spi_multi_slave);

        rst_n = 0; start = 0; ss_sel = 0;

        clkdiv_cfg[0] = 2;
        clkdiv_cfg[1] = 4;
        clkdiv_cfg[2] = 8;

        slave_tx[0] = 8'h3C;
        slave_tx[1] = 8'h0F;
        slave_tx[2] = 8'hAA;

        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        // MODE 0
        cpol=0; cpha=0;
        run_test(0, 8'hA5, 8'h3C);
        run_test(1, 8'hF0, 8'h0F);
        run_test(2, 8'h55, 8'hAA);

        // MODE 1
        cpol=0; cpha=1;
        run_test(0, 8'hAA, 8'h11);

        // MODE 2
        cpol=1; cpha=0;
        run_test(1, 8'hCC, 8'h22);

        // MODE 3
        cpol=1; cpha=1;
        run_test(2, 8'h77, 8'h33);

        $display("====================================");
        $display("PASS = %0d | FAIL = %0d", pass_count, fail_count);
        $display("====================================");

        $finish;
    end

endmodule