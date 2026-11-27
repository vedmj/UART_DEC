# UART-Controlled FPGA Calculator (Basys 3, Verilog)

## Part 1 - UART from scratch

**Serial vs parallel.** Parallel = one wire per bit (fast, but skew, pin count, cabling). Serial = bits one after another on one wire.
**Asynchronous** = no shared clock wire; both ends agree on a *baud rate* beforehand and the receiver re-synchronises on every frame's start bit.
**UART** is the hardware block (shift register + timing) that makes/consumes such frames. Two wires cross over: FPGA TX -> PC RX, PC TX -> FPGA RX. Independent wires = **full duplex**.


### 8N1 frame (LSB first)
```
idle  ___     _____ _____ _____ _____ _____ _____ _____ _____ _____ _______
 1       \___/ b0  X b1  X b2  X b3  X b4  X b5  X b6  X b7  X STOP/ idle...
          START                                              (=1)
          0
          |<------------- 10 bit-times = 86.8 us @115200 ------------->|
```
Example 0x41 = 0100_0001 -> wire order: `0` `1 0 0 0 0 0 1 0` `1` (start, b0..b7, stop). Back-to-back frames: next start bit may follow the stop bit immediately; the receiver must therefore sample the stop bit *mid-bit* and be ready at once.
Optional parity would add one bit between b7 and stop (not used).

### Baud generation from 100 MHz
| Baud | Ideal divisor | Integer | Error |
|---|---|---|---|
| 9600 | 10416.67 | 10417 | +0.003 % |
| 19200 | 5208.33 | 5208 | -0.006 % |
| 38400 | 2604.17 | 2604 | -0.006 % |
| 57600 | 1736.11 | 1736 | -0.006 % |
| 115200 | 868.06 | 868 | -0.006 % |

At 16x oversampling the divisor for 115200 is 54.25 -> an integer divider (54) is 0.46 % off. Over 10 bits a receiver tolerates roughly +-3-4 % total, so even that works, but this design uses a **phase accumulator**: `acc += INC` every clock, tick = carry-out, `INC = 16*BAUD*2^24/100e6`. That is fractional division with error ~1e-5, and changing `BAUD` is a one-parameter edit. Measured in simulation: 115200 baud over 10 ms. No derived clocks anywhere - only 1-clock-wide **enables** on the 100 MHz clock (`tick_16x` for RX, `tick_1x` for TX).

### Receiver ideas
* **Metastability**: the RX pin is asynchronous to the FPGA clock, so a flip-flop sampling it near an edge can hang between 0 and 1. Two FFs in series (`rx_synchronizer`) give the first one a full clock to settle.
* **Mid-bit sampling**: edges are where the signal is changing and where clock mismatch hurts. Sampling at the centre gives half a bit (+-50 %) of timing margin. After detecting the falling edge the RX counts 8 ticks (centre of start bit; re-checks it is still 0 -> rejects glitches), then 16 ticks per bit.

---
## Part 2 - Architecture

```
                      +-------------------- baud_generator ---------------------+
                      | tick_16x                                   tick_1x     |
RsRx --> [uart_rx] ---+--> rx_data/rx_valid --> [packet_parser] --(pending slot: cmd_valid/take)
         (2FF sync)                                      |
                                                  [command_controller] <--> [alu] (comb.)
                                                  latches A,B,op; result/flags/status regs
                                                         | resp_start / resp_ready
RsTx <-- [uart_tx] <-- tx_start/tx_data/done --- [response_generator]  (snapshots result)
                                        result/flags/status --> LEDs, [seven_segment]
```
| File | Depends on | Role |
|---|---|---|
| `baud_generator.v` | - | tick_16x, tick_1x |
| `rx_synchronizer.v` | - | 2-FF synchronizer |
| `uart_rx.v` | rx_synchronizer | serial -> byte |
| `uart_tx.v` | - | byte -> serial |
| `packet_parser.v` | - | 5-byte request FSM + one-entry pending slot + timeout |
| `alu.v` | - | combinational ALU, 16-bit result, 8 flags |
| `command_controller.v` | - | IDLE/EXEC/SEND FSM + result/flags/status/opcode registers |
| `response_generator.v` | - | 6-byte response sequencer |
| `seven_segment.v` | - | hex multiplexer |
| `top_uart_calculator.v` | all | integration, reset sync, LEDs, display select |

### Handshakes (no races, no double sends)
* **parser -> controller**: `cmd_valid` (level, held) / `cmd_take` (= controller IDLE & cmd_valid). Slot freed on the next edge. New event while full -> `overrun` pulse, new event dropped, old kept.
* **controller -> response gen**: `resp_start = (SEND & resp_ready)`; the FSM leaves SEND on the same edge, so exactly one start per command (testbench counts pulses).
* **response gen -> TX**: `tx_start` one-cycle pulse when `!tx_busy`; next byte only after `tx_done`. The generator **snapshots** status/result/flags at start so later commands cannot corrupt an in-flight response.
* **Operand stability**: operands are loaded only in IDLE; EXEC captures the ALU output one cycle later; nothing changes between.
* **Full duplex**: RX path and TX path share only `rst` and the baud generator. A request arriving during a response is parsed immediately; the controller then waits in SEND until the generator is free. Buffering = the parser's one pending slot + the controller's operand registers (2 commands in flight). Sustained streaming of > ~6 back-to-back requests (a response, 521 us, is slower than a request, 434 us) would overrun and be flagged on the decimal point; a request/response host never gets near that.

