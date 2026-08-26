/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 4                                           */
/* MVM Control FSM                                 */
/***************************************************/

module ctrl # (
    parameter VEC_ADDRW = 8,
    parameter MAT_ADDRW = 9,
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
    
)(
    input  clk,
    input  rst,
    input  start,
    input  [VEC_ADDRW-1:0] vec_start_addr,
    input  [VEC_SIZEW-1:0] vec_num_words,
    input  [MAT_ADDRW-1:0] mat_start_addr,
    input  [MAT_SIZEW-1:0] mat_num_rows_per_olane,


    output [VEC_ADDRW-1:0] vec_raddr,
    output [MAT_ADDRW-1:0] mat_raddr,
    output accum_first,
    output accum_last,
    output ovalid,
    output busy
);

/******* Your code starts here *******/

//registers for inputs
logic [VEC_ADDRW-1:0] reg_vec_start_addr;
logic [VEC_SIZEW-1:0] reg_vec_num_words;
logic [MAT_ADDRW-1:0] reg_mat_start_addr;
logic [MAT_SIZEW-1:0] reg_mat_num_rows_per_olane;

//registering inputs 
always_ff @(posedge clk) begin
    if (rst) begin
        reg_vec_start_addr <= 0;
        reg_vec_num_words <= 0;
        reg_mat_start_addr <= 0;
        reg_mat_num_rows_per_olane <= 0;
    end else if (state == IDLE && start) begin
        reg_vec_start_addr <= vec_start_addr;
        reg_vec_num_words <= vec_num_words;
        reg_mat_start_addr <= mat_start_addr;
        reg_mat_num_rows_per_olane <= mat_num_rows_per_olane;
    end
end


typedef enum logic {
    IDLE,
    COMPUTE
} state_t;

state_t state, next_state;

//state decoder
always_ff @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

logic [MAT_SIZEW-1:0] row_cnt;


always_comb begin
    case (state)
        IDLE: begin
            if (start) begin
                next_state = COMPUTE;
            end else begin
                next_state = IDLE;
            end
        end
        COMPUTE: begin
            if (row_cnt == reg_mat_num_rows_per_olane - 1 && accum_last) begin
                next_state = IDLE;
            end else begin
                next_state = COMPUTE;
            end
        end
        default: next_state = IDLE;
    endcase
end


//word by word of row counter loop 
logic [VEC_SIZEW-1:0] word_cnt;

always_ff @(posedge clk) begin
    if (rst) begin
        word_cnt <= 0;
    end else if (state == COMPUTE) begin
        if (word_cnt == reg_vec_num_words - 1) begin
            word_cnt <= 0;
        end else begin
            word_cnt <= word_cnt + 1;
        end
    end else begin
        word_cnt <= 0;
    end
end

assign vec_raddr = reg_vec_start_addr + word_cnt;  
assign accum_first = (word_cnt == 0); //first word of row 
assign accum_last = (word_cnt == reg_vec_num_words - 1); //last word of row 

//matrix mem reading counter loop
logic [MAT_ADDRW-1:0] mat_cnt;

always_ff @(posedge clk) begin
    if (rst) begin
        mat_cnt <= 0;
    end else if (state == COMPUTE) begin
        mat_cnt <= mat_cnt + 1;
    end else begin
        mat_cnt <= 0;
    end
end

assign mat_raddr = reg_mat_start_addr + mat_cnt;

//whole mvm computation loop
always_ff @(posedge clk) begin
    if (rst) begin
        row_cnt <= 0;
    end else if (state == COMPUTE && accum_last) begin
        if (row_cnt == reg_mat_num_rows_per_olane - 1) begin
            row_cnt <= 0;
        end else begin
            row_cnt <= row_cnt + 1;
        end
    end else if (state == COMPUTE && !accum_last) begin
        // do nothing - hold current value
    end else begin
        row_cnt <= 0;   // truly idle
    end
end

assign busy = (state == COMPUTE) || (state == IDLE && start);
assign ovalid = (state == COMPUTE);
/******* Your code ends here ********/

endmodule
