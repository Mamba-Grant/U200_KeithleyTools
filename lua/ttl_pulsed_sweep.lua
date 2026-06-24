loadscript TTLPulsedSweep
    smua.reset()
    smua.nvbuffer1.clear()
    smua.nvbuffer1.appendmode = 1 -- don't overwite buffer!

    local min = 0.5e-3
    local max = 1e-3
    local steps = 100
    local duration = 3 

    local period = duration / steps

    smua.trigger.source.lineari(min, max, points)
    smua.trigger.source.action = smua.ENABLE

    -- make the steps sequential
    trigger.timer[1].delay = period 
    trigger.timer[1].count = steps-1
    trigger.timer[1].stimulus = smua.trigger.ARMED_EVENT_ID

    -- step after each timer trigger
    smua.trigger.source.stimulus = trigger.timer[1].EVENT_ID

    -- define measurement trigger
    smua.trigger.measure.action = smua.ENABLE 
    smua.trigger.measure.v(smua.nvbuffer1)
    smua.trigger.measure.stimulus = smua.trigger.SOURCE_COMPLETE_EVENT_ID
    smua.trigger.arm.count = 1
    smua.trigger.count = points

    -- ttl signal
    digio.trigger[1].mode = digio.TRIG_EITHER
    digio.trigger[1].pulsewidth = 0.001
    digio.trigger[1].stimulus = smua.trigger.MEASURE_COMPLETE_EVENT_ID -- pulse fired following each step

    -- exec
    smua.source.output = smua.OUTPUT_ON
    smua.trigger.initiate()
    waitcomplete()
    smua.source.output = smua.OUTPUT_OFF
endscript
