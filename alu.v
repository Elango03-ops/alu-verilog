module alu(
    input  [31:0] A,
    input  [31:0] B,
    input         cin,
    input  [4:0]  shamt,
    input  [4:0]  opcode,
    output reg [31:0] result,
    output reg        carryout,
    output reg        overflow,
    output reg        zero
);

    // opcode map
    localparam OP_ADD  = 5'd0;
    localparam OP_SUB  = 5'd1;
    localparam OP_AND  = 5'd2;
    localparam OP_OR   = 5'd3;
    localparam OP_XOR  = 5'd4;
    localparam OP_SLL  = 5'd5;
    localparam OP_SRL  = 5'd6;
    localparam OP_SRA  = 5'd7;
    localparam OP_ROTL = 5'd8;
    localparam OP_ROTR = 5'd9;
    localparam OP_SLT  = 5'd10;

    // internal wires
    wire [31:0] adder_sum;
    wire        adder_cout;
    wire [31:0] logic_out;
    wire [31:0] shifter_y;

    reg  [1:0]  logic_sel;
    reg  [2:0]  shifter_sel;

    wire [31:0] adder_B   = (opcode == OP_SUB) ? ~B : B;
    wire        adder_cin = (opcode == OP_SUB) ? 1'b1 : cin;

    // ripple adder
    ripple_adder u_ripple_adder (
        .A(A),
        .B(adder_B),
        .Cin(adder_cin),
        .Sum(adder_sum),
        .Cout(adder_cout)
    );

    // logic unit
    logic_unit u_logic_unit (
        .A(A),
        .B(B),
        .sel(logic_sel),
        .Y(logic_out)
    );

    // shifter
    shifter u_shifter (
        .A(A),
        .shamt(shamt),
        .sel(shifter_sel),
        .Y(shifter_y)
    );

    // ALU control + result select
    always @(*) begin
        result       = 32'b0;
        carryout     = 1'b0;
        overflow     = 1'b0;
        zero         = 1'b0;
        logic_sel    = 2'b00;
        shifter_sel  = 3'b000;

        case (opcode)

            OP_ADD: begin
                result   = adder_sum;
                carryout = adder_cout;
                overflow = (A[31] & B[31] & ~result[31]) |
                           (~A[31] & ~B[31] & result[31]);
            end

            OP_SUB: begin
                result   = adder_sum;
                carryout = adder_cout;
                overflow = (A[31] & ~B[31] & ~result[31]) |
                           (~A[31] &  B[31] &  result[31]);
            end

            OP_AND: begin
                logic_sel = 2'b00;
                result    = logic_out;
            end

            OP_OR: begin
                logic_sel = 2'b01;
                result    = logic_out;
            end

            OP_XOR: begin
                logic_sel = 2'b10;
                result    = logic_out;
            end

            OP_SLL:  begin shifter_sel = 3'd0; result = shifter_y; end
            OP_SRL:  begin shifter_sel = 3'd1; result = shifter_y; end
            OP_SRA:  begin shifter_sel = 3'd2; result = shifter_y; end
            OP_ROTL: begin shifter_sel = 3'd3; result = shifter_y; end
            OP_ROTR: begin shifter_sel = 3'd4; result = shifter_y; end

            OP_SLT: begin
                result = {31'b0, ($signed(A) < $signed(B))};
            end

            default: result = 32'b0;
        endcase

        zero = (result == 32'b0);
    end
endmodule
