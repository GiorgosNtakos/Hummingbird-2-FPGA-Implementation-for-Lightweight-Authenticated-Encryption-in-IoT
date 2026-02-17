# Hummingbird-2 FPGA Implementation for Lightweight Authenticated Encryption in IoT

![Language](https://img.shields.io/badge/HDL-VHDL-blue)
![FPGA](https://img.shields.io/badge/Target-Xilinx%20Artix--7-orange)
![Toolchain](https://img.shields.io/badge/Vivado-2019.2-green)
![Simulation](https://img.shields.io/badge/ModelSim-10.5b-purple)
![Degree](https://img.shields.io/badge/Thesis-Integrated%20Master-red)
![License](https://img.shields.io/badge/License-BSD--3--Clause-yellow)

---

## 🇬🇧 English Version

> 🇬🇷 Ελληνική έκδοση: [README_GR.md](./README_GR.md)

This repository contains the design and hardware implementation of a lightweight authenticated encryption system based on the Hummingbird-2 cryptographic algorithm, targeting resource-constrained Internet of Things (IoT) devices.

The system is implemented in VHDL and optimized for FPGA architectures, with emphasis on performance, hardware efficiency, and security. It supports encryption, decryption, authentication, and MAC verification suitable for RFID systems and wireless sensor networks.

---

### 🎓 Academic Context

This project was developed as a **Diploma Thesis (Integrated Master’s Degree)** at:

**Department of Computer Engineering and Informatics (CEID)**  
University of Patras, Greece  

Author: Georgios Ntakos  
Supervisor: Prof. Nikolaos Sklavos  
Thesis period: December 2022 — October 2024  
Presentation: October 2024  

---

### 🔐 Background

The rapid expansion of the Internet of Things introduces strict requirements for secure communication under severe hardware constraints. Lightweight cryptography provides security solutions optimized for low power consumption, limited memory, and reduced computational capabilities.

Hummingbird-2 is a hybrid lightweight authenticated encryption algorithm designed for such environments, combining properties of block and stream ciphers while providing confidentiality and integrity.

---

### ⚙️ System Features

- Lightweight authenticated encryption (AEAD)  
- Full hardware implementation in VHDL  
- Support for encryption and decryption  
- Message authentication (MAC generation and verification)  
- Architecture optimized for performance and hardware area  
- Suitable for RFID and wireless sensor applications  

---

### 🧠 Hardware Platform

- Target FPGA model: Xilinx Artix-7 (xc7a200tffg1156-3)  
- Implementation language: VHDL  
- Simulation: ModelSim – Intel FPGA Starter Edition 10.5b  
- Synthesis & Implementation: Xilinx Vivado 2019.2 WebPACK Edition  

⚠️ The design has been validated on FPGA models. Future work includes deployment on a physical Basys3 Artix-7 development board.

---

### 📂 Repository Structure

/src → VHDL source files  
/sim → Simulation files and testbenches  
/constraints → FPGA constraint files (if applicable)  
/docs → Thesis document and presentation  
/results → Implementation reports and performance data
/test_vectors → Test vectors used in TBs for verification

---

### 📊 Applications

- Secure IoT communication  
- RFID authentication systems  
- Wireless sensor networks  
- Embedded security modules  
- Resource-constrained devices  

---

### 🔮 Future Work

Planned future work includes deployment and validation on a physical Basys3 Artix-7 development board for real-world evaluation.

---

### ⚠️ Disclaimer

This implementation is provided for academic and research purposes only.

---

### 📖 Citation

If you use this work in academic research, please cite:

```bibtex
@mastersthesis{ntakos2024hummingbird2,
  author       = {Georgios Ntakos},
  title        = {Design and Implementation of a Lightweight Authenticated Encryption System for the Internet of Things},
  school       = {Department of Computer Engineering and Informatics, University of Patras},
  type         = {Diploma Thesis (Integrated Master)},
  year         = {2024},
  address      = {Patras, Greece},
  month        = {October},
  supervisor   = {Nikolaos Sklavos}
}
```

---

### 📜 License

This project is licensed under the BSD 3-Clause License.

Copyright (c) 2024, Georgios Ntakos.
All rights reserved.
