/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

import connections::*;

module cache #(
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

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic [255:0] bus_wdata;
logic [255:0] bus_rdata;
logic [31:0] mem_byte_enable256;

logic [255:0] cacheline_out;
assign pmem_wdata = cacheline_out;
assign bus_rdata = cacheline_out;

connections::ctrl_out ctrl_out;
connections::dpath_out dpath_out;

cache_control control(
	.clk,
	.rst,
   .mem_read,
   .mem_write,
   .mem_resp,
   .pmem_read,
   .pmem_write,
   .pmem_resp,
	.ctrl_out(ctrl_out),
	.dpath_in(dpath_out)
);

cache_datapath datapath(
	.clk,
	.rst,
	.mem_address,
	.bus_wdata,
	.bus_byte_enable(mem_byte_enable256),
	.pmem_address,
	.cacheline_in(pmem_rdata),
	.cacheline_out,
	.dpath_out(dpath_out),
	.ctrl_in(ctrl_out)
);

bus_adapter bus_adapter(
	.mem_wdata256(bus_wdata),
	.mem_rdata256(bus_rdata),
	.mem_wdata,
	.mem_rdata,
	.mem_byte_enable,
	.mem_byte_enable256,
	.address(mem_address)
);

endmodule : cache
