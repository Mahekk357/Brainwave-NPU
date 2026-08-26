/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 4                                           */
/* Matrix Vector Multiplication (MVM) Module       */
/***************************************************/

module mvm # (
    parameter IWIDTH = 8, //bitwidth of a single input element 
    parameter OWIDTH = 32, //bitwidth of single output element 
    parameter MEM_DATAW = IWIDTH * 8, // define size of word
    parameter VEC_MEM_DEPTH = 256,
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH = 512,
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES = 32,
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
)(
    input clk,
    input rst,
    //write interfaces to vec and matrix mem
    input [MEM_DATAW-1:0] i_vec_wdata, //write word by word 
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
   
    input i_start, // start computation 
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words, // # of words in vector * 8 = # of elements in the vector & # columns in matrix
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane, //# of rows per o_lane * NUM_OLANES (8) = # of rows in the matrix 
    output o_busy, //computing an MVM 
    
    //outputs of mvm
    output [OWIDTH*NUM_OLANES-1:0] o_result, 
    output o_valid
);

/******* Your code starts here *******/
logic [VEC_ADDRW-1:0] vec_raddr; //output from ctrl fsm 
logic [MEM_DATAW-1:0] vec_rdata; // output of vector mem
mem #(
    .DATAW (MEM_DATAW),
    .DEPTH (VEC_MEM_DEPTH)
) vector_mem (
    .clk (clk),
    .wdata (i_vec_wdata),
    .waddr (i_vec_waddr),
    .wen (i_vec_wen),
    .raddr (vec_raddr), 
    .rdata (vec_rdata)
);

logic [MAT_ADDRW-1:0]  mat_raddr; //output from ctrl fsm 
logic [MEM_DATAW-1:0]  mat_rdata  [NUM_OLANES-1:0]; //output of matrix mem
logic [OWIDTH-1:0]     dot_result [NUM_OLANES-1:0]; // output of dot8 module
logic                  dot_ovalid [NUM_OLANES-1:0]; // output of dot8 module
logic                  dot_ivalid; //from ctrl fsm 
logic [OWIDTH-1:0]     accum_result [NUM_OLANES-1:0]; // output of accum module
logic                  accum_ovalid [NUM_OLANES-1:0]; // output of accum module
logic                  accum_first; //from ctrl fsm 
logic                  accum_last; //from ctrl fsm 

//pipeline fanout of vec_rdata for dot8 modules
logic [MEM_DATAW-1:0] vec_rdata_reg;

//pipeline mat_rdata to match vector operand 
logic [MEM_DATAW-1:0] mat_rdata_reg [NUM_OLANES-1:0];

// NEW: second pipeline stage
logic [MEM_DATAW-1:0] vec_rdata_reg2;
logic [MEM_DATAW-1:0] mat_rdata_reg2 [NUM_OLANES-1:0];

always_ff @(posedge clk) begin
    vec_rdata_reg  <= vec_rdata;     // ADD THIS: stage 1, was missing
    vec_rdata_reg2 <= vec_rdata_reg; // stage 2, already had this
end

genvar i; 
generate 
    for (i=0; i < NUM_OLANES; i++) begin : lane 
    
     //add delay to matrix operands too 
always_ff @(posedge clk) begin
    mat_rdata_reg[i]  <= mat_rdata[i];
    mat_rdata_reg2[i] <= mat_rdata_reg[i];
