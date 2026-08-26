/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 4                                           */
/* Accumulator Module                              */
/***************************************************/

module accum # (
    parameter DATAW = 32,
    parameter ACCUMW = 32
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data,
    input  ivalid,
    input  first,
    input  last,
    output signed [ACCUMW-1:0] result,
    output ovalid
);

/******* Your code starts here *******/
logic signed [ACCUMW-1:0] accum_reg; 
always_ff @(posedge clk) begin
    if (ivalid) begin
        if (first) begin
            accum_reg <= data; 
        end else begin
            accum_reg <= accum_reg + data; 
        end
    end
    // what happens here if ivalid=0? does accum_reg need an else at the outer level?
end

logic ivalid_d1;
always_ff @(posedge clk) begin
    if (rst) begin
        ivalid_d1 <= 0;    
    end else begin 
        // one line, runs every cycle regardless of ivalid
         ivalid_d1 <= ivalid && last; 
    end 
end

assign ovalid = ivalid_d1; 
assign result = accum_reg; 

/******* Your code ends here ********/

endmodule
