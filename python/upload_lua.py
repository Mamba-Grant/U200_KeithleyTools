# Bug: does not terminate right

from typing import cast
import pyvisa
import time
from pyvisa.resources import TCPIPInstrument

file = "../lua/ttl_pulsed_sweep.lua"

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
keithley.write("TTLPulsedSweep()")

# Block safely on the instrument execution loop
response = ""
while "SWEEP_DONE" not in response:
    try:
        response = keithley.read().strip()
        if response and "SWEEP_DONE" not in response:
            print(f"[Keithley]: {response}")
    except pyvisa.VisaIOError:
        # Prevents Python host from crashing while waiting for a long 3s sweep
        time.sleep(0.1)

# # Safely extract your data array back to host memory
# print("Retrieving measurement data...")
# data = keithley.query("printbuffer(1, smua.nvbuffer1.n, smua.nvbuffer1)")
# points = [float(val) for val in data.split(",") if val.strip()]
# print(f"Retrieved {len(points)} points.")

keithley.close()
