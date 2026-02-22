module serializer_10b (
    input wire clk,   // Link clock
    input wire rst_n,
    input wire [9:0] data_in,    // From FIFO d_out
    input wire fifo_empty,
    output reg rd_en,      // To FIFO rd_en
    output wire serial_out
);

    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;

    localparam COMMA_K28_5 = 10'b1100000101;

    assign serial_out = shift_reg[0]; // Sending LSB first

    // Serializer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= COMMA_K28_5;
            bit_cnt <= 4'd0;
            rd_en <= 1'b0;
        end else begin
            if (bit_cnt == 4'd8) begin
                rd_en <= !fifo_empty;
                bit_cnt <= bit_cnt + 1;
                shift_reg <= {1'b0, shift_reg[9:1]};
            end else if (bit_cnt == 4'd9) begin
                bit_cnt <= 4'd0;
                rd_en <= 1'd0;
                if (!fifo_empty) begin
                    shift_reg <= data_in;
                end else begin
                    // fifo is empty, load comma pattern (K28.5) to keep link busy
                    shift_reg <= COMMA_K28_5;
                end
            end else begin
                shift_reg <= {1'b0, shift_reg[9:1]}; // Shift right
                bit_cnt <= bit_cnt + 1;
                rd_en <= 1'd0;
            end
        end
    end

endmodule

