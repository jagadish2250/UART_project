# Tiny Tapeout UART Module Documentation

## Project Overview

This project implements a full-featured UART (Universal Asynchronous Receiver-Transmitter) controller designed specifically for the Tiny Tapeout platform. The UART enables bidirectional serial communication with configurable parameters and includes interrupt generation capabilities.

## How it works

The UART module (tt_um_uart) serves as a wrapper around a more comprehensive uart_top module, mapping its functionality to Tiny Tapeout's standardized 8-bit I/O interface.

### Key Components

**Input Mapping (ui_in[7:0]):**
- ui_in[0]: tr_en - Transmitter enable
- ui_in[1]: mode_osl - Mode/operational select 
- ui_in[2]: clk_sel - Clock selection (0 = 16x oversampling, 1 = full rate)
- ui_in[3]: tx_data_w_en - TX data write enable
- ui_in[4]: tr_data_load - Transmit data load signal
- ui_in[5]: rx_data_read_en - RX data read enable

**Bidirectional I/O (uio_in[7:0] / uio_out[7:0]):**
- uio_in[7:1]: tr_fifo_data_w - 7-bit transmit data input
- uio_in[0]: rx_data_in - Serial receive data input
- uio_out[0]: tx_line - Serial transmit data output
- uio_out[1]: tx_i_int - TX input interrupt
- uio_out[2]: rx_i_int - RX input interrupt  
- uio_out[3]: tx_o_int - TX output interrupt
- uio_out[4]: rx_o_int - RX output interrupt
- uio_out[5]: tr_busy - Transmitter busy flag
- uio_out[7:6]: Reserved (tied to 0)

**Output (uo_out[7:0]):**
- uo_out[7:0]: rx_data - 8-bit received data

### Operational Flow

1. *Initialization*: Reset the module using rst_n (active low)
2. *Configuration*: Set operational parameters via ui_in control bits
3. *Transmission*: 
   - Load data into uio_in[7:1]
   - Enable transmission with ui_in[3] (tx_data_w_en)
   - Monitor uio_out[5] (tr_busy) for completion
4. *Reception*:
   - Serial data arrives on uio_in[0]
   - Enable reading with ui_in[5] (rx_data_read_en)
   - Read received data from uo_out[7:0]
5. *Interrupt Handling*: Monitor interrupt flags on uio_out[4:1]

### Baud Rate Configuration

The module uses a fixed baud rate configuration with dlh_dll = 16'h0020 (32 decimal), which determines the communication speed based on the input clock frequency.

## How to test

### Prerequisites
- Cocotb testbench environment
- Icarus Verilog or compatible simulator
- Python 3.x with cocotb installed

### Running the Test

1. *Setup the environment*:
   bash
   pip install cocotb
   

2. *Execute the test*:
   bash
   make
   

### Test Procedure

The provided test (test.py) performs the following sequence:

1. *Clock and Reset Setup*:
   - Generates 100 MHz clock (10ns period)
   - Applies reset sequence

2. *Configuration*:
   - Enables transmitter and receiver: ui_in = 0b00000011
   - Sets up operational mode

3. *Loopback Test*:
   - Transmits test byte 0xA5 via uio_in[7:1]
   - Simulates serial reception on uio_in[0]
   - Verifies received data matches transmitted data

4. *Verification*:
   - Compares transmitted vs received data
   - Reports success/failure with detailed output

### Expected Results

The test should output:

TX sending byte: 0xA5
RX received byte: 0xA5


### Waveform Analysis

The testbench generates tb.vcd for waveform viewing. Key signals to monitor:
- Clock and reset behavior
- Control signal transitions
- TX/RX data flow
- Interrupt flag states
- Busy signal timing

## External hardware

### Required Connections

*For basic UART communication:*
- *TX Line*: Connect uio_out[0] to receiving device's RX input
- *RX Line*: Connect external transmitter to uio_in[0]
- *Ground*: Common ground reference between devices

### Recommended External Hardware

1. *USB-to-Serial Converter*:
   - FTDI FT232R/FT234X based modules
   - CP2102/CP2104 based modules
   - For PC connectivity and debugging

2. *RS-232 Level Shifter* (if needed):
   - MAX3232 or similar
   - Required for true RS-232 voltage levels (±12V)
   - Most modern devices use 3.3V/5V TTL levels

3. *Microcontroller Interface*:
   - Arduino boards (3.3V/5V compatible)
   - Raspberry Pi GPIO pins
   - ESP32/ESP8266 modules

4. *Test Equipment*:
   - Logic analyzer for signal debugging
   - Oscilloscope for timing analysis
   - Breadboard and jumper wires for connections

### Connection Example


Tiny Tapeout UART    ←→    External Device
─────────────────          ────────────────
uio_out[0] (TX)     ──→    RX Input
uio_in[0]  (RX)     ←──    TX Output
GND                 ──→    GND


### Pin Configuration Summary

| Pin | Direction | Function | External Connection |
|-----|-----------|----------|-------------------|
| uio_out[0] | Output | TX Data | → External RX |
| uio_in[0] | Input | RX Data | ← External TX |
| uio_out[5:1] | Output | Status/Interrupts | → Status LEDs (optional) |
| ui_in[5:0] | Input | Control | ← Control switches/MCU |

### Notes

- Ensure voltage level compatibility (3.3V TTL for Tiny Tapeout)
- Add pull-up resistors on communication lines if experiencing reliability issues
- Consider adding decoupling capacitors for stable operation
- The fixed baud rate configuration may require adjustment based on your target communication speed