---
## Part 3 - Protocol 

UART only moves bytes. Opcodes, headers and checksums are **our** convention on top of it.

Request `A5 | OP | A | B | OP^A^B`  Response `5A | STATUS | RES_H | RES_L | FLAGS | STATUS^RES_H^RES_L^FLAGS`

| Opcode | Op | Result (16-bit) |
|---|---|---|
| 01 | A+B | 9-bit sum, zero-extended |
| 02 | A-B | (A-B) mod 256, zero-extended; borrow flag tells A<B |
| 03 | A*B | full 16-bit product |
| 04/05/06 | AND/OR/XOR | zero-extended |
| 07 | NOT A | `00 ~A` (B ignored) |
| 08/09 | A<<B[3:0] / A>>B[3:0] | 16-bit, so `FF<<4 = 0FF0` is not truncated |
| 0A | compare | 0000 equal, 0001 A>B, 0002 A<B |

Status: `00` OK, `01` invalid opcode, `02` checksum error, `03` incomplete packet (50 ms without the next byte).
Resync: any failure returns the parser to "hunt for 0xA5".

### Flags (response byte 4) - only these are meaningful per operation
| Bit | Flag | ADD | SUB | MUL | AND/OR/XOR/NOT | SHL | SHR | CMP |
|---|---|---|---|---|---|---|---|---|
| 0 | Z zero (result==0) | y | y | y | y | y | y | y |
| 1 | C carry | carry-out | - | product>255 | - | bits lost above bit 15 | last bit shifted out | - |
| 2 | B borrow | - | A<B unsigned | - | - | - | - | - |
| 3 | N negative (bit 7 of result, signed view) | y | y | - | - | - | - | - |
| 4 | V signed overflow | y | y | - | - | - | - | - |
| 5 | EQ | - | - | - | - | - | - | y |
| 6 | GT | - | - | - | - | - | - | y |
| 7 | LT | - | - | - | - | - | - | y |

Unsigned vs signed: operands are treated as **unsigned**. C/B are the unsigned flags; N/V are what an 8-bit two's-complement reading would give (127+1 sets V; 5-10 sets B and N). The 8-bit subtract result is modular, so the host decides: if B=1, true value is `result - 256`. Compare and multiply are unsigned only.

---
## Part 4 - FSMs

**uart_tx**: `IDLE -(tx_start)-> START -(tick)-> DATA(8 ticks, shift LSB out) -(tick)-> STOP -(tick)-> IDLE`. The start bit is launched *on a baud tick*, so every bit is exactly one baud period. `busy` = high from accept to end of stop; `done` = 1-clock pulse at the end. Request-to-start latency 0-1 bit; consecutive bytes therefore have a small idle gap (legal for UART).

**uart_rx**: `IDLE -(falling edge)-> START_CHECK -(8 ticks, still 0)-> DATA_RECEIVE(8x16 ticks, shift right) -> STOP_CHECK(16 ticks) -> COMPLETE -> IDLE`. COMPLETE pulses `rx_valid` (stop=1) or `framing_error` (stop=0). After a framing error the line must go high again before another start is accepted.

**packet_parser**: `HDR -(A5)-> OP -> A -> B -> CHK -> HDR`; at CHK posts *command* or *checksum-error*; timeout posts *incomplete*.

**command_controller**: `IDLE -(cmd_valid)-> EXEC -> SEND -(resp_ready)-> IDLE`.

---
## Part 5 - Verification

| Testbench | What is proven |
|---|---|
| tb_baud_generator | 1152 baud ticks / 10 ms (=115200), 16x count, 1-clk pulses |
| tb_uart_tx | 00, FF, 55, AA, 41 sampled at mid-bit, LSB first, stop=1, frame = 10 bit-times, busy/done, start-while-busy ignored, back-to-back, reset mid-frame |
| tb_uart_rx | same patterns, back-to-back DE AD BE EF, framing error, 1/8-bit glitch, break, +-2.5 % clock error, reset mid-frame |
| tb_alu | 38 vectors: 10+20, 255+1, 20-10, 5-10, 15x15, 255x255, AA&55, AA^55, 1<<3, flag semantics, invalid ops |
| tb_packet_parser | valid, bad checksum, garbage/resync, timeout, no timeout when idle, unknown opcode, overrun, reset mid-packet |
| tb_command_controller | 9 mixed commands issued back-to-back; in-order bytes, no overwrite, exactly one TX start per command |
| tb_uart_calculator | all ops incl. LED and seven-segment decode and switch views; invalid opcodes; bad checksum; incomplete; framing error; 4 requests while responses are transmitting; reset during RX; reset during TX; 50 consecutive commands without reset |


## Part 7 - Outputs
* LEDs: `led[7:0]` = result low byte, `led[15:8]` = flags `{LT,GT,EQ,V,N,B,C,Z}`.
* 7-seg: `sw[1:0]`: 00 result, 01 `{status,flags}`, 10 `{A,B}` of last command, 11 opcode. Decimal point lit = an overrun happened (cleared by reset).
* 7-seg theory: Basys 3 digits are **common anode** and driven active-low: a segment lights when its cathode is 0, a digit is selected when its anode is 0. Only one digit is on at a time; cycling at 381 Hz (each digit 0.66 ms) looks continuous.
* `btnC` = reset



