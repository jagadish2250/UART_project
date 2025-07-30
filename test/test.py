# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_uart_tx_rx(dut):
    """Test UART TX and RX functionality via Tiny Tapeout pins"""

    # Setup 10ns clock (100 MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # --- Configuration (set bits in ui_in) ---
    # Assuming the following bit mapping:
    # ui_in[0] = tr_en (TX enable)
    # ui_in[1] = rx_en (RX enable)
    # ui_in[2] = clk_sel (0 = 16x, 1 = full rate)
    # ui_in[3] = rd_en (Read enable)
    # You can customize as per your design mapping

    dut.ui_in.value = 0b00000011  # tr_en=1, rx_en=1

    # --- Send data to transmitter (through uio_in[7:1]) ---
    data_to_transmit = 0xA5  # 10100101
    dut.uio_in.value = (data_to_transmit << 1)  # shift left, bit0 is rx_data_in

    await Timer(20, units='ns')
    print(f"TX sending byte: 0x{data_to_transmit:02X}")

    # Wait for UART to process transmission
    for _ in range(2000):
        await RisingEdge(dut.clk)

    # Simulate received data (via uio_in[0] = rx_data_in)
    for i in range(8):
        bit = (data_to_transmit >> i) & 0x1
        dut.uio_in.value = (dut.uio_in.value & 0xFE) | bit  # replace LSB
        await Timer(104, units='us')  # Simulated bit time (depends on baud)

    # Enable read to receive output from RX
    dut.ui_in.value = 0b00001011  # set rd_en = 1
    await Timer(200, units='us')

    # Capture output
    received = dut.uo_out.value.integer
    print(f"RX received byte: 0x{received:02X}")

    assert received == data_to_transmit, f"Mismatch! Sent 0x{data_to_transmit:02X}, Received 0x{received:02X}"

    # End of test
    await Timer(200, units='ns')
