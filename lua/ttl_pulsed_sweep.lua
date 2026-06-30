loadscript TTLPulsedSweep
    smua.reset()
    smua.nvbuffer1.clear()
    smua.nvbuffer1.appendmode = 1
    smua.source.func = smua.OUTPUT_DCAMPS -- I'll never forgive anyone who forgets to set their output mode

    local min = 0.5e-3
    local max = 1e-3
    local steps = 100
    local duration = 3
    local compliance_v = 10.0  -- evil
    local period = duration / steps
    local num_points = steps

    smua.trigger.source.lineari(min, max, num_points)
    smua.trigger.source.limitv = compliance_v
    smua.trigger.source.action = smua.ENABLE

    local period_timer = trigger.timer[1]
    period_timer.delay = period 
    period_timer.passthrough = true
    period_timer.count = num_points + 5
    period_timer.stimulus = smua.trigger.ARMED_EVENT_ID

    smua.trigger.source.stimulus = period_timer.EVENT_ID -- trigger measurement after set current
    smua.trigger.measure.action = smua.ENABLE 
    smua.trigger.measure.v(smua.nvbuffer1)
    smua.trigger.measure.stimulus = smua.trigger.SOURCE_COMPLETE_EVENT_ID
    
    smua.trigger.arm.count = 1
    smua.trigger.count = num_points

    -- TODO: pass 1011 to get a error-correctable edge
    digio.trigger[1].clear()
    digio.trigger[1].mode = digio.TRIG_FALLING -- or TRIG_RISING
    digio.trigger[1].pulsewidth = 0.001
    digio.trigger[1].stimulus = smua.trigger.MEASURE_COMPLETE_EVENT_ID 

    smua.source.output = smua.OUTPUT_ON -- OUTPUT_ON my beloved

    smua.trigger.initiate()
    waitcomplete()

    smua.source.output = smua.OUTPUT_OFF
    
    print("SWEEP_DONE")
endscript
