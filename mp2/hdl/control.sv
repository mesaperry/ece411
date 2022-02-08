import rv32i_types::*; /* Import types defined in rv32i_types.sv */
import connections::*;

module control
(
    input clk,
    input rst,
	 
    input logic mem_resp,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
	 
	 input datapath_pack dpath_in,
	 output control_pack ctrl_out
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(dpath_in.funct3);
assign branch_funct3 = branch_funct3_t'(dpath_in.funct3);
assign load_funct3 = load_funct3_t'(dpath_in.funct3);
assign store_funct3 = store_funct3_t'(dpath_in.funct3);
assign rs1_addr = dpath_in.rs1;
assign rs2_addr = dpath_in.rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (dpath_in.opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                rv32i_types::lw: rmask = 4'b1111;
                rv32i_types::lh, rv32i_types::lhu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                rv32i_types::lb, rv32i_types::lbu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                rv32i_types::sw: wmask = 4'b1111;
                rv32i_types::sh: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                rv32i_types::sb: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	fetch1        = 0,
	fetch2        = 1,
	fetch3        = 2,
	decode        = 3,
	imm           = 4,
	lui           = 5,
	calc_addr_ld  = 6,
	calc_addr_st  = 7,
	ld1           = 8,
	ld2           = 9,
	st1           = 10,
	st2           = 11,
	auipc         = 12,
	br            = 13,
	reg_op        = 14,
	jal           = 15,
	jalr          = 16
} state, next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
	mem_byte_enable = 4'b1111;
	mem_read = 1'b0;
	mem_write = 1'b0;
	ctrl_out.load_pc = 1'b0;
	ctrl_out.load_ir = 1'b0;
	ctrl_out.load_regfile = 1'b0;
	ctrl_out.load_mar = 1'b0;
	ctrl_out.load_mdr = 1'b0;
	ctrl_out.load_data_out = 1'b0;
	ctrl_out.pcmux_sel = pcmux::pc_plus4;
	ctrl_out.alumux1_sel = alumux::rs1_out;
	ctrl_out.alumux2_sel = alumux::i_imm;
	ctrl_out.regfilemux_sel = regfilemux::alu_out;
	ctrl_out.marmux_sel = marmux::pc_out;
	ctrl_out.cmpmux_sel = cmpmux::rs2_out;
	ctrl_out.aluop = rv32i_types::alu_ops ' (dpath_in.funct3);
	ctrl_out.cmpop = rv32i_types::branch_funct3_t ' (dpath_in.funct3);
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    ctrl_out.load_pc = 1'b1;
    ctrl_out.pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
endfunction

function void loadMDR();
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */


    if (setop)
        ctrl_out.aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
	/* Default output assignments */
	set_defaults();
	/* Actions for each state */
	case (state)
		fetch1: begin
			ctrl_out.load_mar = 1'b1;
			ctrl_out.marmux_sel = marmux::pc_out;
		end
		fetch2: begin
			ctrl_out.load_mdr = 1'b1;
			mem_read = 1'b1;
      end
		fetch3:
			ctrl_out.load_ir = 1'b1;
		imm:
			case (dpath_in.funct3)
				rv32i_types::slt: begin
					ctrl_out.load_regfile = 1'b1;
					ctrl_out.load_pc = 1'b1;
					ctrl_out.cmpop = rv32i_types::blt;
					ctrl_out.cmpmux_sel = cmpmux::i_imm;
					ctrl_out.regfilemux_sel = regfilemux::br_en;
				end
				rv32i_types::sltu: begin
					ctrl_out.load_regfile = 1'b1;
					ctrl_out.load_pc = 1'b1;
					ctrl_out.cmpop = rv32i_types::bltu;
					ctrl_out.cmpmux_sel = cmpmux::i_imm;
					ctrl_out.regfilemux_sel = regfilemux::br_en;
				end
				rv32i_types::sr: begin
					ctrl_out.load_regfile = 1'b1;
					ctrl_out.load_pc = 1'b1;
					ctrl_out.regfilemux_sel = regfilemux::alu_out;
					ctrl_out.aluop = dpath_in.funct7 == 7'b0100000 ?
						rv32i_types::alu_sra : rv32i_types::alu_srl;
				end
				default: begin
					ctrl_out.load_regfile = 1'b1;
					ctrl_out.load_pc = 1'b1;
					ctrl_out.aluop = alu_ops ' (dpath_in.funct3);
					ctrl_out.regfilemux_sel = regfilemux::alu_out;
				end
			endcase
		lui: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.regfilemux_sel = regfilemux::u_imm;
      end
		calc_addr_ld: begin
			ctrl_out.load_mar = 1'b1;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
      end
		ld1: begin
			ctrl_out.load_mdr = 1'b1;
			mem_read = 1'b1;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
      end
		ld2: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
			case (dpath_in.funct3)
				rv32i_types::lb: ctrl_out.regfilemux_sel = regfilemux::lb;
				rv32i_types::lh: ctrl_out.regfilemux_sel = regfilemux::lh;
				rv32i_types::lw: ctrl_out.regfilemux_sel = regfilemux::lw;
				rv32i_types::lbu: ctrl_out.regfilemux_sel = regfilemux::lbu;
				rv32i_types::lhu: ctrl_out.regfilemux_sel = regfilemux::lhu;
				default: ctrl_out.regfilemux_sel = regfilemux::alu_out;
			endcase
      end
		calc_addr_st: begin
			ctrl_out.load_mar = 1'b1;
			ctrl_out.load_data_out = 1'b1;
			ctrl_out.alumux2_sel = alumux::s_imm;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
      end
		st1: begin
			mem_read = 1'b0;
			mem_write = 1'b1;
			ctrl_out.alumux2_sel = alumux::s_imm;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
			case (dpath_in.funct3)
				rv32i_types::sb: mem_byte_enable = (4'b0001 << dpath_in.mem_address[1:0]);
				rv32i_types::sh: mem_byte_enable = (4'b0011 << dpath_in.mem_address[1:0]);
				default: mem_byte_enable = 4'b1111;
			endcase
      end
		st2: begin
			ctrl_out.load_pc = 1'b1;
			ctrl_out.alumux2_sel = alumux::s_imm;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.marmux_sel = marmux::alu_out;
      end
		auipc: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.alumux1_sel = alumux::pc_out;
			ctrl_out.alumux2_sel = alumux::u_imm;
			ctrl_out.regfilemux_sel = regfilemux::alu_out;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.pcmux_sel = pcmux::pc_plus4;
			ctrl_out.marmux_sel = marmux::alu_out;
      end
		br: begin
			ctrl_out.load_pc = 1'b1;
			ctrl_out.pcmux_sel = pcmux::pcmux_sel_t ' (dpath_in.br_en);
			ctrl_out.alumux1_sel = alumux::pc_out;
			ctrl_out.alumux2_sel = alumux::b_imm;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.cmpop = rv32i_types::branch_funct3_t ' (dpath_in.funct3);
      end
      reg_op: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.aluop = rv32i_types::alu_ops ' (dpath_in.funct3);
			ctrl_out.alumux2_sel = alumux::rs2_out;
			ctrl_out.regfilemux_sel = regfilemux::alu_out;
			if ((dpath_in.funct3 == rv32i_types::add) && (dpath_in.funct7 == 7'b0000000))
				ctrl_out.aluop = rv32i_types::alu_add;
			else if ((dpath_in.funct3 == rv32i_types::add) && (dpath_in.funct7 == 7'b0100000))
				ctrl_out.aluop = rv32i_types::alu_sub;
			else if ((dpath_in.funct3 == rv32i_types::sll))
				ctrl_out.aluop = rv32i_types::alu_sll;
			else if ((dpath_in.funct3 == rv32i_types::slt)) begin
				ctrl_out.cmpop = rv32i_types::blt;
				ctrl_out.cmpmux_sel = cmpmux::rs2_out;
				ctrl_out.regfilemux_sel = regfilemux::br_en;
			end
			else if ((dpath_in.funct3 == rv32i_types::sltu)) begin
				ctrl_out.cmpop = rv32i_types::bltu;
				ctrl_out.cmpmux_sel = cmpmux::rs2_out;
				ctrl_out.regfilemux_sel = regfilemux::br_en;
			end
			else if ((dpath_in.funct3 == rv32i_types::axor))
				ctrl_out.aluop = rv32i_types::alu_xor;
			else if ((dpath_in.funct3 == rv32i_types::sr) && (dpath_in.funct7 == 7'b0000000))
				ctrl_out.aluop = rv32i_types::alu_srl;
			else if ((dpath_in.funct3 == rv32i_types::sr) && (dpath_in.funct7 == 7'b0100000))
				ctrl_out.aluop = rv32i_types::alu_sra;
			else
				ctrl_out.aluop = rv32i_types::alu_ops ' (dpath_in.funct3);
      end
      jal: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.regfilemux_sel = regfilemux::pc_plus4;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.alumux1_sel = alumux::pc_out;
			ctrl_out.alumux2_sel = alumux::j_imm;
			ctrl_out.pcmux_sel = pcmux::alu_mod2;
      end
      jalr: begin
			ctrl_out.load_regfile = 1'b1;
			ctrl_out.load_pc = 1'b1;
			ctrl_out.regfilemux_sel = regfilemux::pc_plus4;
			ctrl_out.aluop = rv32i_types::alu_add;
			ctrl_out.alumux1_sel = alumux::rs1_out;
			ctrl_out.alumux2_sel = alumux::i_imm;
			ctrl_out.pcmux_sel = pcmux::alu_mod2;
      end
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	if (rst) begin
		next_state <= fetch1;
	end else begin
		case (state)
			fetch1:
				next_state <= fetch2;
			fetch2:
				next_state <= mem_resp == 1'b0 ? fetch2 : fetch3;
			fetch3:
				next_state <= decode;
			decode:
				unique case(dpath_in.opcode)
					rv32i_types::op_imm: next_state <= imm;
					rv32i_types::op_lui: next_state <= lui;
					rv32i_types::op_load: next_state <= calc_addr_ld;
					rv32i_types::op_store: next_state <= calc_addr_st;
					rv32i_types::op_auipc: next_state <= auipc;
					rv32i_types::op_br: next_state <= br;
					rv32i_types::op_reg: next_state <= reg_op;
					rv32i_types::op_jal: next_state <= jal;
					rv32i_types::op_jalr: next_state <= jalr;
					default: next_state <= fetch1;
				endcase
			calc_addr_ld:
				next_state <= ld1;
			ld1:
				next_state <= mem_resp == 1'b0 ? ld1 : ld2;
			calc_addr_st:
				next_state <= st1;
			st1:
				next_state <= mem_resp == 1'b0 ? st1 : st2;
			default:
				next_state <= fetch1;
		endcase
	end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control
