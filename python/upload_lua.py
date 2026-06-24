from typing import cast
import pyvisa
import time
from pyvisa.resources import TCPIPInstrument

file = "../lua/ttl_pulsed_sweep.lua"

script: str = ""
with open(file, "r") as ctx:
    script = ctx.read()

print(script)

rm = pyvisa.ResourceManager()
keithley: TCPIPInstrument = cast(TCPIPInstrument, rm.open_resource("TCPIP0::192.168.1.129::INSTR"))

keithley.read_termination = "\n"
keithley.read_termination = "\n"

# executes
keithley.write("TTLPulsedSweep()")

# check it
response = ""
while "SWEEP_DONE" not in response:
    try:
        response = keithley.read()
    except pyvisa.VisaIOError:
        time.sleep(0.1)
    except Exception:
        ...

data = keithley.query("printbuffer(1, smua.nvbuffer.n, smu_reading_buffer)")
points = [float(val) for val in data.split(",")]

keithley.close()

print("Done!")