end
    
    mem #(
        .DATAW (MEM_DATAW),
        .DEPTH (MAT_MEM_DEPTH)
    ) matrix_mem (
        .clk (clk),
        .wdata (i_mat_wdata),
        .waddr (i_mat_waddr),
        .wen (i_mat_wen[i]),
        .raddr (mat_raddr), 
        .rdata (mat_rdata[i])
    );

    dot8 #(
        .IWIDTH (IWIDTH),
        .OWIDTH (OWIDTH)
    ) dot_product (
        .clk (clk),
        .rst (rst),
        .vec0 (vec_rdata_reg2),
        .vec1 (mat_rdata_reg2 [i]),
        .ivalid (dot_ivalid),
        .result (dot_result[i]),
        .ovalid (dot_ovalid[i])
    );
    
    
     accum #(
        .DATAW (OWIDTH), 
        .ACCUMW (OWIDTH)
    ) accumulator (
        .clk (clk),
        .rst (rst),
        .data (dot_result[i]),
        .ivalid (dot_ovalid[i]),
        .first (accum_first),
        .last (accum_last),
        .result (accum_result[i]),
        .ovalid (accum_ovalid[i])
    );

end
endgenerate


logic ctrl_ovalid;       // output from ctrl.ovalid 
logic ctrl_accum_first;  // output from ctrl.accum_first
logic ctrl_accum_last;   // output from ctrl.accum_last
logic ctrl_busy;         // output from ctrl.busy

   ctrl #(
        .VEC_ADDRW (VEC_ADDRW), 
        .MAT_ADDRW (MAT_ADDRW),
        .VEC_SIZEW (VEC_SIZEW),
        .MAT_SIZEW (MAT_SIZEW)
   ) control_fsm (
        .clk (clk),
        .rst (rst),
        .start (i_start),
        .vec_start_addr (i_vec_start_addr),
        .vec_num_words (i_vec_num_words),
        .mat_start_addr(i_mat_start_addr), 
        .mat_num_rows_per_olane(i_mat_num_rows_per_olane),
        .vec_raddr(vec_raddr),
        .mat_raddr(mat_raddr), 
        .accum_first (ctrl_accum_first),
        .accum_last (ctrl_accum_last),
        .ovalid (ctrl_ovalid),
        .busy(ctrl_busy)
    );

logic dot_ivalid_d1, dot_ivalid_d2;
always_ff @(posedge clk) begin
    if (rst) begin
        dot_ivalid_d1 <= 0;
        dot_ivalid_d2 <= 0;
        dot_ivalid    <= 0;
    end else begin
        dot_ivalid_d1 <= ctrl_ovalid;
        dot_ivalid_d2 <= dot_ivalid_d1;
        dot_ivalid    <= dot_ivalid_d2;
    end
end

logic first_d1, first_d2, first_d3, first_d4, first_d5, first_d6; 
logic last_d1, last_d2, last_d3, last_d4, last_d5, last_d6; 

always_ff @(posedge clk) begin
      if (rst) begin
          first_d1 <= 0;   
          first_d2 <= 0;   
          first_d3 <= 0;   
          first_d4 <= 0;   
          first_d5 <= 0;
          first_d6 <= 0;
          accum_first <= 0; 
          last_d1 <= 0;   
          last_d2 <= 0;   
          last_d3 <= 0;   
          last_d4 <= 0;   
          last_d5 <= 0; 
          last_d6 <= 0;
          accum_last <= 0; 

      end else begin 
          first_d1 <= ctrl_accum_first;  //1 cycle delay
          first_d2 <= first_d1;          //2
          first_d3 <= first_d2;          //3
          first_d4 <= first_d3;          //4
          first_d5 <= first_d4;          //5
          first_d6 <= first_d5;          //6
          accum_first <= first_d6;       //7
          
          last_d1 <= ctrl_accum_last;    //1 cycle delay
          last_d2 <= last_d1;            //2
          last_d3 <= last_d2;            //3
          last_d4 <= last_d3;            //4
          last_d5 <= last_d4;            //5
          last_d6 <= last_d5;            //6
          accum_last <= last_d6;         //7
      end 
end 

genvar j;
generate
    for (j = 0; j < NUM_OLANES; j = j + 1) begin : pack
        assign o_result[(j+1)*OWIDTH-1 -: OWIDTH] = accum_result[j];
    end
endgenerate

assign o_valid = accum_ovalid[0];
assign o_busy = ctrl_busy; 


/******* Your code ends here ********/

endmodule
