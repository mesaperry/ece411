`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

word_t expected;

task test_enqueue();
    @(tb_clk);
    itf.valid_i <= 1'b1;
    for (int i = 0; i < 256; i++) begin
        @(tb_clk);
        itf.data_i <= itf.data_i + 8'd1;
    end
    itf.valid_i <= 1'b0;
endtask : test_enqueue

task test_dequeue();
    @(tb_clk);
    itf.yumi <= 1'b1;
    for (int i = 0; i < 256; i++) begin
        @(tb_clk);
    end
    itf.yumi <= 1'b0;
endtask : test_dequeue

task test_simultaneous();
    @(tb_clk);
    expected <= 1;
    for (int i = 0; i < 256; i++) begin
        @(tb_clk);
        itf.valid_i <= 1'b1;
        itf.yumi <= 1'b0;
        itf.data_i <= itf.data_i + 8'd1;

        @(tb_clk);
        itf.yumi <= 1'b1;
        itf.data_i <= itf.data_i + 8'd1;
    end

    @(tb_clk);
    itf.yumi <= 1'b0;
    itf.valid_i <= 1'b0;
endtask : test_simultaneous

always @ (tb_clk) begin
    if (itf.yumi == 1'b1) begin
        expected = expected + 8'd1;
        assert(itf.data_o == expected)
        else begin
            $error("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected -- %0d %0d", `__LINE__, $time, itf.data_o, expected);
            report_error(INCORRECT_DATA_O_ON_YUMI_I);
        end
    end
end

task test_reset();
    @(tb_clk);
    itf.reset_n <= 1'b0;
    @(posedge itf.clk);
    assert(itf.rdy == 1'b1)
    else begin
        $error("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
        report_error(RESET_DOES_NOT_CAUSE_READY_O);
    end
    itf.valid_i <= 1'b0;
endtask : test_reset

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    expected <= 8'd0;
    itf.data_i <= 8'd0;

    test_enqueue();
    test_dequeue();
    test_simultaneous();
    test_reset();

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

