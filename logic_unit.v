module logic_unit(
    input  [31:0] A,
    input  [31:0] B,
    input  [1:0]  sel,  
    output reg [31:0] Y
);
always @(*) begin
    case (sel)
        2'b00: Y = A & B;
        2'b01: Y = A | B;
        2'b10: Y = A ^ B;
        default: Y = 32'b0;
    endcase
end
endmodule
