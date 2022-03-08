package connections;

typedef enum {
	cacheline,
	bus_adaptor
} datain_sel_t;

typedef enum {
	nowrite,
	writeall,
	cpuwrite
} write_en_sel_t;

typedef enum {
	data_way1,
	data_way2
} output_sel_t;

typedef enum {
	cpu,
	write_dirt
} pmem_sel_t;

typedef struct packed {
	logic ld_tag_1;
	logic ld_tag_2;
	logic ld_dirty_1;
	logic dirty_in_1;
	logic ld_dirty_2;
	logic dirty_in_2;
	logic ld_lru;
	logic lru_in;
	logic ld_valid;
	logic write_sel_1;
	logic write_sel_2;
	logic output_sel;
	logic pmem_address;
	logic [1:0] valid_in;
	logic [1:0] write_en_sel1;
	logic [1:0] write_en_sel2;
} ctrl_out;

typedef struct packed {
	logic dirty1;
	logic dirty2;
	logic lru;
	logic [23:0] tag1;
	logic [23:0] tag2;
	logic [1:0] valid;
	logic [255:0] cacheline_out;
} dpath_out;

endpackage
