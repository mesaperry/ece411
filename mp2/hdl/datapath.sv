`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
import connections::*;

module datapath (
    input clk,
    input rst,
	 
    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
	 
	 input control_pack ctrl_in,
	 output datapath_pack dpath_out
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_pack conn;
assign conn.ctrl = ctrl_in;
assign dpath_out = conn.dpath;

logic load_pc;
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
rv32i_word pc_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_reg rd;
rv32i_word regfilemux_out;

assign load_pc = conn.ctrl.load_pc;
assign pcmux_out = conn.dpath.pcmux_out;
assign mdrreg_out = conn.dpath.mdr_out;
assign pc_out = conn.dpath.pc_out;
assign rs1_out = conn.dpath.rs1_out;
assign rs2_out = conn.dpath.rs2_out;
assign rd = conn.dpath.rd;
assign regfilemux_out = conn.dpath.regfilemux_out;

assign mem_address = {conn.dpath.mem_address[31:2], 2'd0};
/*****************************************************************************/


/***************************** Registers *************************************/
logic [31:0] mem_data_out_in;

pc_register PC(
	.clk(clk),
	.rst(rst),
	.load(conn.ctrl.load_pc),
	.in(conn.dpath.pcmux_out),
	.out(conn.dpath.pc_out)
);

register MAR(
	.clk(clk),
	.rst(rst),
	.load(conn.ctrl.load_mar),
	.in(conn.dpath.marmux_out),
	.out(conn.dpath.mem_address)
);

// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
	.clk(clk),
	.rst(rst),
	.load(conn.ctrl.load_ir),
	.in(conn.dpath.mdr_out),
	.funct3(conn.dpath.funct3),
	.funct7(conn.dpath.funct7),
	.opcode(conn.dpath.opcode),
	.i_imm(conn.dpath.i_imm),
	.s_imm(conn.dpath.s_imm),
	.b_imm(conn.dpath.b_imm),
	.u_imm(conn.dpath.u_imm),
	.j_imm(conn.dpath.j_imm),
	.rs1(conn.dpath.rs1),
	.rs2(conn.dpath.rs2),
	.rd(conn.dpath.rd)
);

regfile regfile(
	.clk(clk),
	.rst(rst),
	.load(conn.ctrl.load_regfile),
	.in(conn.dpath.regfilemux_out),
	.src_a(conn.dpath.rs1),
	.src_b(conn.dpath.rs2),
	.dest(conn.dpath.rd),
	.reg_a(conn.dpath.rs1_out),
	.reg_b(conn.dpath.rs2_out)
);

register mem_data_out(
	.clk(clk),
	.rst(rst),
	.load(conn.ctrl.load_data_out),
	.in(mem_data_out_in),
	.out(mem_wdata)
);

register MDR(
	.clk(clk),
	.rst(rst),
	.load(ctrl_in.load_mdr),
	.in(mem_rdata),
	.out(conn.dpath.mdr_out)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu alu_0(
      .aluop(conn.ctrl.aluop),
      .a(conn.dpath.alumux1_out),
      .b(conn.dpath.alumux2_out),
      .f(conn.dpath.alu_out)
);

cmp cmp_0(
      .op(conn.ctrl.cmpop),
      .a(conn.dpath.rs1_out),
      .b(conn.dpath.cmp_mux_out),
      .f(conn.dpath.br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
	unique case (conn.ctrl.pcmux_sel)
		pcmux::pc_plus4: conn.dpath.pcmux_out = conn.dpath.pc_out + 4;
		pcmux::alu_out:  conn.dpath.pcmux_out = conn.dpath.alu_out;
		pcmux::alu_mod2:  conn.dpath.pcmux_out = {conn.dpath.alu_out[31:2], 2'd0};
		default: `BAD_MUX_SEL;
	endcase

	unique case (conn.ctrl.marmux_sel)
		marmux::pc_out: conn.dpath.marmux_out = conn.dpath.pc_out;
		marmux::alu_out: conn.dpath.marmux_out = conn.dpath.alu_out;
		default: `BAD_MUX_SEL;
	endcase

	unique case (conn.ctrl.alumux1_sel)
		alumux::rs1_out: conn.dpath.alumux1_out = conn.dpath.rs1_out;
		alumux::pc_out: conn.dpath.alumux1_out = conn.dpath.pc_out;
		default: `BAD_MUX_SEL;
	endcase

	unique case (conn.ctrl.alumux2_sel)
		alumux::i_imm: conn.dpath.alumux2_out = conn.dpath.i_imm;
		alumux::u_imm: conn.dpath.alumux2_out = conn.dpath.u_imm;
		alumux::b_imm: conn.dpath.alumux2_out = conn.dpath.b_imm;
		alumux::s_imm: conn.dpath.alumux2_out = conn.dpath.s_imm;
		alumux::j_imm: conn.dpath.alumux2_out = conn.dpath.j_imm;
		alumux::rs2_out: conn.dpath.alumux2_out = conn.dpath.rs2_out;
		default: `BAD_MUX_SEL;
	endcase

	unique case (conn.ctrl.regfilemux_sel)
		regfilemux::alu_out: conn.dpath.regfilemux_out = conn.dpath.alu_out;
		regfilemux::br_en: conn.dpath.regfilemux_out =  {31'd0, conn.dpath.br_en};
		regfilemux::u_imm: conn.dpath.regfilemux_out = conn.dpath.u_imm;
		regfilemux::lw: conn.dpath.regfilemux_out = conn.dpath.mdr_out;
		regfilemux::pc_plus4: conn.dpath.regfilemux_out = conn.dpath.pc_out + 32'd4;
		regfilemux::lb: begin
			unique case(conn.dpath.alu_out[1:0])
				4'b00: conn.dpath.regfilemux_out = {{24{conn.dpath.mdr_out[7]}}, conn.dpath.mdr_out[7:0]};
				4'b01: conn.dpath.regfilemux_out = {{24{conn.dpath.mdr_out[15]}}, conn.dpath.mdr_out[15:8]};
				4'b10: conn.dpath.regfilemux_out = {{24{conn.dpath.mdr_out[23]}}, conn.dpath.mdr_out[23:16]};
				4'b11: conn.dpath.regfilemux_out = {{24{conn.dpath.mdr_out[31]}}, conn.dpath.mdr_out[31:24]};
			endcase
		end
		regfilemux::lbu: begin
			unique case(conn.dpath.alu_out[1:0])
				4'b00: conn.dpath.regfilemux_out = {24'd0, conn.dpath.mdr_out[7:0]};
				4'b01: conn.dpath.regfilemux_out = {24'd0, conn.dpath.mdr_out[15:8]};
				4'b10: conn.dpath.regfilemux_out = {24'd0, conn.dpath.mdr_out[23:16]};
				4'b11: conn.dpath.regfilemux_out = {24'd0, conn.dpath.mdr_out[31:24]};
			endcase
		end
		regfilemux::lh: begin
			unique case(conn.dpath.alu_out[1:0])
				4'b00: conn.dpath.regfilemux_out = {{16{conn.dpath.mdr_out[15]}}, conn.dpath.mdr_out[15:0]};
				4'b01: conn.dpath.regfilemux_out = {{16{conn.dpath.mdr_out[23]}}, conn.dpath.mdr_out[23:8]};
				4'b10: conn.dpath.regfilemux_out = {{16{conn.dpath.mdr_out[31]}}, conn.dpath.mdr_out[31:16]};
				4'b11: conn.dpath.regfilemux_out = 32'd0;
			endcase
		end
		regfilemux::lhu: begin
			unique case(conn.dpath.alu_out[1:0])
            4'b00: conn.dpath.regfilemux_out = {16'd0, conn.dpath.mdr_out[15:0]};
            4'b01: conn.dpath.regfilemux_out = {16'd0, conn.dpath.mdr_out[23:8]};
            4'b10: conn.dpath.regfilemux_out = {16'd0, conn.dpath.mdr_out[31:16]};
            4'b11: conn.dpath.regfilemux_out = 32'd0;
			endcase
		end
	endcase

	unique case (conn.ctrl.cmpmux_sel)
		cmpmux::rs2_out: conn.dpath.cmp_mux_out = conn.dpath.rs2_out;
		cmpmux::i_imm: conn.dpath.cmp_mux_out = conn.dpath.i_imm;
		default: `BAD_MUX_SEL;
	endcase

	unique case (conn.dpath.funct3)
		rv32i_types::sb, rv32i_types::sh:
			mem_data_out_in = (conn.dpath.rs2_out << {conn.dpath.alu_out[1:0], 3'd0});
		default: mem_data_out_in = conn.dpath.rs2_out;
	endcase
end
/*****************************************************************************/
endmodule : datapath
