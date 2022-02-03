import rv32i_types::*;
import pcmux::*;
import marmux::*;
import regfilemux::*;
import alumux::*;
import cmpmux::*;

package connections;

typedef struct packed {
	logic load_pc;
	logic load_mar;
	logic load_ir;
	logic load_regfile;
	logic load_data_out;
	logic load_mdr;
	pcmux::pcmux_sel_t pcmux_sel;
	marmux::marmux_sel_t marmux_sel;
	alumux::alumux1_sel_t alumux1_sel;
	alumux::alumux2_sel_t alumux2_sel;
	rv32i_types::alu_ops aluop;
	regfilemux::regfilemux_sel_t regfilemux_sel;
	cmpmux::cmpmux_sel_t cmpmux_sel;
	rv32i_types::branch_funct3_t cmpop;
} control_pack;

typedef struct packed {
	rv32i_types::rv32i_reg rs1;
	rv32i_types::rv32i_reg rs2;
	rv32i_types::rv32i_reg rd;
	rv32i_types::rv32i_reg rs1_out;
	rv32i_types::rv32i_reg rs2_out;
	rv32i_types::rv32i_word i_imm;
	rv32i_types::rv32i_word u_imm;
	rv32i_types::rv32i_word b_imm;
	rv32i_types::rv32i_word s_imm;
	rv32i_types::rv32i_word j_imm;
	rv32i_types::rv32i_word pcmux_out;
	rv32i_types::rv32i_word pc_out;
	rv32i_types::rv32i_word pc4_out;
	rv32i_types::rv32i_word marmux_out;
	rv32i_types::rv32i_word mem_address;
	rv32i_types::rv32i_word alumux1_out;
	rv32i_types::rv32i_word alumux2_out;
	rv32i_types::rv32i_word alu_out;
	rv32i_types::rv32i_word mem_wdata;
	rv32i_types::rv32i_word mem_rdata;
	rv32i_types::rv32i_word mdr_out;
	rv32i_types::rv32i_word regfilemux_out;
	rv32i_types::rv32i_word cmp_mux_out;
	rv32i_types::rv32i_opcode opcode;
	logic [2:0] funct3;
	logic [6:0] funct7;
	logic br_en;
	} datapath_pack;

typedef struct packed {
	control_pack ctrl;
	datapath_pack dpath;
} rv32i_pack;

endpackage : connections