module ripple_adder(
    input [31:0] A,
    input [31:0] B,
    input Cin,
    output [31:0] Sum,
    output Cout);
    wire [31:0]carry;
    
    assign {carry[0],Sum[0]} = A[0]+B[0]+ Cin;
    genvar i;
    generate
        for(i=1;i<32;i=i+1)
        begin:fa_loop
           assign {carry[i], Sum[i]} = A[i] + B[i] + carry[i-1];
        end
        
    endgenerate
    assign Cout = carry[31];
endmodule
