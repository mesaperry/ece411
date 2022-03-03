/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

import connections::*;

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rst,
	 
	input   logic [31:0]    mem_address,
	input   logic [255:0]   bus_wdata,
	input   logic [31:0]    bus_byte_enable,

	output  logic [31:0]    pmem_address,
	input   logic [255:0]   cacheline_in,
	output  logic [255:0]   cacheline_out,

	output connections::dpath_out dpath_out,
	input connections::ctrl_out ctrl_in
);

logic [23:0] tag1_out;
logic [23:0] tag2_out;

logic tag1_match;
logic tag2_match;


assign tag1_match = (tag1_out == mem_address[31:8]) && dpath_out.valid_out[0];
assign tag2_match = (tag2_out == mem_address[31:8]) && dpath_out.valid_out[1];
assign dpath_out.cache_hit = tag1_match || tag2_match;
assign dpath_out.way_hit = tag2_match;


array #(.s_index(s_index), .width(s_tag))
tag_array_1(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.tag_ld[0]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(mem_address[31:8]),
	.dataout(tag1_out)
);

array #(.s_index(s_index), .width(s_tag))
tag_array_2(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.tag_ld[1]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(mem_address[31:8]),
	.dataout(tag2_out)
);

array #(.s_index(s_index), .width(1))
lru_array(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.lru_ld),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(ctrl_in.lru_in),
	.dataout(dpath_out.lru_out)
);

array #(.s_index(s_index), .width(1))
valid_array_1(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.valid_ld[0]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(ctrl_in.valid_in[0]),
	.dataout(dpath_out.valid_out[0])
);

array #(.s_index(s_index), .width(1))
valid_array_2(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.valid_ld[1]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(ctrl_in.valid_in[1]),
	.dataout(dpath_out.valid_out[1])
);

array #(.s_index(s_index), .width(1))
dirty_array_1(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.dirty_ld[0]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(ctrl_in.dirty_in[0]),
	.dataout(dpath_out.dirty_out[0])
);

array #(.s_index(s_index), .width(1))
dirty_array_2(
	.clk(clk),
	.rst(rst),
	.read(1'b1),
	.load(ctrl_in.dirty_ld[1]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(ctrl_in.dirty_in[1]),
	.dataout(dpath_out.dirty_out[1])
);

logic [255:0] data_in [1:0];
logic [255:0] data_out [1:0];
logic [31:0] data_wen [1:0];

data_array way1(
	.clk(clk),
	.read(1'b1),
	.write_en(data_wen[0]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(data_in[0]),
	.dataout(data_out[0])
);

data_array way2(
	.clk(clk),
	.read(1'b1),
	.write_en(data_wen[1]),
	.rindex(mem_address[7:5]),
	.windex(mem_address[7:5]),
	.datain(data_in[1]),
	.dataout(data_out[1])
);


// muxes
always_comb begin
	case (ctrl_in.write_sel1)
		default: data_in[0] = cacheline_in;
	endcase

	case (ctrl_in.write_sel2)
		default: data_in[1] = cacheline_in;
	endcase

	case (ctrl_in.write_en_sel1)
		no_write: data_wen[0] = 32'd0;
		write_all: data_wen[0] = {{32{1'b1}}};
	endcase

	case (ctrl_in.write_en_sel2)
		no_write: data_wen[1] = 32'd0;
		write_all: data_wen[1] = {{32{1'b1}}};
	endcase
	
	cacheline_out = data_out[ctrl_in.output_sel];

	case (ctrl_in.pmem_address)
		default: pmem_address = {mem_address[31:5], 5'd0};
	endcase
end

endmodule : cache_datapath
