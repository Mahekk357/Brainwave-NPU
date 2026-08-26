/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 4                                           */
/* 8-Lane Dot Product Module                       */
/***************************************************/

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

/******* Your code starts here *******/

//unpacking vec0
logic signed [IWIDTH-1:0] a0, a1, a2, a3, a4, a5, a6, a7; 
assign a0 = vec0[(1)*IWIDTH-1 -: IWIDTH]; // vec0[7:0]
assign a1 = vec0[(2)*IWIDTH-1 -: IWIDTH]; // vec0[15:8]
assign a2 = vec0[(3)*IWIDTH-1 -: IWIDTH]; // vec0[23:16]
assign a3 = vec0[(4)*IWIDTH-1 -: IWIDTH]; // vec0[31:24]
assign a4 = vec0[(5)*IWIDTH-1 -: IWIDTH]; // vec0[39:32]
assign a5 = vec0[(6)*IWIDTH-1 -: IWIDTH]; // vec0[47:40]
assign a6 = vec0[(7)*IWIDTH-1 -: IWIDTH]; // vec0[55:48]
assign a7 = vec0[(8)*IWIDTH-1 -: IWIDTH]; // vec0[63:56]

//unpacking vec1
logic signed [IWIDTH-1:0] b0, b1, b2, b3, b4, b5, b6, b7; 
assign b0 = vec1[(1)*IWIDTH-1 -: IWIDTH]; // vec1[7:0]
assign b1 = vec1[(2)*IWIDTH-1 -: IWIDTH]; // vec1[15:8]
assign b2 = vec1[(3)*IWIDTH-1 -: IWIDTH]; // vec1[23:16]
assign b3 = vec1[(4)*IWIDTH-1 -: IWIDTH]; // vec1[31:24]
assign b4 = vec1[(5)*IWIDTH-1 -: IWIDTH]; // vec1[39:32]
assign b5 = vec1[(6)*IWIDTH-1 -: IWIDTH]; // vec1[47:40]
assign b6 = vec1[(7)*IWIDTH-1 -: IWIDTH]; // vec1[55:48]
assign b7 = vec1[(8)*IWIDTH-1 -: IWIDTH]; // vec1[63:56]

// Stage 1: multiply, then register
logic signed [2*IWIDTH-1:0] p0, p1, p2, p3, p4, p5, p6, p7;

always_ff @(posedge clk) begin
        p0 <= a0 * b0;
        p1 <= a1 * b1;
        p2 <= a2 * b2;
        p3 <= a3 * b3;
        p4 <= a4 * b4;
        p5 <= a5 * b5;
        p6 <= a6 * b6;
        p7 <= a7 * b7;
end

// Stage 2: pairwise add, then register
logic signed [2*IWIDTH:0] s01, s23, s45, s67;
always_ff @(posedge clk) begin
        s01 <= p0 + p1; 
        s23 <= p2 + p3;
        s45 <= p4 + p5; 
        s67 <= p6 + p7;
end
 
// Stage 3: pairwise add again, then register
logic signed [2*IWIDTH+1:0] s0123, s4567;
always_ff @(posedge clk) begin
        s0123 <= s01 + s23; 
        s4567 <= s45 + s67;
end

// Stage 4: final add, then register
logic signed [2*IWIDTH+2:0] final_sum; 
always_ff @(posedge clk) begin
       final_sum <= s0123 + s4567;
end

logic ivalid_d1, ivalid_d2, ivalid_d3, ivalid_d4;
always_ff @(posedge clk) begin
  if (rst) begin
        ivalid_d1 <= 0;    
        ivalid_d2 <= 0; 
        ivalid_d3 <= 0; 
        ivalid_d4 <= 0; 
    end else begin 
        ivalid_d1 <= ivalid;    // shadows stage 1
        ivalid_d2 <= ivalid_d1; // shadows stage 2
        ivalid_d3 <= ivalid_d2; // shadows stage 3
        ivalid_d4 <= ivalid_d3; // shadows stage 4  
    end
end

assign ovalid = ivalid_d4; 
assign result = final_sum; 

/******* Your code ends here ********/

endmodule
