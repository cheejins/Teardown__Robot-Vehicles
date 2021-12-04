#include "utility.lua"

-- ====================================================================================================
-- Zombie AI - by: Cheejins
-- ====================================================================================================

-- ----------------------------------------------------------------------------------------------------
-- This script handles the boid navigation for zombies.
-- ----------------------------------------------------------------------------------------------------


function initBoids()

    boidsData = {
        timer = { -- boid execution timed for performance.
            time = 0,
            rpm = 30000,
        },
        obstacles = {
            count = 0,
            positions = {},
            initDone = false,
        },
        radius = {
            align = 3,
            cohesion = 0,
            separation = 3,
            obstacle = 5,
        },
        strength = { -- Scaled boid output
            align = 0.4,
            cohesion = 1,
            separation = 0.85,
            obstacle = 0.75,
        }
    }

    boidMap = {}
    boidMap.boundsSize = 30
    boidMap.bounds = {
        min = Vec(-boidMap.boundsSize, 0, -boidMap.boundsSize),
        max = Vec(boidMap.boundsSize, 0, boidMap.boundsSize),
    }
    boidObstacles = {}
end


function computeAlignment(boid, boids)

    local boidTr = GetBodyTransform(boid)
    local boidVel = GetBodyVelocity(boid)

    local vel = Vec(0,0,0)
    local neighborCount = 0

    for i = 1, #boids do
        local otherBoid = boids[i].body
        if otherBoid ~= boid then

            local otherBoidTr = GetBodyTransform(otherBoid)
            local otherBoidVel = GetBodyVelocity(otherBoid)

            local velHigher = VecLength(boidVel) > VecLength(otherBoidVel)

            if CalcDist(boidTr.pos, otherBoidTr.pos) < boidsData.radius.align and velHigher then
                vel[1] = vel[1] + otherBoidVel[1]
                vel[3] = vel[3] + otherBoidVel[3]
                neighborCount = neighborCount + 1
                DrawLine(boidTr.pos, otherBoidTr.pos, 1,1,1,0.1)
            end

        end
    end

    if neighborCount == 0 then
        return vel
    end

    vel[2] = 0
    vel = VecDiv(vel, neighborCount)
    vel = VecNormalize(vel)

    return VecScale(vel, boidsData.strength.align)
end


function computeCohesion(boid, boids)

    local boidTr = GetBodyTransform(boid)
    local boidVel = GetBodyVelocity(boid)

    local vel = Vec(0,0,0)
    local neighborCount = 0

    for i = 1, #boids do
        if boid ~= boids[i].body then

            local otherBoidTr = GetBodyTransform(boids[i].body)

            if CalcDist(boidTr.pos, otherBoidTr.pos) < boidsData.radius.cohesion then
                vel[1] = vel[1] + otherBoidTr.pos[1]
                vel[3] = vel[3] + otherBoidTr.pos[3]
                neighborCount = neighborCount + 1
            end

        end
    end

    if neighborCount == 0 then
        return vel
    end

    vel = VecDiv(vel, neighborCount)
    vel = Vec(vel[1] - boidTr.pos[1], 0, vel[3] - boidTr.pos[3])
    vel = VecNormalize(vel)
    vel[2] = 0

    return VecScale(vel, boidsData.strength.cohesion)
end


function computeSeparation(boid, boids, targetPos, scale)

    scale = scale or 1
    local boidTr = GetBodyTransform(boid)
    local vel = Vec(0,0,0)

    local neighborCount = 0

    for i = 1, #boids do

        local otherBoidTr = GetBodyTransform(boids[i])

        boidTr[2] = 0
        otherBoidTr[2] = 0

        if CalcDist(boidTr.pos, otherBoidTr.pos) < boidsData.radius.separation then

            vel[1] = otherBoidTr.pos[1] - boidTr.pos[1]
            vel[3] = otherBoidTr.pos[3] - boidTr.pos[3]

            -- PointLight(otherBoidTr.pos, 1, 1, 0, 2)

            neighborCount = neighborCount + 1
        end

    end

    if neighborCount == 0 then
        return vel
    end

    vel[1] = -vel[1]
    vel[2] = 0
    vel[3] = -vel[3]

    return VecScale(vel, boidsData.strength.separation * scale)
end


function computeObstacles(boid)

    local boidTr = GetBodyTransform(boid)

    local vel = Vec(0,0,0)
    local neighborCount = 0

    for i = 1, #boidsData.obstacles.positions do

        local obstacle = Transform(boidsData.obstacles.positions[i])

        if CalcDist(boidTr.pos, obstacle.pos) < boidsData.radius.obstacle then
            vel[1] = obstacle.pos[1] - boidTr.pos[1]
            vel[3] = obstacle.pos[3] - boidTr.pos[3]
            neighborCount = neighborCount + 1
            DebugLine(boidTr.pos, obstacle.pos, 1, 0, 0)
            PointLight(VecAdd(obstacle.pos, Vec(0,2,0)), 1, 0, 0, 1)
        elseif CalcDist(boidTr.pos, obstacle.pos) < 1 then
            PointLight((boidTr.pos), 1, 0, 0, 1)
        end

    end

    if neighborCount == 0 then
        return vel
    end

    vel[1] = -vel[1]
    vel[2] = 0
    vel[3] = -vel[3]

    return VecScale(vel, boidsData.strength.obstacle)
end


function processBoids()
    populateObstacles()
    -- displayObstacles()
    boidsData.timer.time = boidsData.timer.time - GetTimeStep()
end


function populateObstacles()
    if boidsData.obstacles.initDone == false then
        for i = 1, boidsData.obstacles.count do
            local obstaclePos = rdmVec(-boidMap.boundsSize, boidMap.boundsSize)
            obstaclePos[1] = obstaclePos[1]
            obstaclePos[2] = 0
            obstaclePos[3] = obstaclePos[3] + 40
            table.insert(boidsData.obstacles.positions, obstaclePos)
        end
    end
    boidsData.obstacles.initDone = true
end


function displayObstacles()
    for i = 1, #boidsData.obstacles.positions do
        DebugLine(boidsData.obstacles.positions[i], VecAdd(boidsData.obstacles.positions[i], Vec(0,5,0)), 1, 0, 0)
    end
end
