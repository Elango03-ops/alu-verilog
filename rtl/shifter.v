module shifter(
    input  [31:0] A,
    input  [4:0]  shamt,
    input  [2:0]  sel,   
    output reg [31:0] Y
);
always @(*) begin
    case (sel)
        3'd0: Y = A << shamt;
        3'd1: Y = A >> shamt;
        3'd2: Y = $signed(A) >>> shamt;
        3'd3: Y = (A << shamt) | (A >> (32-shamt));
        3'd4: Y = (A >> shamt) | (A << (32-shamt));
        default: Y = 32'b0;
    endcase
end
endmodule
