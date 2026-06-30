loadscript TTLPulsedSweepBD
	-- Configuration parameters
	local min = 0.5e-3 -- A
	local max = 1e-3 -- A
	local steps = 300
	local duration = 30       
	local compliance_v = 10.0
	local hold_duration = 1  

	-- Waveform
	local period = duration / steps
	local steps_h = math.floor(hold_duration / period)
	local steps_rf = math.floor((steps - steps_h) / 2)
	local cycles = 3 -- each with steps

	local sourceValues  = {}
	for c = 1, cycles do
		for i = 1, steps_rf do -- rising
		    sourceValues[table.getn(sourceValues) + 1] = min + (i * (max - min) / steps_rf)
		end
		for i = 1, steps_h do -- hold
		    sourceValues[table.getn(sourceValues) + 1] = max
		end
		for i = 1, steps_rf do -- falling
		    sourceValues[table.getn(sourceValues) + 1] = max - (i * (max - min) / steps_rf)
		end
	end

	local numDataPoints = table.getn(sourceValues)

	-- Configure the SMU Ranges & Modes
	smua.reset()
	smua.source.func            = smua.OUTPUT_DCAMPS -- Always set output mode!
	smua.source.settling        = smua.SETTLE_FAST_POLARITY
	smua.source.autorangev      = smua.AUTORANGE_OFF
	smua.source.autorangei      = smua.AUTORANGE_OFF
	smua.source.rangei          = max
	smua.source.limitv          = compliance_v

	smua.measure.autorangev     = smua.AUTORANGE_OFF
	smua.measure.autorangei     = smua.AUTORANGE_OFF
	smua.measure.autozero       = smua.AUTOZERO_OFF
	smua.measure.rangev         = compliance_v
	smua.measure.nplc           = 0.01

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps = 1
	smua.nvbuffer1.appendmode   = 1

	-- Configure the Hardware Trigger Model
	--======================================

	-- Timer 1 spaces out points evenly to finish within the specified duration
	trigger.timer[1].delay       = (duration / numDataPoints)
	trigger.timer[1].passthrough = true
	trigger.timer[1].stimulus    = smua.trigger.ARMED_EVENT_ID
	trigger.timer[1].count       = numDataPoints - 1

	-- Configure the SMU Trigger Loop
	smua.trigger.source.listi(sourceValues)
	smua.trigger.source.limitv   = compliance_v
	smua.trigger.source.action   = smua.ENABLE
	smua.trigger.measure.action  = smua.ENABLE
	smua.trigger.measure.v(smua.nvbuffer1)

	smua.trigger.endpulse.action = smua.SOURCE_HOLD
	smua.trigger.endsweep.action = smua.SOURCE_IDLE
	smua.trigger.count           = numDataPoints -- Must equal array size
	smua.trigger.arm.count       = 1
	smua.trigger.arm.stimulus    = 0
	smua.trigger.source.stimulus = trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus = smua.trigger.SOURCE_COMPLETE_EVENT_ID
	smua.trigger.endpulse.stimulus = 0

	-- Digital I/O Synchronization Edge Trigger
	digio.trigger[1].clear()
	digio.trigger[1].mode        = digio.TRIG_FALLING
	digio.trigger[1].pulsewidth  = 0.001
	digio.trigger[1].stimulus    = smua.trigger.MEASURE_COMPLETE_EVENT_ID

	-- Execute the Test Sequence
	smua.source.output           = smua.OUTPUT_ON
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output           = smua.OUTPUT_OFF

	-- Print the collected data back to the console
	print("Time\tVoltage")
	for x = 1, smua.nvbuffer1.n do
	print(smua.nvbuffer1.timestamps[x], smua.nvbuffer1[x])
	end

	print("SWEEP_DONE")
endscript
