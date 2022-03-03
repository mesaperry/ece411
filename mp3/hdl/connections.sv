package connections;

typedef enum {
	cacheline,
	bus_adaptor
} datain_sel_t;

typedef enum {
	no_write,
	write_all,
	cpu_write
} write_en_sel_t;

//typedef enum {
//	data_way1,
//	data_way2
//} cacheline_sel_t;

typedef enum {
	cpu,
	write_dirt
} pmem_sel_t;

typedef struct packed {
	logic [1:0] tag_ld;
	logic [1:0] dirty_ld;
	logic [1:0] dirty_in;
	logic lru_ld;
	logic lru_in;
	logic [1:0] valid_ld;
	logic [1:0] valid_in;
	logic output_sel;

	datain_sel_t write_sel1;
	datain_sel_t write_sel2;
	write_en_sel_t write_en_sel1;
	write_en_sel_t write_en_sel2;

	pmem_sel_t pmem_address;
} ctrl_out;

typedef struct packed {
	logic cache_hit;
	logic way_hit;
	logic lru_out;
	logic [1:0] valid_out;
	logic [1:0] dirty_out;
} dpath_out;

endpackage