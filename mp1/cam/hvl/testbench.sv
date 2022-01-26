import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

key_t [7:0] keys;
val_t [7:0] vals;

task test_evict();
    @(tb_clk);
    itf.key = 16'h1234;
    itf.val_i = 16'h4321;
    itf.rw_n = 1'b0;
    itf.valid_i = 1'b1;

    for (int i = 0; i < 8; ++i) begin
        @(tb_clk);
        itf.key = keys[i];
        itf.val_i = vals[i];
    end

    @(tb_clk);
    itf.valid_i = 1'b0;
endtask : test_evict

task test_read_hit();
      @(tb_clk);
      itf.rw_n = 1'b1;
      itf.valid_i = 1'b1;

      for (int i = 0; i < 8; ++i) begin
            itf.key = keys[i];
            itf.val_i = vals[i];
            @(tb_clk);
            assert(itf.val_o == vals[i])
            else begin
                  itf.tb_report_dut_error(READ_ERROR);
                  $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, vals[i - 1]);
            end
      end

      @(tb_clk);
      itf.valid_i = 1'b0;
endtask: test_read_hit

task test_ww();
      @(tb_clk);
      itf.key = 16'h0011;
      itf.val_i = 16'h0022;
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;

      @(tb_clk);
      itf.val_i = 16'h0033;

      @(tb_clk);
      itf.valid_i = 1'b0;

      @(tb_clk);
      assert(itf.val_o == 16'h0033)
      else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, 16'h0033);
      end
      itf.valid_i = 1'b0;
endtask : test_ww

task test_wr();
      @(tb_clk);
      itf.key = 16'h0033;
      itf.val_i = 16'h0044;
      itf.rw_n = 1'b0;
      itf.valid_i = 1'b1;

      @(tb_clk);
      itf.key = 16'h0033;
      itf.rw_n = 1'b1;

      @(tb_clk);
      assert(itf.val_o == 16'h0044)
      else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, 16'h0044);
      end
      itf.valid_i = 1'b0;
endtask : test_wr

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

    for (int i = 0; i < 8; i++) begin
        keys[i] = i;
        vals[i] = i * 2 + 3;
    end

    test_evict();
    test_read_hit();
    test_ww();
    test_wr();

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
