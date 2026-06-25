loadscript TTLPulsedSweep
    smua.reset()
    smua.nvbuffer1.clear()
    smua.nvbuffer1.appendmode = 1
    smua.source.func = smua.OUTPUT_DCAMPS -- I'll never forgive anyone who forgets to set their output mode

    local min = 0.5e-3
    local max = 1e-3
    local steps = 1000

    local duration = 30
    local compliance_v = 10.0  -- evil; don't exceed 10V
    local hold_duration = 0.5 -- seconds; note 5-10us uncertainty

    local period = duration / steps
    local num_points = steps + 1 

    local steps_h = math.floor(hold_duration / period) -- hold steps count
    local steps_rf = math.floor((steps - steps_h) / 2) -- rise/fall steps count (both equal)

    -- Generate the waveform
    local points = {}
    for i = 0, steps_rf do -- rising
        points[#points+1] = min + (i * (max-min)/steps_rf)
    end
    for i = 0, steps_h do -- hold
        points[#points+1] = max
    end
    for i = 0, steps_rf do -- falling
        points[#points+1] = max - (i * (max-min)/steps_rf)
    end

    -- Rising sweep
    smua.trigger.source.listi(points)
    smua.trigger.source.limitv = compliance_v
    smua.trigger.source.action = smua.ENABLE
    smua.trigger.count = #points

    trigger.timer[1].delay = period 
    trigger.timer[1].count = num_points - 1 
    trigger.timer[1].stimulus = smua.trigger.ARMED_EVENT_ID

    smua.trigger.source.stimulus = trigger.timer[1].EVENT_ID -- wait for timer 1 before changing output
    smua.trigger.measure.action = smua.ENABLE 
    smua.trigger.measure.v(smua.nvbuffer1)
    smua.trigger.measure.stimulus = smua.trigger.SOURCE_COMPLETE_EVENT_ID -- wait for ramp to finish before measuring

    -- TODO: pass 1011 to get a error-correctable edge
    digio.trigger[1].clear()
    digio.trigger[1].mode = digio.TRIG_FALLING -- or TRIG_RISING
    digio.trigger[1].pulsewidth = 0.001
    digio.trigger[1].stimulus = smua.trigger.MEASURE_COMPLETE_EVENT_ID 

    smua.source.output = smua.OUTPUT_ON -- OUTPUT_ON my beloved

    smua.trigger.initiate()
    waitcomplete()

    -- Finish
    smua.source.output = smua.OUTPUT_OFF
    print("SWEEP_DONE")
endscript
