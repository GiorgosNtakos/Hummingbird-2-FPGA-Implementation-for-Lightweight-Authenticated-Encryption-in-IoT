import tkinter as tk
import matplotlib.pyplot as plt

from matplotlib.backends.backend_tkagg import (
    FigureCanvasTkAgg
)
from tkinter import ttk
from tkinter import messagebox

import serial
import time
import random
import hb_tool
import hb2_validation


COM_PORT = "COM3"
BAUDRATE = 115200

HB2_FCLK = 250e6
HB2_SLICES = 863


class HB2GUI:

    def __init__(self, root):
        
        self.encrypt_count = 0
        self.decrypt_count = 0

        self.valid_mac_count = 0
        self.invalid_mac_count = 0

        self.validation_runs = 0

        self.tests_passed = 0
        self.tests_failed = 0
        
        self.latency_history = []
        self.throughput_history = []
        
        self.hb2_latency_history = []
        self.hb2_throughput_history = []
        self.hb2_efficiency_history = []
        self.hb2_cycle_history = []
        
        self.benchmark_lengths = []
        self.benchmark_latency = []
        self.benchmark_throughput = []
        self.benchmark_cycles = []
        

        

        self.last_ciphertext = ""
        self.last_mac_tag = ""
        
        self.root = root

        root.title("HB2 FPGA Tool")
        self.notebook = ttk.Notebook(root)
        self.notebook.pack(
            fill="both",
            expand=True
        )

        self.crypto_tab = ttk.Frame(self.notebook)
        self.validation_tab = ttk.Frame(self.notebook)
        self.logs_tab = ttk.Frame(self.notebook)
        self.stats_tab_system = ttk.Frame(self.notebook)
        self.hb2_tab = tk.Frame(self.notebook)
        self.benchmark_tab = tk.Frame(
            self.notebook,
            bg="#1e1e1e"
        )
        self.about_tab = ttk.Frame(self.notebook)

        self.notebook.add(
            self.crypto_tab,
            text="Crypto"
        )

        self.notebook.add(
            self.validation_tab,
            text="Validation"
        )
        
        self.notebook.add(
            self.logs_tab,
            text="Logs"
        )
        
        self.notebook.add(
            self.stats_tab_system,
            text="System Statistics"
        )
        
        self.notebook.add(
            self.hb2_tab,
            text="HB2 Statistics"
        )
        
        self.notebook.add(
            self.benchmark_tab,
            text="HB2 Benchmark"
        )

        self.notebook.add(
            self.about_tab,
            text="About"
        )
        root.geometry("800x600")
        root.configure(
            bg="#1e1e1e"
        )
        style = ttk.Style()
        style.theme_use("clam")
        
        style.configure(
            "TNotebook",
            background="#1e1e1e"
        )

        style.configure(
            "TNotebook.Tab",
            background="#252526",
            foreground="white"
        )
        
        style.configure(
            ".",
            background="#1e1e1e",
            foreground="white"
        )

        style.configure(
            "TLabel",
            background="#1e1e1e",
            foreground="white"
        )

        style.configure(
            "TFrame",
            background="#1e1e1e"
        )

        style.configure(
            "TButton",
            padding=5
        )

        style.configure(
            "TCheckbutton",
            background="#1e1e1e",
            foreground="white"
        )

        style.configure(
            "TRadiobutton",
            background="#1e1e1e",
            foreground="white"
        )
        
        style.configure(
            "TEntry",
            fieldbackground="#252526",
            foreground="#00FF00"
        )
        
        style.configure(
            "Treeview",
            background="#252526",
            foreground="#00FF00",
            fieldbackground="#252526",
            rowheight=25
        )

        style.configure(
            "Treeview.Heading",
            background="#1e1e1e",
            foreground="white"
        )
        
        # ---------------------------------
        # Connection Status
        # ---------------------------------

        self.connection_label = tk.Label(
            self.crypto_tab,
            text="● FPGA Connected",
            fg="green",
            font=("Arial", 10, "bold")
        )

        self.connection_label.pack(pady=5)

        # ---------------------------------
        # Serial
        # ---------------------------------
        try:   
            self.ser = serial.Serial(
                port=COM_PORT,
                baudrate=BAUDRATE,
                bytesize=8,
                parity='N',
                stopbits=1,
                timeout=5
            )

            time.sleep(1)
            
        except Exception:

            self.connection_label.config(
                text="● FPGA Disconnected",
                fg="red"
            )

            self.ser = None

        # ---------------------------------
        # Operation
        # ---------------------------------

        self.operation_var = tk.StringVar()
        self.operation_var.set("encrypt")

        # ---------------------------------
        # Integrity
        # ---------------------------------

        self.integrity_var = tk.IntVar()

        # ---------------------------------
        # Labels
        # ---------------------------------

        ttk.Label(
            self.crypto_tab,
            text="Operation"
        ).pack()

        ttk.Radiobutton(
            self.crypto_tab,
            text="Encrypt",
            variable=self.operation_var,
            value="encrypt"
        ).pack()

        ttk.Radiobutton(
            self.crypto_tab,
            text="Decrypt",
            variable=self.operation_var,
            value="decrypt"
        ).pack()

        ttk.Label(
            self.crypto_tab,
            text="Key (32 hex chars)"
        ).pack()

        self.key_entry = ttk.Entry(
            self.crypto_tab,
            width=50
        )

        self.key_entry.pack()

        ttk.Label(
            self.crypto_tab,
            text="IV (16 hex chars)"
        ).pack()

        self.iv_entry = ttk.Entry(
            self.crypto_tab,
            width=50
        )

        self.iv_entry.pack()

        ttk.Label(
            self.crypto_tab,
            text="Data"
        ).pack()

        self.data_entry = ttk.Entry(
            self.crypto_tab,
            width=50
        )

        self.data_entry.pack()

        ttk.Label(
            self.crypto_tab,
            text="MAC Tag"
        ).pack()

        self.mac_entry = ttk.Entry(
            self.crypto_tab,
            width=50
        )

        self.mac_entry.pack()

        ttk.Label(
            self.crypto_tab,
            text="Text Length"
        ).pack()

        self.text_len_entry = ttk.Entry(
            self.crypto_tab,
            width=20
        )

        self.text_len_entry.insert(
            0,
            "128"
        )

        self.text_len_entry.pack()

        ttk.Checkbutton(
            self.crypto_tab,
            text="Integrity",
            variable=self.integrity_var
        ).pack()
        
        ttk.Button(
            self.crypto_tab,
            text="Use Last Encryption Result",
            command=self.load_last_result
        ).pack()
        
        ttk.Label(
            self.crypto_tab,
            text="Test Vector"
        ).pack()

        self.tv_combo = ttk.Combobox(
            self.crypto_tab,
            values=[
                "TV1",
                "TV3",
                "TV5"
            ],
            state="readonly",
            width=15
        )

        self.tv_combo.pack(
            pady=2
        )

        self.tv_combo.bind(
            "<<ComboboxSelected>>",
            self.load_selected_tv
        )

        ttk.Button(
            self.crypto_tab,
            text="RUN",
            command=self.run_crypto
        ).pack(
            pady=5
        )
        
        ttk.Button(
            self.validation_tab,
            text="Run Validation Suite",
            command=self.run_validation
        ).pack(
            pady=5
        )
        
        self.benchmark_toolbar = tk.Frame(
            self.benchmark_tab,
            bg="#1e1e1e"
        )

        self.benchmark_toolbar.pack(
            fill="x",
            pady=0,
            padx=0
        )

        ttk.Button(
            self.benchmark_toolbar,
            text="Run HB2 Benchmark",
            command=self.run_hb2_benchmark
        ).pack(
            pady=0,
            padx=0
        )

        # ---------------------------------
        # OUTPUTS
        # ---------------------------------

        ttk.Label(
            self.crypto_tab,
            text="Data Output"
        ).pack()

        self.data_output_entry = ttk.Entry(
            self.crypto_tab,
            width=60
        )

        self.data_output_entry.pack()

        ttk.Label(
            self.crypto_tab,
            text="MAC Tag Output"
        ).pack()

        self.mac_output_entry = ttk.Entry(
            self.crypto_tab,
            width=60
        )

        self.mac_output_entry.pack()

        self.mac_status_label = tk.Label(
            self.crypto_tab,
            text="MAC STATUS: N/A",
            font=("Arial", 10, "bold"),
            fg="white",
            bg="#1e1e1e"
        )

        self.mac_status_label.pack(
            pady=5
        )
        
        # ---------------------------------
        # LAST ENCRYPTION RESULT
        # ---------------------------------

        ttk.Label(
            self.crypto_tab,
            text="Last Encryption Result"
        ).pack(
            pady=5
        )

        self.last_result_text = tk.Text(
            self.crypto_tab,
            height=6,
            width=90,
            bg="#252526",
            fg="#00FF00",
            insertbackground="#00FF00"
        )

        self.last_result_text.pack()
        
        ttk.Label(
            self.validation_tab,
            text="Validation Console"
        ).pack(pady=5)

        self.output_text = tk.Text(
            self.validation_tab,
            height=15,
            width=90,
            bg="#252526",
            fg="#00FF00",
            insertbackground="white"
        )

        self.output_text.pack()
        
        ttk.Label(
            self.crypto_tab,
            text="Packet Viewer"
        ).pack(
            pady=5
        )

        self.packet_viewer = tk.Text(
            self.crypto_tab,
            height=15,
            width=90,
            bg="#252526",
            fg="#00FF00",
            insertbackground="white"
        )

        self.packet_viewer.pack()
        
        # ---------------------------------
        # VALIDATION TABLE
        # ---------------------------------

        ttk.Label(
            self.validation_tab,
            text="Validation Results"
        ).pack(
            pady=5
        )

        self.validation_table = ttk.Treeview(
            self.validation_tab,
            columns=("test", "result"),
            show="headings",
            height=8
        )

        self.validation_table.heading(
            "test",
            text="Test Vector"
        )

        self.validation_table.heading(
            "result",
            text="Result"
        )

        self.validation_table.column(
            "test",
            width=300,
            anchor="center"
        )

        self.validation_table.column(
            "result",
            width=120,
            anchor="center"
        )

        self.validation_table.pack()
        
        self.validation_table.tag_configure(
            "even",
            background="#252526"
        )

        self.validation_table.tag_configure(
            "odd",
            background="#2d2d30"
        )
        
        # ---------------------------------
        # SESSION LOG
        # ---------------------------------

        ttk.Label(
            self.logs_tab,
            text="Session Log"
        ).pack(
            pady=5
        )

        self.log_text = tk.Text(
            self.logs_tab,
            height=8,
            width=90,
            bg="#252526",
            fg="#00FF00",
            insertbackground="white"
        )
        
        self.log_text.pack(
            pady=5
        )
        
        ttk.Button(
            self.logs_tab,
            text="Clear",
            command=self.clear_log
        ).pack(
            pady=5
        )

        self.log_text.pack()

        self.last_result_text.insert(
                tk.END,
                "No encryption executed yet."
            )
            
        self.output_text.tag_config(
            "pass",
            foreground="green"
        )

        self.output_text.tag_config(
            "fail",
            foreground="red"
        )

        self.output_text.tag_config(
            "title",
            foreground="blue"
        )
        
        # ---------------------------------
        # SYSTEM STATS TAB
        # ---------------------------------
        self.stats_label = tk.Label(
            self.stats_tab_system,
            justify="left",
            font=("Consolas", 12),
            bg="#1e1e1e",
            fg="#00FF00"
        )

        self.stats_label.pack(
            pady=20
        )
        
        self.figure = plt.Figure(
            figsize=(6, 3),
            dpi=100
        )

        self.ax = self.figure.add_subplot(111)

        self.ax.set_title(
            "System Latency History"
        )

        self.ax.set_ylabel(
            "Latency (ms)"
        )

        self.ax.set_xlabel(
            "Operation"
        )

        self.canvas = FigureCanvasTkAgg(
            self.figure,
            master=self.stats_tab_system
        )

        self.canvas.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady=10
        )
        
        self.figure2 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax2 = self.figure2.add_subplot(
            111
        )

        self.canvas2 = FigureCanvasTkAgg(
            self.figure2,
            master=self.stats_tab_system
        )

        self.canvas2.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady=10
        )
        
        self.figure3 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax3 = self.figure3.add_subplot(111)

        self.canvas3 = FigureCanvasTkAgg(
            self.figure3,
            master=self.hb2_tab
        )

        self.canvas3.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady=0
        )
        
        self.figure4 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax4 = self.figure4.add_subplot(111)

        self.canvas4 = FigureCanvasTkAgg(
            self.figure4,
            master=self.hb2_tab
        )

        self.canvas4.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady=0
        )
        
        self.figure5 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax5 = self.figure5.add_subplot(111)

        self.canvas5 = FigureCanvasTkAgg(
            self.figure5,
            master=self.hb2_tab
        )

        self.canvas5.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady=0
        )
        
        self.figure_b1 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax_b1 = self.figure_b1.add_subplot(
            111
        )

        self.canvas_b1 = FigureCanvasTkAgg(
            self.figure_b1,
            master=self.benchmark_tab
        )

        self.canvas_b1.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady =0
        )
        
        self.figure_b2 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax_b2 = self.figure_b2.add_subplot(
            111
        )

        self.canvas_b2 = FigureCanvasTkAgg(
            self.figure_b2,
            master=self.benchmark_tab
        )

        self.canvas_b2.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady =0
        )
        
        self.figure_b3 = plt.Figure(
            figsize=(6,3),
            dpi=100
        )

        self.ax_b3 = self.figure_b3.add_subplot(
            111
        )

        self.canvas_b3 = FigureCanvasTkAgg(
            self.figure_b3,
            master=self.benchmark_tab
        )

        self.canvas_b3.get_tk_widget().pack(
            fill="both",
            expand=True,
            pady =0
        )
        
        self.figure_b1.subplots_adjust(
            left=0.08,
            right=0.98,
            top=0.92,
            bottom=0.15
        )

        self.figure_b2.subplots_adjust(
            left=0.08,
            right=0.98,
            top=0.92,
            bottom=0.15
        )

        self.figure_b3.subplots_adjust(
            left=0.08,
            right=0.98,
            top=0.92,
            bottom=0.15
        )
        
        ttk.Label(
            self.stats_tab_system,
            text="Monte Carlo Iterations"
        ).pack(
            pady=(20,5)
        )

        self.stress_var = tk.StringVar()

        self.stress_var.set("100")

        stress_combo = ttk.Combobox(
            self.stats_tab_system,
            textvariable=self.stress_var,
            values=[
                "100",
                "1000",
                "10000"
            ],
            width=10,
            state="readonly"
        )

        stress_combo.pack()

        ttk.Button(
            self.stats_tab_system,
            text="Run Monte Carlo",
            command=self.run_monte_carlo
        ).pack(
            pady=10
        )
        
        # ---------------------------------
        # HB2 CORE STATS TAB
        # ---------------------------------
        self.hb2_stats_label = tk.Label(
            self.hb2_tab,
            text="",
            justify="left",
            anchor="nw",
            bg="#1e1e1e",
            fg="#00FF00",
            font=("Consolas", 10)
        )

        self.hb2_stats_label.pack(
            fill="x",
            padx=0,
            pady=0
        )
        
        # ---------------------------------
        # BENCHM MARK STATS TAB
        # ---------------------------------
        self.benchmark_stats_label = tk.Label(
            self.benchmark_tab,
            text="",
            justify="left",
            anchor="nw",
            bg="#1e1e1e",
            fg="#00FF00",
            font=("Consolas", 10)
        )

        self.benchmark_stats_label.pack(
            fill="x",
            padx=5,
            pady=5
        )
                
        # ---------------------------------
        # ABOUT TAB
        # ---------------------------------

        about_text = """
        HB2 FPGA Crypto Accelerator

        Author:
        Giorgos Ntakos

        Board:
        Basys3

        FPGA:
        Artix-7 XC7A35T

        Communication:
        UART 115200 baud

        RX Packet:
        58 bytes

        TX Packet:
        35 bytes

        Features:
        - Encrypt
        - Decrypt
        - MAC Verification
        - Integrity Mode
        - Validation Suite
        - UART Packet Interface

        Version:
        v1.0
        """

        self.about_text = tk.Text(
            self.about_tab,
            height=25,
            width=60,
            bg="#252526",
            fg="#00FF00",
            insertbackground="#00FF00",
            font=("Consolas", 11),
            relief="flat",
            borderwidth=0
        )

        self.about_text.pack(
            padx=20,
            pady=20
        )

        self.about_text.insert(
            tk.END,
            about_text
        )

        self.about_text.config(
            state="disabled"
        )
        self.update_graph()
        self.update_benchmark_graphs()

    # ---------------------------------
    # RUN
    # ---------------------------------

    def run_crypto(self):

        try:
            
            if self.ser is None:

                messagebox.showerror(
                    "Connection Error",
                    "FPGA not connected"
                )

                return

            key = self.key_entry.get().strip()
            iv = self.iv_entry.get().strip()

            data = self.data_entry.get().strip()
            mac = self.mac_entry.get().strip()

            text_len = int(
                self.text_len_entry.get()
            )

            integrity = self.integrity_var.get()
            
            self.add_log(
                "Crypto Operation Started"
            )

            if self.operation_var.get() == "encrypt":
                
                self.add_log(
                "Encrypt Requested"
            )
                self.encrypt_count += 1
                
                operation = 0
                verify_mac = 0

                if mac == "":
                    mac = (
                        "0000000000000000"
                        "0000000000000000"
                    )

            else:
                
                self.add_log(
                    "Decrypt Requested"
                )
                
                self.decrypt_count += 1
                
                operation = 1
                verify_mac = 1

            start_time = time.perf_counter()
            
            data_out, mac_tag, mac_valid, latency_cycles = (
                hb_tool.run_command(
                    self.ser,

                    operation,
                    integrity,
                    verify_mac,

                    text_len,

                    key,
                    iv,

                    data,
                    mac
                )
            )
            
            end_time = time.perf_counter()

            latency_ms = (
                end_time - start_time
            ) * 1000

            self.latency_history.append(
                latency_ms
            )
            
            hb2_latency_ms = (
                latency_cycles / HB2_FCLK
            ) * 1e3
            
            hb2_throughput_kbps = (
                text_len * HB2_FCLK
                /
                latency_cycles
            ) / 1e3
            
            hb2_efficiency = (
                hb2_throughput_kbps
                /
                HB2_SLICES
            )
            
            throughput_bps = (
                text_len
                /
                (latency_ms / 1000)
            )
            
            self.throughput_history.append(
                throughput_bps
            )
            
            self.hb2_latency_history.append(
                hb2_latency_ms
            )

            self.hb2_throughput_history.append(
                hb2_throughput_kbps
            )

            self.hb2_efficiency_history.append(
                hb2_efficiency
            )
            
            self.hb2_cycle_history.append(
                latency_cycles
            )
            
            flags = hb_tool.build_flags(
                operation,
                integrity,
                verify_mac
            )
            
            self.packet_viewer.delete(
                "1.0",
                tk.END
            )

            self.packet_viewer.insert(
                tk.END,
                "===== TX PACKET =====\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"Flags    : {flags:02X}\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"Text Len : {text_len}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"Key:\n{key}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"IV:\n{iv}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"Data:\n{data}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"MAC:\n{mac}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                "===== RX PACKET =====\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"Data Output:\n{data_out}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"MAC Tag:\n{mac_tag}\n\n"
            )

            self.packet_viewer.insert(
                tk.END,
                f"MAC Valid:\n{mac_valid}\n"
            )
            
            self.packet_viewer.insert(
                tk.END,
                f"Latency Cycles:\n{latency_cycles}\n"
            )
            
            self.add_log(
            "FPGA Response Received"
        )
            
            self.last_ciphertext = data_out
            self.last_mac_tag = mac_tag
            
            if operation == 0:

                self.last_result_text.delete(
                    "1.0",
                    tk.END
                )

                self.last_result_text.insert(
                    tk.END,
                    f"Ciphertext:\n{data_out}\n\n"
                    f"MAC Tag:\n{mac_tag}"
                )

            self.data_output_entry.delete(
                0,
                tk.END
            )

            self.data_output_entry.insert(
                0,
                data_out
            )

            self.mac_output_entry.delete(
                0,
                tk.END
            )

            self.mac_output_entry.insert(
                0,
                mac_tag
            )
            
            if operation == 0:

                self.mac_status_label.config(
                    text="MAC STATUS: GENERATED",
                    fg="#00FF00"
                )

            elif mac_valid == 1:
                self.valid_mac_count += 1

                self.add_log(
                    "MAC VALID"
                )

                self.mac_status_label.config(
                    text="MAC STATUS: VALID",
                    fg="#00FF00"
                )

            else:
                self.invalid_mac_count += 1

                self.add_log(
                    "MAC INVALID"
                )

                self.mac_status_label.config(
                    text="MAC STATUS: INVALID",
                    fg="red"
                )

        except Exception as e:

            messagebox.showerror(
                "Error",
                str(e)
            )
            
        self.update_statistics()
        self.update_graph()
        self.update_benchmark_graphs()
        
    # ---------------------------------
    # LOG HELPER
    # ---------------------------------

    def add_log(self, message):

        import datetime

        timestamp = datetime.datetime.now().strftime(
            "%H:%M:%S"
        )

        self.log_text.insert(
            tk.END,
            f"[{timestamp}] {message}\n"
        )

        self.log_text.see(tk.END)
        
    # ---------------------------------
    # VALIDATION
    # ---------------------------------

    def run_validation(self):
        self.add_log(
        "Validation Started"
    )

        try:

            self.output_text.delete(
                "1.0",
                tk.END
            )

            self.output_text.insert(
                tk.END,
                "Running Validation Suite...\n\n",
                "title"
            )

            results = (
                hb2_validation.run_validation_suite(
                    self.ser
                )
            )
            
            # ---------------------------------
            # CLEAR TABLE
            # ---------------------------------

            for item in self.validation_table.get_children():

                self.validation_table.delete(item)

            # ---------------------------------
            # FILL TABLE
            # ---------------------------------

            for index, (test_name, result) in enumerate(results):

                tag = "even" if index % 2 == 0 else "odd"

                self.validation_table.insert(
                    "",
                    tk.END,
                    values=(
                        test_name,
                        result
                    ),
                    tags=(tag,)
                )

            passed = 0
            
            for _, result in results:

                if result == "PASS":

                    passed += 1

            self.add_log(
                f"Validation Result: {passed}/{len(results)} PASSED"
            )

            for test_name, result in results:

                if result == "PASS":

                    self.output_text.insert(
                        tk.END,
                        f"{test_name:<20} PASS\n",
                        "pass"
                    )

                else:

                    self.output_text.insert(
                        tk.END,
                        f"{test_name:<20} FAIL\n",
                        "fail"
                    )

            self.output_text.insert(
                tk.END,
                "\n"
            )

            self.output_text.insert(
                tk.END,
                f"TOTAL: {passed}/{len(results)} PASSED\n",
                "title"
            )
            
            self.add_log(
                "Validation Finished"
            )

            if passed == len(results):

                self.output_text.insert(
                    tk.END,
                    "\n🎉 ALL VALIDATION TESTS PASSED 🎉\n"
                )

        except Exception as e:

            messagebox.showerror(
                "Validation Error",
                str(e)
            )
            
    def load_last_result(self):

        self.operation_var.set("decrypt")
        
        self.output_text.insert(
        tk.END,
        "\nLoaded previous encryption result.\n"
        )

        self.data_entry.delete(0, tk.END)
        self.data_entry.insert(
            0,
            self.last_ciphertext
        )

        self.mac_entry.delete(0, tk.END)
        self.mac_entry.insert(
            0,
            self.last_mac_tag
        )
        
    # ---------------------------------
    # TEST VECTOR 1
    # ---------------------------------

    def load_tv1(self):

        self.operation_var.set("encrypt")
        self.integrity_var.set(0)

        self.key_entry.delete(0, tk.END)
        self.key_entry.insert(
            0,
            "23016745AB89EFCDDCFE98BA54761032"
        )

        self.iv_entry.delete(0, tk.END)
        self.iv_entry.insert(
            0,
            "34127856BC9AF0DE"
        )

        self.data_entry.delete(0, tk.END)
        self.data_entry.insert(
            0,
            "11003322554477669988BBAADDCCFFEE"
        )

        self.mac_entry.delete(0, tk.END)

        self.text_len_entry.delete(0, tk.END)
        self.text_len_entry.insert(
            0,
            "128"
        )
        
    # ---------------------------------
    # TEST VECTOR 3
    # ---------------------------------

    def load_tv3(self):

        self.operation_var.set("encrypt")
        self.integrity_var.set(0)

        self.key_entry.delete(0, tk.END)
        self.key_entry.insert(
            0,
            "00000000000000000000000000000000"
        )

        self.iv_entry.delete(0, tk.END)
        self.iv_entry.insert(
            0,
            "0000000000000000"
        )

        self.data_entry.delete(0, tk.END)
        self.data_entry.insert(
            0,
            "00000000000000000000000000000000"
        )

        self.mac_entry.delete(0, tk.END)

        self.text_len_entry.delete(0, tk.END)
        self.text_len_entry.insert(
            0,
            "13"
        )
        
    # ---------------------------------
    # TEST VECTOR 5
    # ---------------------------------

    def load_tv5(self):

        self.operation_var.set("encrypt")
        self.integrity_var.set(1)

        self.key_entry.delete(0, tk.END)
        self.key_entry.insert(
            0,
            "23016745AB89EFCDDCFE98BA54761032"
        )

        self.iv_entry.delete(0, tk.END)
        self.iv_entry.insert(
            0,
            "34127856BC9AF0DE"
        )

        self.data_entry.delete(0, tk.END)
        self.data_entry.insert(
            0,
            "11003322554477669988BBAADDCCFFEE"
        )

        self.mac_entry.delete(0, tk.END)

        self.text_len_entry.delete(0, tk.END)
        self.text_len_entry.insert(
            0,
            "83"
        )
        
    def load_selected_tv(self, event):

        selected = self.tv_combo.get()

        if selected == "TV1":
            self.load_tv1()

        elif selected == "TV3":
            self.load_tv3()

        elif selected == "TV5":
            self.load_tv5()
            
    # ---------------------------------
    # CLEAR
    # ---------------------------------
            
    def clear_log(self):

        self.log_text.delete(
            "1.0",
            tk.END
        )
        
    # ---------------------------------
    # STATS
    # ---------------------------------
    def update_statistics(self):

        if len(self.latency_history) > 0:

            avg_latency = (
                sum(self.latency_history)
                /
                len(self.latency_history)
            )

            max_latency = max(
                self.latency_history
            )

            min_latency = min(
                self.latency_history
            )
            
            avg_throughput = (
                sum(self.throughput_history)
                /
                len(self.throughput_history)
            )

            max_throughput = max(
                self.throughput_history
            )
            
            avg_throughput_kbps = (
                avg_throughput / 1000
            )

            max_throughput_kbps = (
                max_throughput / 1000
            )
            
            avg_hb2_latency = (
                sum(self.hb2_latency_history)
                /
                len(self.hb2_latency_history)
            )
            
            avg_hb2_throughput = (
                sum(self.hb2_throughput_history)
                /
                len(self.hb2_throughput_history)
            )
                
            avg_hb2_efficiency = (
               sum(self.hb2_efficiency_history)
                /
                len(self.hb2_efficiency_history)
            )
            
            avg_cycles = (
                sum(self.hb2_cycle_history)
                /
                len(self.hb2_cycle_history)
            )

            min_cycles = min(
                self.hb2_cycle_history
            )

            max_cycles = max(
                self.hb2_cycle_history
            )

        else:

            avg_latency = 0
            max_latency = 0
            min_latency = 0
            
            avg_throughput_kbps = 0
            max_throughput_kbps = 0
            
            avg_hb2_latency = 0
            avg_hb2_throughput = 0
            avg_hb2_efficiency = 0
            
            avg_cycles = 0
            min_cycles = 0
            max_cycles = 0

        self.stats_label.config(
            text=
            f"""
        Encryptions      : {self.encrypt_count}
        Decryptions      : {self.decrypt_count}

        Valid MACs       : {self.valid_mac_count}
        Invalid MACs     : {self.invalid_mac_count}

        Average Latency__SYSTEM  : {avg_latency:.2f} ms
        Maximum Latency__SYSTEM  : {max_latency:.2f} ms
        Minimum Latency__SYSTEM  : {min_latency:.2f} ms
        
        Average Throughput_SYSTEM : {avg_throughput_kbps:.2f} kbps
        Peak Throughput_SYSTEM    : {max_throughput_kbps:.2f} kbps
        """
        )
        
        self.hb2_stats_label.config(
            text=
            f"""
        HB2 Average Latency    : {avg_hb2_latency:.2f} ms

        HB2 Average Throughput : {avg_hb2_throughput:.2f} Kbps

        HB2 Efficiency         : {avg_hb2_efficiency:.2f} Kbps/Slice
        
        HB2 Average Cycles     : {avg_cycles:.1f}

        HB2 Minimum Cycles     : {min_cycles}

        HB2 Maximum Cycles     : {max_cycles}
        """
        )
        
    # ---------------------------------
    # STRESS TEST
    # ---------------------------------
    def run_monte_carlo(self):

        import secrets

        iterations = int(
            self.stress_var.get()
        )

        passed = 0
        failed = 0

        self.add_log(
            f"Monte Carlo Started ({iterations})"
        )

        for i in range(iterations):

            try:
                start_time = time.perf_counter()

                key = secrets.token_hex(16)

                iv = secrets.token_hex(8)

                plaintext = (
                    secrets.token_hex(16)
                )

                # -------------------
                # Encrypt
                # -------------------

                ciphertext, mac_tag, _, enc_cycles = (
                    hb_tool.run_command(

                        self.ser,

                        operation=0,
                        integrity=0,
                        verify_mac=0,

                        text_len = 128,

                        key_hex=key,
                        iv_hex=iv,

                        data_hex=plaintext,

                        mac_hex=
                        "00000000000000000000000000000000"
                    )
                )

                # -------------------
                # Decrypt
                # -------------------

                decrypted, _, mac_valid, dec_cycles = (
                    hb_tool.run_command(

                        self.ser,

                        operation=1,
                        integrity=0,
                        verify_mac=1,

                        text_len=128,

                        key_hex=key,
                        iv_hex=iv,

                        data_hex=ciphertext,

                        mac_hex=mac_tag
                    )
                )
                
                end_time = time.perf_counter()

                latency_ms = (
                    end_time - start_time
                ) * 1000
                
                hb2_cycles = (enc_cycles + dec_cycles)
                
                hb2_latency_ms = (
                    hb2_cycles / HB2_FCLK
                ) * 1e3
                
                hb2_throughput_kbps = (
                    256 * HB2_FCLK / hb2_cycles
                ) / 1e3
                
                hb2_efficiency = (
                    hb2_throughput_kbps / HB2_SLICES
                )
                
                self.hb2_latency_history.append(
                    hb2_latency_ms
                )
                
                self.hb2_throughput_history.append(
                    hb2_throughput_kbps
                )
                
                self.hb2_efficiency_history.append(
                    hb2_efficiency
                )
                
                self.hb2_cycle_history.append(
                    hb2_cycles
                )
                

                self.latency_history.append(
                    latency_ms
                )

                throughput_bps = (
                    256 /
                    (latency_ms / 1000)
                )

                self.throughput_history.append(
                    throughput_bps
                )

                if (
                    decrypted == plaintext.upper()
                    and
                    mac_valid == 1
                ):

                    passed += 1

                    self.encrypt_count += 1
                    self.decrypt_count += 1

                    self.valid_mac_count += 1

                else:

                    failed += 1

                    self.invalid_mac_count += 1

            except:

                failed += 1

        self.add_log(
            f"Monte Carlo Finished "
            f"{passed}/{iterations}"
        )
        
        self.update_statistics()

        self.update_graph()

        messagebox.showinfo(
            "Monte Carlo Result",

            f"""
    Iterations : {iterations}

    Passed : {passed}

    Failed : {failed}

    Success Rate :

    {(passed/iterations)*100:.2f} %
    """
        )
        
        
    # ---------------------------------
    # GRAPHS
    # ---------------------------------        
    def update_graph(self):

        self.ax.clear()
        self.figure.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax.set_facecolor(
            "#252526"
        )
        
        self.ax.tick_params(
            colors="#00FF00"
        )

        self.ax.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax.title.set_color(
            "#00FF00"
        )
        
        for spine in self.ax.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.ax.plot(
            self.latency_history,
            marker="o",
            color="#00FF00"
        )
        
        self.ax.grid(
            True,
            color="#404040"
        )

        self.ax.set_title(
            "System Latency History"
        )

        self.ax.set_ylabel(
            "Latency (ms)"
        )

        self.ax.set_xlabel(
            "Operation"
        )

        self.canvas.draw()
        
        self.ax2.clear()

        self.figure2.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax2.set_facecolor(
            "#252526"
        )

        self.ax2.plot(
            self.throughput_history,
            marker="o",
            color="#00FF00"
        )
        
        self.ax2.grid(
            True,
            color="#404040"
        )

        self.ax2.set_title(
            "System Throughput History"
        )

        self.ax2.set_ylabel(
            "bps"
        )

        self.ax2.set_xlabel(
            "Operation"
        )

        self.ax2.tick_params(
            colors="#00FF00"
        )

        self.ax2.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax2.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax2.title.set_color(
            "#00FF00"
        )

        for spine in self.ax2.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.canvas2.draw()
        
        self.ax3.clear()

        self.figure3.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax3.set_facecolor(
            "#252526"
        )

        self.ax3.plot(
            self.hb2_latency_history,
            marker="o",
            color="#00FF00"
        )

        self.ax3.grid(
            True,
            color="#404040"
        )

        self.ax3.set_title(
            "HB2 Core Latency History"
        )

        self.ax3.set_ylabel(
            "ms"
        )

        self.ax3.set_xlabel(
            "Operation"
        )

        self.ax3.tick_params(
            colors="#00FF00"
        )

        self.ax3.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax3.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax3.title.set_color(
            "#00FF00"
        )

        for spine in self.ax3.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.canvas3.draw()
        
        self.ax4.clear()

        self.figure4.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax4.set_facecolor(
            "#252526"
        )

        self.ax4.plot(
            self.hb2_throughput_history,
            marker="o",
            color="#00FF00"
        )

        self.ax4.grid(
            True,
            color="#404040"
        )

        self.ax4.set_title(
            "HB2 Core Throughput History"
        )

        self.ax4.set_ylabel(
            "Kbps"
        )

        self.ax4.set_xlabel(
            "Operation"
        )

        self.ax4.tick_params(
            colors="#00FF00"
        )

        self.ax4.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax4.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax4.title.set_color(
            "#00FF00"
        )

        for spine in self.ax4.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.canvas4.draw()
        
        self.ax5.clear()

        self.figure5.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax5.set_facecolor(
            "#252526"
        )

        self.ax5.plot(
            self.hb2_efficiency_history,
            marker="o",
            color="#00FF00"
        )

        self.ax5.grid(
            True,
            color="#404040"
        )

        self.ax5.set_title(
            "HB2 Core Efficiency History"
        )

        self.ax5.set_ylabel(
            "Kbps/Slice"
        )

        self.ax5.set_xlabel(
            "Operation"
        )

        self.ax5.tick_params(
            colors="#00FF00"
        )

        self.ax5.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax5.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax5.title.set_color(
            "#00FF00"
        )

        for spine in self.ax5.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.canvas5.draw()
        
    def run_hb2_benchmark(self):
        
        if self.ser is None:

            messagebox.showerror(
                "Connection Error",
                "FPGA not connected"
            )

            return

        self.benchmark_lengths.clear()

        self.benchmark_latency.clear()

        self.benchmark_throughput.clear()
        
        self.benchmark_cycles.clear()
        
        benchmark_text = ""

        lengths = [
            16,
            32,
            48,
            64,
            80,
            96,
            112,
            128
        ]

        key = "23016745AB89EFCDDCFE98BA54761032"

        iv = "34127856BC9AF0DE"

        data = "11003322554477669988BBAADDCCFFEE"
        
        self.add_log("")
        self.add_log("====================================")
        self.add_log("HB2 BENCHMARK STARTED")
        self.add_log("====================================")

        for i, text_len in enumerate(lengths, start=1):
            
            self.add_log(
                f"[{i}/{len(lengths)}] Running benchmark "
                f"for text_len={text_len} bits"
            )

            self.root.update()

            ciphertext, mac_tag, _, enc_cycles = (
                hb_tool.run_command(
                    self.ser,

                    operation=0,
                    integrity=0,
                    verify_mac=0,

                    text_len=text_len,

                    key_hex=key,
                    iv_hex=iv,

                    data_hex=data,

                    mac_hex=
                    "00000000000000000000000000000000"
                )
            )

            plaintext, _, _, dec_cycles = (
                hb_tool.run_command(
                    self.ser,

                    operation=1,
                    integrity=0,
                    verify_mac=1,

                    text_len=text_len,

                    key_hex=key,
                    iv_hex=iv,

                    data_hex=ciphertext,

                    mac_hex=mac_tag
                )
            )

            latency_cycles = (
                enc_cycles +
                dec_cycles
            )

            latency_ms = (
                latency_cycles
                /
                HB2_FCLK
            ) * 1e3

            throughput_kbps = (
                text_len
                *
                HB2_FCLK
                /
                latency_cycles
            ) / 1e3

            self.benchmark_lengths.append(
                text_len
            )

            self.benchmark_latency.append(
                latency_ms
            )

            self.benchmark_throughput.append(
                throughput_kbps
            )
            
            self.benchmark_cycles.append(
                latency_cycles
            )
            
            benchmark_text += (
                f"Text Length : {text_len:>3d} bits   "
                f"Cycles : {latency_cycles:>4d}   "
                f"Latency : {latency_ms:>7.4f} ms   "
                f"Throughput : {throughput_kbps:>8.2f} kbps\n"
            )
            
        self.add_log("====================================")
        self.add_log("HB2 BENCHMARK FINISHED")
        self.add_log("====================================")
        
        avg_latency = (
            sum(self.benchmark_latency)
            /
            len(self.benchmark_latency)
        )

        avg_throughput = (
            sum(self.benchmark_throughput)
            /
            len(self.benchmark_throughput)
        )

        avg_cycles = (
            sum(self.benchmark_cycles)
            /
            len(self.benchmark_cycles)
        )

        results_text = (
            "HB2 BENCHMARK RESULTS\n\n"
            + benchmark_text +
            "\n"
            + f"Average Latency    : {avg_latency:.4f} ms\n"
            + f"Average Throughput : {avg_throughput:.2f} kbps\n"
            + f"Average Cycles     : {avg_cycles:.1f}"
        )

        self.benchmark_stats_label.config(
            text=results_text
        )

        self.update_benchmark_graphs()
        
    def update_benchmark_graphs(self):
        self.ax_b1.clear()
        
        self.figure_b1.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax_b1.set_facecolor(
            "#252526"
        )

        self.ax_b1.tick_params(
            colors="#00FF00"
        )

        self.ax_b1.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b1.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b1.title.set_color(
            "#00FF00"
        )

        for spine in self.ax_b1.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.figure_b1.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax_b1.set_facecolor(
            "#252526"
        )

        self.ax_b1.plot(
            self.benchmark_lengths,
            self.benchmark_latency,
            marker="o",
            color="#00FF00"
        )

        self.ax_b1.grid(
            True,
            color="#404040"
        )

        self.ax_b1.set_title(
            "HB2 End-to-End Latency vs Text Length"
        )

        self.ax_b1.set_xlabel(
            "Text Length (bits)"
        )

        self.ax_b1.set_ylabel(
            "Latency (ms)"
        )

        self.canvas_b1.draw()
        
        self.ax_b2.clear()
        
        self.figure_b2.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax_b2.set_facecolor(
            "#252526"
        )

        self.ax_b2.tick_params(
            colors="#00FF00"
        )

        self.ax_b2.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b2.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b2.title.set_color(
            "#00FF00"
        )

        for spine in self.ax_b2.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.figure_b2.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax_b2.set_facecolor(
            "#252526"
        )

        self.ax_b2.plot(
            self.benchmark_lengths,
            self.benchmark_throughput,
            marker="o",
            color="#00FF00"
        )

        self.ax_b2.grid(
            True,
            color="#404040"
        )

        self.ax_b2.set_title(
            "HB2 Throughput vs Text Length"
        )

        self.ax_b2.set_xlabel(
            "Text Length (bits)"
        )

        self.ax_b2.set_ylabel(
            "Throughput (Kbps)"
        )

        self.canvas_b2.draw()
        
        self.ax_b3.clear()

        self.figure_b3.patch.set_facecolor(
            "#1e1e1e"
        )

        self.ax_b3.set_facecolor(
            "#252526"
        )

        self.ax_b3.tick_params(
            colors="#00FF00"
        )

        self.ax_b3.xaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b3.yaxis.label.set_color(
            "#00FF00"
        )

        self.ax_b3.title.set_color(
            "#00FF00"
        )

        for spine in self.ax_b3.spines.values():

            spine.set_color(
                "#00FF00"
            )

        self.ax_b3.plot(
            self.benchmark_lengths,
            self.benchmark_cycles,
            marker="o",
            color="#00FF00"
        )

        self.ax_b3.grid(
            True,
            color="#404040"
        )

        self.ax_b3.set_title(
            "HB2 Processing Cycles vs Text Length"
        )

        self.ax_b3.set_xlabel(
            "Text Length (bits)"
        )

        self.ax_b3.set_ylabel(
            "Cycles"
        )

        self.canvas_b3.draw()


root = tk.Tk()

app = HB2GUI(root)

root.mainloop()