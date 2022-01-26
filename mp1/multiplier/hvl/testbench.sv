import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


logic [16:0] operands;
logic [15:0] expected_product;

assign itf.multiplicand = operands[15:8];
assign itf.multiplier = operands[7:0];
assign expected_product = itf.multiplicand * itf.multiplier;

task test_product();
    @(tb_clk);
    itf.start <= 1'b1;

    @(posedge itf.done);
    operands <= operands + 17'd1;
    itf.start <= 1'b0;

    // the optional reset
    @(tb_clk);
    itf.reset_n <= 1'b0;
    @(tb_clk);
    itf.reset_n <= 1'b1;
endtask: test_product

task test_start_during_shift();
    @(tb_clk);
    operands <= 17'h12345;
    itf.start <= 1'b1;
    @(tb_clk);
    itf.start <= 1'b0;

    while (1) begin
        @(tb_clk);
        if (dut.ms.op == SHIFT) begin
            @(tb_clk);
            itf.start <= 1'b1;
            @(tb_clk);
            itf.start <= 1'b0;
            break;
        end
    end
      
    @(posedge itf.done);
endtask: test_start_during_shift

task test_start_during_add();
    @(tb_clk);
    operands <= 17'h12345;
    itf.start <= 1'b1;
    @(tb_clk);
    itf.start <= 1'b0;

    while (1) begin
        @(tb_clk);
        if (dut.ms.op == ADD) begin
            @(tb_clk);
            itf.start <= 1'b1;
            @(tb_clk);
            itf.start <= 1'b0;
            break;
        end
    end

    @(posedge itf.done);
endtask: test_start_during_add

task test_reset_during_shift();
    @(tb_clk);
    operands <= 17'h12345;
    itf.start <= 1'b1;
    @(tb_clk);
    itf.start <= 1'b0;

    while (itf.rdy == 1'b0) begin
        @(tb_clk);
        if (dut.ms.op == SHIFT) begin
            @(tb_clk);
            itf.reset_n <= 1'b0;
            @(tb_clk);
            itf.reset_n <= 1'b1;
        end
    end
endtask: test_reset_during_shift

task test_reset_during_add();
    @(tb_clk);
    operands <= 17'h12345;
    itf.start <= 1'b1;
    @(tb_clk);
    itf.start <= 1'b0;

    while (itf.rdy == 1'b0) begin
        @(tb_clk);
        if (dut.ms.op == ADD) begin
            @(tb_clk);
            itf.reset_n <= 1'b0;
            @(tb_clk);
            itf.reset_n <= 1'b1;
        end
    end
endtask: test_reset_during_add


always @ (posedge itf.done) begin
    assert (itf.product == expected_product)
    else begin
        $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
        report_error (BAD_PRODUCT);
    end
    assert (itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error (NOT_READY);
    end
end

always @ (negedge itf.reset_n) begin
    @(posedge itf.reset_n);
    assert (itf.rdy == 1'b1)
    else begin
        $error("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error (NOT_READY);
    end
end


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    operands = 17'd0;

    while (operands < 17'h10000) begin
        test_product();
    end
    test_start_during_shift();
    test_start_during_add();
    test_reset_during_shift();
    test_reset_during_add();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
