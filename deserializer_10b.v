module deserializer_10b (
    input wire clk,  // Link clock
    input wire rst_n,
    input wire serial_in,
    input wire fifo_full,
    output reg [9:0] data_out,
    output reg wr_en,
    output reg comma_det,
    output reg link_lock
);

    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;
    reg [3:0] lock_count; // ensure stable comma detection before locking

    localparam COMMA_P = 10'b1100000101; 
    localparam COMMA_N = 10'b0011111010;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 10'b0;
            bit_cnt <= 4'd0;
            data_out <= 10'b0;
            wr_en <= 1'b0;
            comma_det <= 1'b0;
            link_lock <= 1'b0;
            lock_count <= 4'd0;
        end else begin
            shift_reg <= {serial_in, shift_reg[9:1]}; // Shift in new bit
            comma_det <= 1'b0;

            if ({serial_in, shift_reg[9:1]} == COMMA_P || {serial_in, shift_reg[9:1]} == COMMA_N) begin
                bit_cnt <= 4'd0; // Reset bit count on comma detection
                comma_det <= 1'b1;

                // Link Training: If we see 4 commas in a row, consider the link "Locked"
                if (lock_count < 4'd4) lock_count <= lock_count + 1'b1;
                else link_lock <= 1'b1;
            end
                
            if (bit_cnt == 4'd9) begin
                bit_cnt <= 4'd0;
                // Only write to FIFO if it's not full and we have achieved link lock
                if (!fifo_full && link_lock) begin
                    data_out <= {serial_in, shift_reg[9:1]}; // Output full 10-bit word
                    wr_en <= 1'b1;
                end
            end else begin
                bit_cnt <= bit_cnt + 1;
                wr_en <= 1'b0;
            end
        end
    end

endmodule