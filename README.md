## Repository Extension

The original repository presented a VHDL implementation of the Hummingbird-2 authenticated encryption algorithm developed as part of the thesis work, focusing on architectural exploration and FPGA-based realization of the cipher.

This repository has now been extended with a second FPGA architecture specifically designed for deployment and real-time operation on a Digilent Basys3 development board featuring the Xilinx Artix-7 XC7A35T FPGA.

The new implementation adopts a different hardware architecture optimized for practical FPGA deployment and resource efficiency. In addition to the cryptographic core, the system integrates:

- UART-based communication between PC and FPGA
- Custom packet-based communication protocol
- Multi-clock domain architecture with CDC synchronization
- Python-based desktop graphical user interface (GUI)
- Real-time encryption and decryption execution
- MAC generation and verification
- Automated validation framework
- Benchmarking and performance evaluation tools
- Monte Carlo reliability testing
- Real-time logging and monitoring capabilities

This extension transforms the original thesis implementation into a complete hardware/software co-design platform for lightweight authenticated encryption on physical FPGA hardware.

For the original/thesis approach, see:

Thesis Edition :[Thesis-Impl](./Thesis_Implementation)

For details regarding the FPGA deployment architecture, GUI application, benchmarking results, validation framework, and hardware resource utilization, see:

Basys3 Edition :[Basys3-Uart](./Basys3_UART_GUI_Architecture)
