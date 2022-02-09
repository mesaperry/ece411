import rv32i_types::*;
import connections::*;

module mp2
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_regfile;
/*****************************************************************************/

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
/*****************************************************************************/

/* Instantiate MP 1 top level blocks here */
datapath_pack dpath_conn;
control_pack ctrl_conn;

assign load_pc = ctrl_conn.load_pc;
assign load_regfile = ctrl_conn.load_regfile;
assign pcmux_sel = ctrl_conn.pcmux_sel;
assign alumux1_sel = ctrl_conn.alumux1_sel;
assign alumux2_sel = ctrl_conn.alumux2_sel;
assign regfilemux_sel = ctrl_conn.regfilemux_sel;
assign marmux_sel = ctrl_conn.marmux_sel;
assign cmpmux_sel = ctrl_conn.cmpmux_sel;

// Keep control named `control` for RVFI Monitor
control control(
	.clk(clk),
	.rst(rst),
	.mem_resp(mem_resp),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_byte_enable(mem_byte_enable),
	.dpath_in(dpath_conn),
	.ctrl_out(ctrl_conn)
);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(
	.clk(clk),
	.rst(rst),
	.mem_rdata(mem_rdata),
	.mem_wdata(mem_wdata),
	.mem_address(mem_address),
	.ctrl_in(ctrl_conn),
	.dpath_out(dpath_conn)
);

endmodule : mp2
