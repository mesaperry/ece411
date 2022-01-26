module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

	enum {S1, S2, S3, S4, S5} state;
    logic reading;
    logic writing;
	
	always_ff @(posedge clk) begin
		
		if (reset_n <= 1'b0) begin
			state <= S1;
			reading <= 1'b0;
			writing <= 1'b0;
			read_o <= 1'b0;
			write_o <= 1'b0;
		end
		else if (read_i == 1'b1 && reading == 1'b0) begin
            state <= S1;
			reading <= 1'b1;
			read_o <= 1'b1;
			write_o <= 1'b0;
			address_o <= address_i;
		end
		else if (write_i == 1'b1 && writing == 1'b0) begin
            state <= S1;
			writing <= 1'b1;
			read_o <= 1'b0;
			write_o <= 1'b1;
			address_o <= address_i;
			burst_o <= line_i[63:0];
		end
		
		if (writing == 1'b1) begin
			case (state)
				S1: begin
					if (resp_i == 1'b1) begin
                        state <= S2;
						burst_o <= line_i [127:64];
					end
				end
				S2: begin
					if (resp_i == 1'b1) begin
                        state <= S3;
						burst_o <= line_i [191:128];
					end
				end
				S3: begin
					if (resp_i == 1'b1) begin
                        state <= S4;
						burst_o <= line_i [255:192];
					end
				end
				S4: begin					
					if (resp_i == 1'b1) begin
                        state <= S5;
						resp_o <= 1'b1;
					end
				end
				S5: begin
					state <= S5;
					writing <= 1'b0;
					resp_o <= 1'b0;
					write_o <= 1'b0;
				end
			endcase
		
		end
		
		if (reading == 1'b1) begin
			case (state)
				S1: begin
					if (resp_i == 1'b1) begin
                        state <= S2;
						line_o [63:0] <= burst_i;
					end
				end
				S2: begin
					if (resp_i == 1'b1) begin
                        state <= S3;
						line_o [127:64] <= burst_i;
					end
				end
				S3: begin
					if (resp_i == 1'b1) begin
                        state <= S4;
						line_o [191:128] <= burst_i;
					end
				end
				S4: begin					
					if (resp_i == 1'b1) begin
                        state <= S5;
						line_o [255:192] <= burst_i;
						resp_o <= 1'b1;
					end
				end
				S5: begin
                    state <= S1;
					reading <= 1'b0;
					resp_o <= 1'b0;
					read_o <= 1'b0;
				end
			endcase
		end
		
	end
endmodule : cacheline_adaptor
