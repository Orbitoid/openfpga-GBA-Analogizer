// SNES controller reader for the Analogizer SNAC port (configuration A).
//
// SNES-only cut of RndMnkIII's serlatch_game_controller (MIT), keeping the
// same bus waveform: ~100 kHz strobe, latch held high for two strobes, clock
// low during latch, then 16 clock pulses with data sampled on each falling
// edge. One poll takes 36 strobes (~360 us, ~2.8 kHz poll rate).
//
//   strobe : 0  1  2  3  4  5  6 ... 32 33 34 35
//   LATCH  : _/~~~~~\_____________________________
//   CLK    : ________/~~\__/~~\__ ... /~~\________
//   sample :       b0    b1    b2 ... b15
//
// SNES serial order (data line low = pressed):
//   0 B, 1 Y, 2 Select, 3 Start, 4 Up, 5 Down, 6 Left, 7 Right,
//   8 A, 9 X, 10 L, 11 R, 12-15 ID (line high on a standard pad)
//
// The ID bits double as a presence check. With nothing plugged in the data
// line does not hold high for bits 12-15, so the poll is dropped and no
// buttons are reported (instead of "everything pressed").
//
// btn_state uses the Pocket cont*_key layout, active high:
//   [0] up [1] down [2] left [3] right [4] A [5] B [6] X [7] Y
//   [8] L  [9] R    [14] select [15] start

`default_nettype none
`timescale 1ns / 1ps

module snac_snes #(
    parameter MASTER_CLK_FREQ = 8_388_608
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_ena,
    output reg  [15:0] btn_state,
    // SNAC pins
    output reg         o_clk,
    output reg         o_lat,
    input  wire        i_dat
);

localparam integer STB_DIV = MASTER_CLK_FREQ / 100_000;

reg [$clog2(STB_DIV)-1:0] div_cnt;
reg [5:0]  step;
reg [15:0] shift;
reg [1:0]  dat_sync;

wire stb = (div_cnt == STB_DIV - 1);

always @(posedge i_clk) begin
    dat_sync <= {dat_sync[0], i_dat};

    if (i_rst || !i_ena) begin
        div_cnt   <= 0;
        step      <= 6'd0;
        o_clk     <= 1'b0;
        o_lat     <= 1'b0;
        btn_state <= 16'h0000;
    end else begin
        div_cnt <= stb ? 1'b0 : div_cnt + 1'b1;

        if (stb) begin
            step  <= (step == 6'd35) ? 6'd0 : step + 6'd1;
            o_lat <= (step <= 6'd1);
            o_clk <= (step >= 6'd3 && step <= 6'd33) ? step[0] : 1'b0;

            // Even steps 2..32 sample bits 0..15 (bit = step/2 - 1).
            if (!step[0] && step >= 6'd2 && step <= 6'd32)
                shift[step[5:1] - 5'd1] <= dat_sync[1];

            if (step == 6'd34) begin
                if (&shift[15:12])
                    btn_state <= ~{shift[3], shift[2], 4'b1111, shift[11], shift[10],
                                   shift[1], shift[9], shift[0], shift[8],
                                   shift[7], shift[6], shift[5], shift[4]};
                else
                    btn_state <= 16'h0000;
            end
        end
    end
end

endmodule
