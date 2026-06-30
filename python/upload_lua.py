from typing import cast
import pyvisa
import time
from pyvisa.resources import TCPIPInstrument
import matplotlib.pyplot as plt
import numpy as np

file = "../lua/ttl_pulsed_sweep_bidirectional.lua"

rm = pyvisa.ResourceManager()
keithley: TCPIPInstrument = cast(TCPIPInstrument, rm.open_resource("TCPIP0::192.168.1.129::INSTR"))

keithley.read_termination = "\n"
keithley.write_termination = "\n"

keithley.write("errorqueue.clear()")

with open(file, "r") as ctx:
    for line in ctx:
        stripped_line = line.strip()
        if stripped_line:
            keithley.write(stripped_line)
            time.sleep(0.015)

print("Script uploaded successfully.")

# Validate if the compiler accepted the code before execution
err_check = keithley.query("print(errorqueue.next())")
if "0" not in err_check.split("\t")[0] and "0" not in err_check.split(",")[0]:
    print(f"Compilation error: {err_check}")
    keithley.close()
    exit()

print("Exec")
keithley.write("TTLPulsedSweepBD()")

response = ""
while "SWEEP_DONE" not in response:
    try:
        response = keithley.read().strip()
        if response and "SWEEP_DONE" not in response:
            print(f"[Keithley]: {response}")
    except pyvisa.VisaIOError:
        time.sleep(0.1)

# Current setpoints are read only
voltages = keithley.query("printbuffer(1, smua.nvbuffer1.n, smua.nvbuffer1)")
keithley.close()

points = np.array([float(val) for val in voltages.split(",") if val.strip()])

plt.plot(np.linspace(0, 1, len(points)), points, )
plt.ylabel("Voltage (V)")
plt.xlabel("Time (a.u.)")
plt.show()

