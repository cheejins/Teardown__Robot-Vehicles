-- Timers that count down constantly.
function runTimers()
    TimerRunTime(timers.gun.bullets)
    TimerRunTime(timers.gun.rockets)
end

function initTimers()

    timers = {}

    timers.gun = {
        bullets = { time = 0, rpm = regGetFloat('robot.weapon.bullet.rpm') },
        rockets = { time = 0, rpm = regGetFloat('robot.weapon.rocket.rpm') }}
end
