loadscript ACWaveformSweepScript
	reset()

	-- Configuration parameters (Adjust these as needed)
	local Vrms          = 12          -- Desired RMS voltage of the sinewave
	local numCycles     = 2           -- Number of sinewave cycles to output
	local frequency     = 60          -- Frequency of the sinewave (Hz)
	local limitI        = 100e-3      -- Current limit of the output (Amps)

	-- Generate the source values
	local Vpp				= Vrms * math.sqrt(2)
	local sourceValues		= {} 
	local pointsPerCycle	= 7200 / frequency
	local numDataPoints		= pointsPerCycle * numCycles

	for i=1, numDataPoints do
		sourceValues[i]		= (Vpp * math.sin(i * 2 * math.pi / pointsPerCycle))
	end

	-- Configure the SMU ranges
	smua.reset()
	smua.source.settling		= smua.SETTLE_FAST_POLARITY
	smua.source.autorangev		= smua.AUTORANGE_OFF
	smua.source.autorangei		= smua.AUTORANGE_OFF
	smua.source.rangev			= Vpp
	smua.source.limiti			= limitI

	smua.measure.autorangev		= smua.AUTORANGE_OFF
	smua.measure.autorangei		= smua.AUTORANGE_OFF
	smua.measure.autozero		= smua.AUTOZERO_OFF
	-- Voltage will be measured on the same range as the source range
	smua.measure.rangei			= limitI
	smua.measure.nplc			= 0.001

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure the trigger model
	--============================

	-- Timer 1 controls the time between source points
	trigger.timer[1].delay = 0.15
	trigger.timer[1].passthrough = true
	trigger.timer[1].stimulus = smua.trigger.ARMED_EVENT_ID
	trigger.timer[1].count = numDataPoints - 1

	-- Configure the SMU trigger model
	smua.trigger.source.listv(sourceValues)
	smua.trigger.source.limiti		= limitI
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_HOLD
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numDataPoints
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= 0
	smua.trigger.source.action		= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2. Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end

	print("SWEEP_DONE")
endscript
