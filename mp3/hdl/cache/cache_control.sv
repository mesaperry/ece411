import connections::*;

module cache_control (
	input clk,
	input rst,

	input cpu_write,
	input cpu_read,

	input mem_resp,
	output logic cache_resp,
	output logic mem_read,
	output logic mem_write,

	output connections::ctrl_out ctrl_out,
	input connections::dpath_out dpath_in,
	input logic [31:0] address
);

logic hit;
logic dirty;
logic set_hit;
logic set_1_hit;
logic set_2_hit;
logic set_1_old;
logic set_2_old;

logic safe_write;
logic safe_read;

assign hit = ((dpath_in.tag1 == address[31:8]) && dpath_in.valid[0]) || ((dpath_in.tag2 == address[31:8]) && dpath_in.valid[1]);
assign dirty = dpath_in.lru ? dpath_in.dirty1 : dpath_in.dirty2;

assign set_hit = (dpath_in.tag1 == address[31:8]) ? 1'b0 : 1'b1;
assign set_1_hit = (set_hit == 1'b0);
assign set_2_hit = (set_hit == 1'b1);
assign set_1_old = (dpath_in.lru == 1'b0) ? 1'b0 : 1'b1;
assign set_2_old = (dpath_in.lru == 1'b1) ? 1'b0 : 1'b1;

assign safe_write = cpu_write && (~cpu_read);
assign safe_read = cpu_read && (~cpu_write);

enum int unsigned {
	reset,
	idle,
	write_hit,
	read_hit,
	read_mem,
	write_dirt,
	write_data,
	return_data
} state, next_state;

// state update
always_ff @(posedge clk) begin
      state <= next_state;
end

// state output values

function void set_defaults();
      ctrl_out.write_en_sel1 = nowrite;
      ctrl_out.write_en_sel2 = nowrite;
      ctrl_out.write_sel_1 = cacheline;
      ctrl_out.write_sel_2 = cacheline;
      ctrl_out.output_sel = data_way1;
      ctrl_out.pmem_address = cpu;
      ctrl_out.ld_tag_1 = 1'b0;
      ctrl_out.ld_tag_2 = 1'b0;
      ctrl_out.ld_dirty_1 = 1'b0;
      ctrl_out.ld_dirty_2 = 1'b0;
      ctrl_out.dirty_in_1 = 1'b0;
      ctrl_out.dirty_in_2 = 1'b0;
      ctrl_out.ld_lru = 1'b0;
      ctrl_out.lru_in = 1'b0;
      ctrl_out.ld_valid = 1'b0;
      ctrl_out.valid_in = 2'b0;
      cache_resp = 1'b0;
      mem_read = 1'b0;
      mem_write = 1'b0;
endfunction

always_comb begin
      set_defaults();

      if((state == write_hit) && hit) begin
            ctrl_out.ld_dirty_1 = set_1_hit;
            ctrl_out.ld_dirty_2 = set_2_hit;
            ctrl_out.ld_lru = 1'b1;
            ctrl_out.dirty_in_1 = 1'b1;
            ctrl_out.dirty_in_2 = 1'b1;
            ctrl_out.lru_in = set_hit;
            ctrl_out.write_en_sel1 = set_1_hit ? cpuwrite : nowrite;
            ctrl_out.write_en_sel2 = set_2_hit ? cpuwrite : nowrite;
            cache_resp = 1'b1;
            ctrl_out.write_sel_1 = bus_adaptor;
            ctrl_out.write_sel_2 = bus_adaptor;
            ctrl_out.output_sel = set_hit;
      end

      else if((state == read_hit) && hit) begin
            ctrl_out.ld_lru = 1'b1;
            ctrl_out.lru_in = set_hit;
            ctrl_out.output_sel = set_hit;
            cache_resp = 1'b1;
      end

      else if (state == write_dirt) begin
            mem_write = 1'b1;
            ctrl_out.output_sel = ~(dpath_in.lru);
            ctrl_out.pmem_address = write_dirt;
      end

      else if (state == read_mem) begin
            if(dpath_in.valid == 2'b00) begin
                  ctrl_out.ld_tag_1 = 1'b1;
                  ctrl_out.dirty_in_1 = 1'b0;
                  ctrl_out.ld_dirty_1 = 1'b1;
                  ctrl_out.write_en_sel1 = writeall;
                  mem_read = 1'b1;
                  ctrl_out.write_sel_1 = cacheline;
            end else if(dpath_in.valid == 2'b01) begin
                  ctrl_out.ld_dirty_2 = 1'b1;
                  ctrl_out.ld_tag_2 = 1'b1;
                  ctrl_out.dirty_in_2 = 1'b0;
                  ctrl_out.write_sel_2 = cacheline;
                  ctrl_out.write_en_sel2 = writeall;
                  mem_read = 1'b1;
            end else begin
                  ctrl_out.ld_tag_1 = set_1_old;
                  ctrl_out.ld_tag_2 = set_2_old;
                  ctrl_out.ld_dirty_1 = set_1_old;
                  ctrl_out.dirty_in_2 = 1'b0;
                  ctrl_out.dirty_in_1 = 1'b0;
                  ctrl_out.ld_dirty_2 = set_2_old;
                  ctrl_out.write_en_sel1 = set_1_old ? writeall : nowrite;
                  ctrl_out.write_en_sel2 = set_2_old ? writeall : nowrite;
                  ctrl_out.write_sel_2 = cacheline;
                  ctrl_out.write_sel_1 = cacheline;
                  mem_read = 1'b1;
            end
      end

      else if (state == return_data) begin
            if(dpath_in.valid == 2'b00) begin
                  ctrl_out.ld_dirty_1 = 1'b1;
                  ctrl_out.dirty_in_1 = 1'b0;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.lru_in = 1'b0;
                  ctrl_out.valid_in = 2'b01;
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.output_sel = data_way1;
                  cache_resp = 1'b1;
            end else if (dpath_in.valid == 2'b01) begin
                  cache_resp = 1'b1;
                  ctrl_out.dirty_in_2 = 1'b0;
                  ctrl_out.ld_dirty_2 = 1'b1;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.valid_in = 2'b11;
                  ctrl_out.lru_in = 1'b1;
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.output_sel = data_way2;
                  cache_resp = 1'b1;
            end else begin
                  ctrl_out.ld_dirty_1 = set_1_old;
                  ctrl_out.ld_dirty_2 = set_2_old;
                  ctrl_out.dirty_in_1 = 1'b0;
                  ctrl_out.valid_in = 2'b11;
                  ctrl_out.dirty_in_2 = 1'b0;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.lru_in = ~(dpath_in.lru);
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.output_sel = ~(dpath_in.lru);
                  cache_resp = 1'b1;
            end
      end

      else if (state == write_data) begin
            if(dpath_in.valid == 2'b00) begin
                  ctrl_out.ld_dirty_1 = 1'b1;
                  ctrl_out.dirty_in_1 = 1'b1;
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.lru_in = 1'b0;
                  ctrl_out.valid_in = 2'b01;
                  ctrl_out.write_en_sel1 = cpuwrite;
                  ctrl_out.write_sel_1 = bus_adaptor;
                  cache_resp = 1'b1;
                  ctrl_out.output_sel = 1'b0;
            end else if (dpath_in.valid == 2'b01) begin
                  ctrl_out.ld_dirty_2 = 1'b1;
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.valid_in = 2'b11;
                  ctrl_out.dirty_in_2 = 1'b1;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.lru_in = 1'b1;
                  ctrl_out.write_en_sel2 = cpuwrite;
                  ctrl_out.write_sel_2 = bus_adaptor;
                  cache_resp = 1'b1;
                  ctrl_out.output_sel = 1'b1;
            end else begin
                  ctrl_out.ld_dirty_1 = set_1_old;
                  ctrl_out.ld_dirty_2 = set_2_old;
                  ctrl_out.dirty_in_2 = 1'b1;
                  ctrl_out.dirty_in_1 = 1'b1;
                  ctrl_out.ld_lru = 1'b1;
                  ctrl_out.lru_in = ~(dpath_in.lru);
                  ctrl_out.ld_valid = 1'b1;
                  ctrl_out.valid_in = 2'b11;
                  ctrl_out.write_sel_1 = bus_adaptor;
                  ctrl_out.write_sel_2 = bus_adaptor;
                  ctrl_out.write_en_sel1 = set_1_old ? cpuwrite : nowrite;
                  ctrl_out.write_en_sel2 = set_2_old ? cpuwrite : nowrite;
                  cache_resp = 1'b1;
                  ctrl_out.output_sel = ~(dpath_in.lru);
            end
      end

end

// next state calculation
always_comb begin
      if(rst) begin
            next_state <= idle;

      end else begin

            if(state == idle) begin
                  if((safe_write == 0) && (safe_read == 0))
                        next_state <= idle;
                  else begin
                        if(hit && safe_write)
                              next_state <= write_hit;
                        else if(hit && safe_read)
                              next_state <= read_hit;
                        else if(!hit && safe_read)
                              next_state <= read_hit;
                        else
                              next_state <= write_hit;
                  end
            end

            else if(state == read_hit) begin
                  if(hit)
                        next_state <= idle;
                  else begin
                        if((!dirty) || (dpath_in.valid != 2'b11))
                              next_state <= read_mem;
                        else
                              next_state <= write_dirt;
                  end
            end

            else if(state == write_hit) begin
                  if(hit)
                        next_state <= idle;
                  else begin
                        if((!dirty) || (dpath_in.valid != 2'b11))
                              next_state <= read_mem;
                        else
                              next_state <= write_dirt;
                  end
            end

            else if(state == write_dirt) begin
                  if(!mem_resp)
                        next_state <= write_dirt;
                  else
                        next_state <= read_mem;
            end

            else if(state == read_mem) begin
                  if(!mem_resp)
                        next_state <= read_mem;
                  else if(cpu_write)
                        next_state <= write_data;
                  else
                        next_state <= return_data;
            end

            else
                  next_state <= idle;

      end
end

endmodule : cache_control
