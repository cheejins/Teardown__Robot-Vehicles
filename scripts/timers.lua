-- Timers that count down constantly.
function runTimers()
    TimerRunTime(timers.gun.bullets)
    TimerRunTime(timers.gun.rockets)
end

function initTimers()

    timers = {}

    timers.gun = { 
        bullets = { time = 0, rpm = 800 },
        rockets = { time = 0, rpm = 200 }}
end
