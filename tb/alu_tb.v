
`timescale 1ns/1ps

module alu_selfcheck_tb;

   
    reg  [31:0] A;
    reg  [31:0] B;
    reg         cin;
    reg  [4:0]  shamt;
    reg  [4:0]  opcode;

    wire [31:0] result;
    wire        carryout;
    wire        overflow;
    wire        zero;

    
    alu uut (
        .A(A),
        .B(B),
        .cin(cin),
        .shamt(shamt),
        .opcode(opcode),
        .result(result),
        .carryout(carryout),
        .overflow(overflow),
        .zero(zero)
    );

    
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

    
    reg  [31:0] expected_result;
    reg         expected_carry;
    reg         expected_overflow;
    reg         expected_zero;
    reg  [31:0] r;
    reg  [32:0] tmp_result;  // one way to resolve carry error by using 33 bit temperoray result 

    
    integer idx;
    integer passcount;
    integer failcount;

    function [31:0] rotl;
        input [31:0] v;
        input [4:0] s;
        begin 
            rotl = (v << s) | (v >> (32-s));
        end
    endfunction

   
    function [31:0] rotr;
        input [31:0] v;
        input [4:0] s;
        begin 
            rotr = (v >> s) | (v << (32-s));
        end
    endfunction

   
    task expected;
        input [31:0] ta;
        input [31:0] tb;
        input tcin;
        input [4:0]  tshamt;
        input [4:0]  top;
        begin

          
            expected_result   = 32'b0;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;
            expected_zero     = 1'b0;

            case(top)

                OP_ADD: begin
                    {expected_carry, expected_result} = ta + tb + tcin;
                    expected_overflow = (ta[31] & tb[31] & ~expected_result[31]) |
                                        (~ta[31] & ~tb[31] & expected_result[31]);
                end

               
                OP_SUB: begin
                    tmp_result = {1'b0, ta} + {1'b0, ~tb} + 33'b1;
                    expected_carry = tmp_result[32];
                    expected_result = tmp_result[31:0];
                    expected_overflow = (ta[31] & ~tb[31] & ~expected_result[31]) |
                                        (~ta[31] & tb[31] & expected_result[31]);
                end

               
                OP_AND: begin
                    expected_result = ta & tb;
                end
                
                OP_OR: begin
                    expected_result = ta | tb;
                end

                OP_XOR: begin
                    expected_result = ta ^ tb;
                end

                
                OP_ROTL: begin 
                    expected_result = rotl(ta, tshamt);
                end

                OP_ROTR: begin
                    expected_result = rotr(ta, tshamt);
                end

                
                OP_SLL: begin
                    expected_result = ta << tshamt;
                end

                OP_SRL: begin
                    expected_result = ta >> tshamt;
                end

                OP_SLT: begin
                    expected_result = {31'b0, ($signed(ta) < $signed(tb))};
                end

                OP_SRA: begin
                    expected_result = $signed(ta) >>> tshamt;
                end

               
                default: begin
                    expected_result = 32'b0;
                end

            endcase

            
            expected_zero = (expected_result == 32'b0);
        end
    endtask

    
    task apply_and_check(input [31:0] ta, input [31:0] tb, input tcin, input [4:0] tshamt, input [4:0] top);
        begin
            
            A = ta; 
            B = tb; 
            cin = tcin; 
            shamt = tshamt; 
            opcode = top;
            #5;
            expected(ta, tb, tcin, tshamt, top);

            
            if(result != expected_result) begin
                $display("FAIL: time=%0t OP=%0d shamt=%0d A=%0h B=%0h | RESULT: GOT=%0h EXP=%0h",
                    $time, top, tshamt, ta, tb, result, expected_result);
                failcount = failcount + 1;
            end
           
            else if(carryout != expected_carry) begin
                $display("FAIL: time=%0t OP=%0d shamt=%0d A=%0h B=%0h | CARRYOUT: GOT=%0h EXP=%0h",
                    $time, top, tshamt, ta, tb, carryout, expected_carry);
                failcount = failcount + 1;
            end
          
            else if(overflow != expected_overflow) begin
                $display("FAIL: time=%0t OP=%0d shamt=%0d A=%0h B=%0h | OVERFLOW: GOT=%0h EXP=%0h",
                    $time, top, tshamt, ta, tb, overflow, expected_overflow);
                failcount = failcount + 1;
            end
            
            else if(zero != expected_zero) begin
                $display("FAIL: time=%0t OP=%0d shamt=%0d A=%0h B=%0h | ZERO: GOT=%0h EXP=%0h",
                    $time, top, tshamt, ta, tb, zero, expected_zero);
                failcount = failcount + 1;
            end
            
            else begin
                passcount = passcount + 1;
            end
        end
    endtask

    
    initial begin
       
        $dumpfile("alu_selfcheck_tb.vcd");
        $dumpvars(0, alu_selfcheck_tb);

       
        failcount = 0;
        passcount = 0;

        
        apply_and_check(32'd15, 32'd10, 1'b0, 5'd0, OP_ADD);
        apply_and_check(32'hFFFFFFFF, 32'h00000001, 1'b0, 5'd0, OP_ADD);
        apply_and_check(32'h40000000, 32'h40000000, 1'b0, 5'd0, OP_ADD);

       
        apply_and_check(32'd20, 32'd5, 1'b0, 5'd0, OP_SUB);
        apply_and_check(32'h7FFFFFFF, 32'hFFFFFFFF, 1'b0, 5'd0, OP_SUB);

        
        apply_and_check(32'hA5A5A5A5, 32'h0F0F0F0F, 1'b0, 5'd0, OP_AND);
        apply_and_check(32'hA5A5A5A5, 32'h0F0F0F0F, 1'b0, 5'd0, OP_OR);
        apply_and_check(32'hA5A5A5A5, 32'hFFFF0000, 1'b0, 5'd0, OP_XOR);

        
        apply_and_check(32'h0000FFFF, 32'd0, 1'b0, 5'd8, OP_SLL);
        apply_and_check(32'hFF000000, 32'd0, 1'b0, 5'd8, OP_SRL);
        apply_and_check(32'h80000000, 32'd0, 1'b0, 5'd4, OP_SRA);

        
        apply_and_check(32'h12345678, 32'd0, 1'b0, 5'd8, OP_ROTL);
        apply_and_check(32'h12345678, 32'd0, 1'b0, 5'd8, OP_ROTR);

       
        apply_and_check(32'hFFFFFFFF, 32'd1, 1'b0, 5'd0, OP_SLT);
        apply_and_check(32'd0, 32'd0, 1'b0, 5'd0, OP_ADD);

        for (idx = 0; idx < 200; idx = idx + 1) begin
            r = $random;
            if ((r % 11) == OP_SUB) begin
                
                apply_and_check($random, $random, 1'b0, r[4:0], OP_SUB); 
            end else begin
                
                apply_and_check($random, $random, $random & 1, r[4:0], r % 11);
            end
            #10;
        end

       
        $display("\n");
        $display("========================================");
        $display("SELF-CHECK COMPLETE");
        $display("========================================");
        $display("PASSED: %0d tests", passcount);
        $display("FAILED: %0d tests", failcount);
        $display("========================================");
        
        if (failcount != 0) begin
            $display("One or more tests FAILED.");
        end else begin
            $display("All tests PASSED!");
        end
        $display("========================================\n");

        $finish;
    end

endmodule
