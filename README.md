# SPI-Multi-Slave-Verification
SystemVerilog-based verification of a configurable SPI Master communicating with multiple SPI Slaves using a self-checking testbench and SystemVerilog Assertions (SVA).

# SPI Multi-Slave Verification using SystemVerilog

## Overview

This project implements and verifies a configurable SPI (Serial Peripheral Interface) Master communicating with multiple SPI Slaves using SystemVerilog. The SPI Master supports dynamic slave selection, all four standard SPI modes through configurable Clock Polarity (CPOL) and Clock Phase (CPHA), and programmable clock division.

A comprehensive self-checking verification environment is developed using behavioral SPI slave models, automatic result checking, and SystemVerilog Assertions (SVA) to validate correct communication with multiple slave devices under different operating conditions.

---

## Features

### SPI Master

- Configurable data width (default: 8 bits)
- Supports multiple SPI Slaves
- Dynamic slave selection using Slave Select (SS)
- Supports all four SPI modes
  - Mode 0 (CPOL=0, CPHA=0)
  - Mode 1 (CPOL=0, CPHA=1)
  - Mode 2 (CPOL=1, CPHA=0)
  - Mode 3 (CPOL=1, CPHA=1)
- Programmable SPI clock divider
  - System Clock ÷2
  - System Clock ÷4
  - System Clock ÷8
  - System Clock ÷16
- Finite State Machine (FSM) based implementation
- Registered SPI clock generation
- Full-duplex SPI communication
- Configurable transmit and receive data paths

---

## Verification Features

- Self-checking testbench
- Behavioral SPI Slave models
- Automatic PASS/FAIL reporting
- SystemVerilog Assertions (SVA)
- Scoreboard-based result checking
- Functional verification of all SPI modes
- Verification across multiple slave devices
- Multiple clock divider verification
- Timeout detection
- Bidirectional data integrity checking

---

## Project Structure

```
SPI-Multi-Slave-Verification
│
├── spi_master_cfg.sv
├── spi_master_cfg_tb.sv
└── README.md
```

---

## Verification Methodology

The verification environment consists of:

- Configurable SPI Master (DUT)
- Multiple Behavioral SPI Slave Models
- Clock Generator
- Reset Generator
- Self-checking Scoreboard
- SystemVerilog Assertions (SVA)
- Automated Test Scenarios

The scoreboard automatically compares expected and actual data for every SPI transaction, eliminating the need for manual waveform analysis.

---

## Test Coverage

The verification includes:

Reset functionality
Slave selection verification
Communication with multiple SPI slaves
SPI Mode 0
SPI Mode 1
SPI Mode 2
SPI Mode 3
Clock Divider (/2)
Clock Divider (/4)
Clock Divider (/8)
Clock Divider (/16)
Master-to-Slave data transfer
Slave-to-Master data transfer
Simultaneous full-duplex communication
DONE signal generation
Busy signal behavior
Slave Select (SS) functionality
SCK idle polarity verification
Timeout handling
Data integrity verification

---

## SystemVerilog Assertions

The verification environment includes assertions to verify protocol correctness, including:

- DONE signal must be a single-cycle pulse.
- Only one Slave Select line is active during a transaction.
- Selected slave remains active throughout communication.
- SPI Clock returns to the configured idle polarity after transfer completion.

These assertions help detect protocol violations automatically during simulation.

---

## Simulation Output

The simulation generates:

- PASS/FAIL report for every test case
- Scoreboard comparison results
- Overall verification summary
- VCD waveform file for timing analysis

---

## Tools Used

- SystemVerilog
- ModelSim / QuestaSim
- GTKWave (for waveform viewing)

---

## Learning Outcomes

This project demonstrates:

- SPI protocol implementation
- Multi-slave communication
- Finite State Machine (FSM) design
- Self-checking verification methodology
- Scoreboard-based verification
- Behavioral modeling
- SystemVerilog Assertions (SVA)
- Functional verification techniques

---

## Future Enhancements

- Functional Coverage
- Constrained Random Verification
- UVM-based Verification Environment
- Parameterizable number of slave devices
- Variable frame sizes
- Coverage-driven verification

---

## Author

**Saipriyaa Thiagarajan**
