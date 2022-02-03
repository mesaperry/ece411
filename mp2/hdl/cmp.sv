import rv32i_types::*;

module cmp (
    input branch_funct3_t op,
    input rv32i_word a, b,
    output logic f
);

always_comb
begin
    unique case (op)
			rv32i_types::beq: f = (a == b);
			rv32i_types::bne: f = (a != b);
			rv32i_types::blt: f = ($signed(a) < $signed(b));
			rv32i_types::bge: f = ($signed(a) >= $signed(b));
			rv32i_types::bltu: f = (a < b);
			rv32i_types::bgeu: f = (a >= b);
    endcase
end

endmodule : cmp
