/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

import connections::*;

module cache_control (
    input clk,
    input rst,
	 
    input   logic          mem_read,
    input   logic          mem_write,
    output  logic          mem_resp,
	 
    output  logic          pmem_read,
    output  logic          pmem_write,
    input   logic				pmem_resp,
	 
	 output connections::ctrl_out ctrl_out,
	 input connections::dpath_out dpath_in
);


enum { idle, search, evict, read_mem } state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end


function void set_defaults();
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	
	ctrl_out.tag_ld = 2'b00;
	ctrl_out.dirty_ld = 2'b00;
	ctrl_out.dirty_in = 2'b00;
	ctrl_out.lru_ld = 1'b0;
	ctrl_out.lru_in = 1'b0;
	ctrl_out.valid_ld = 2'b00;
	ctrl_out.valid_in = 2'b00;
//	datain_sel_t [1:0] write_sel;
	ctrl_out.write_en_sel1 = no_write;
	ctrl_out.write_en_sel2 = no_write;
	ctrl_out.output_sel = 1'b0;
	ctrl_out.pmem_address = cpu;
endfunction


// state outputs
always_comb begin
	set_defaults();
	
	case (state)
		idle: begin
			
		end
		search: begin
			if (dpath_in.cache_hit) begin
				mem_resp = 1'b1;
				ctrl_out.output_sel = dpath_in.way_hit;
			end
		end
		evict: begin
			// TODO: write to mem
			ctrl_out.valid_ld[dpath_in.lru_out] = 1'b1;
			ctrl_out.valid_in[dpath_in.lru_out] = 1'b0;
		end
		read_mem: begin
			pmem_read = 1'b1;
			if (dpath_in.lru_out == 1'b0) begin
				ctrl_out.write_en_sel1 = write_all;
			end else begin
				ctrl_out.write_en_sel2 = write_all;
			end
			ctrl_out.tag_ld[dpath_in.lru_out] = 1'b1;
			ctrl_out.valid_ld[dpath_in.lru_out] = 1'b1;
			ctrl_out.valid_in[dpath_in.lru_out] = 1'b1;
			ctrl_out.lru_in = ~dpath_in.lru_out;
			if (pmem_resp) begin
				ctrl_out.lru_ld = 1'b1;
			end
		end
	endcase
end


// next state flow
always_comb begin
	if (rst) begin
		next_state = idle;
	end else begin
		case (state)
			idle: begin
				if (mem_read || mem_write) begin
					next_state = search;
				end else begin
					next_state = idle;
				end
			end
			search: begin
				if (dpath_in.cache_hit) begin
					next_state = idle;
				end else begin
					if (dpath_in.valid_out[dpath_in.lru_out]) begin
						next_state = evict;
					end else begin
						next_state = read_mem;
					end
				end
			end
			evict: begin
				next_state = search;
			end
			read_mem: begin
				if (~pmem_resp) begin
					next_state = read_mem;
				end else begin
					next_state = search;
				end
			end
		endcase
	end
end

endmodule : cache_control
