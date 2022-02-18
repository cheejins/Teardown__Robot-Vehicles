-- Timers that count down constantly.
function runTimers()
    TimerRunTime(timers.gun.bullets)
    TimerRunTime(timers.gun.rockets)

    TimerRunTime(timers.aeon.primary)
    TimerRunTime(timers.aeon.secondary)
    TimerRunTime(timers.aeon.special)
end

function initTimers()

    timers = {}

    timers.gun = {
        bullets = { time = 0, rpm = regGetFloat('robot.weapon.bullet.rpm')},
        rockets = { time = 0, rpm = regGetFloat('robot.weapon.rocket.rpm')}
    }

    timers.aeon = {
        primary =   { time = 0, rpm = 130},
        secondary = { time = 0, rpm = 130},
        special =   { time = 0, rpm = 800},
    }

end
