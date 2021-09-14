RaceController = RaceController or {}
RaceController.racers = {}
RaceController.racerCount = 0
RaceController.running = false
dofile("./addons/racecontroller/utils.lua")

RaceController.readCfg()

local f = io.open("./config.json")
RaceController.currentMap = RaceController.splitString(decode_json(f:read("*all")).map, "/")[2]
f:close()

hooks.register("OnStdIn", "consoleControl", function(input)
    local cmd = RaceController.splitString(input)

    if cmd[1] == "/reloadcfg" then
        RaceController.readCfg()
    end

    if cmd[1] == "/writecfg" then
        RaceController.writeCfg()
    end

    if cmd[1] == "/rcpromote" and cmd[2] then
        local ply = RaceController.findPlayerByName(cmd[2])

        if ply then
            if RaceController.cfg.admins[ply:getSecret()] then
                RaceController.print("Player " .. ply:getName() .. " is already admin")
            else
                RaceController.cfg.admins[ply:getSecret()] = true
                RaceController.print("Promoted " .. ply:getName() .. " to admin")
            end
        else
            RaceController.print("Player not found")
        end
    end

    if cmd[1] == "/rcdemote" and cmd[2] then
        local ply = RaceController.findPlayerByName(cmd[2])

        if ply then
            if not RaceController.cfg.admins[ply:getSecret()] then
                RaceController.print("Player " .. ply:getName() .. " is not admin")
            else
                RaceController.cfg.admins[ply:getSecret()] = nil
                RaceController.print("Demoted " .. ply:getName() .. " from admin")
            end
        else
            RaceController.print("Player not found")
        end
    end
end)

hooks.register("OnChat", "chatControl", function(clientID, message)
    if string.sub(message, 1, 1) ~= "/" then return end
    if not RaceController.isAdmin(connections[clientID]) then return end
    local cmd = RaceController.splitString(message)
    local caller = connections[clientID]
    local callerPos

    --Required due to bug
    --https://github.com/TheHellBox/KISS-multiplayer/issues/104
    if not pcall(function()
        callerPos = vehicles[caller:getCurrentVehicle()]:getTransform():getPosition()
    end) then
        RaceController.msg(caller, "WARNING: Your vehicle object is nil! Spawn a new vehicle before running any commands!")

        return ""
    end

    if cmd[1] == "/add" then
        local ply = RaceController.findPlayerByName(cmd[2])

        if not cmd[2] or not ply then
            RaceController.msg(caller, "Player not found")
        elseif RaceController.racers[ply:getID()] then
            RaceController.msg(caller, "Player " .. ply:getName() .. " already added")
        elseif not vehicles[ply:getCurrentVehicle()] then
            RaceController.msg(caller, "WARNING: Player " .. ply:getName() .. " has nil vehicle!")
        else
            RaceController.addRacer(ply:getID())
            RaceController.msg(caller, "Added player " .. ply:getName() .. " in vehicle " .. vehicles[ply:getCurrentVehicle()]:getData():getName())
            RaceController.racerCount = RaceController.racerCount + 1
        end
    end

    if cmd[1] == "/remove" then
        local ply = RaceController.findPlayerByName(cmd[2])

        if not cmd[2] or not ply then
            RaceController.msg(caller, "Player not found")
        else
            if RaceController.racers[ply:getID()] then
                RaceController.removeRacer(ply:getID())
                RaceController.msg(caller, "Removed player " .. ply:getName())
                RaceController.racerCount = RaceController.racerCount - 1
            else
                RaceController.msg(caller, "Player not added")
            end
        end
    end

    if cmd[1] == "/reloadcfg" then
        RaceController.readCfg()
        RaceController.msg(caller, "Read configuration file successfully")
    end

    if cmd[1] == "/writecfg" then
        RaceController.writeCfg()
        RaceController.msg(caller, "Wrote configuration file successfully")
    end

    if cmd[1] == "/resetcfg" then
        RaceController.loadDefaultCfg()
        RaceController.msg(caller, "Reset active configuration to default - /writecfg to save")
    end

    if cmd[1] == "/p1" then
        if not RaceController.cfg.linePositions[RaceController.currentMap] then
            RaceController.cfg.linePositions[RaceController.currentMap] = {}
        end

        RaceController.cfg.linePositions[RaceController.currentMap].x1 = math.floor(callerPos[1] * 10) / 10
        RaceController.cfg.linePositions[RaceController.currentMap].y1 = math.floor(callerPos[2] * 10) / 10
        RaceController.msg(caller, "Set position 1 to (" .. RaceController.cfg.linePositions[RaceController.currentMap].x1 .. ", " .. RaceController.cfg.linePositions[RaceController.currentMap].y1 .. ")")
    end

    if cmd[1] == "/p2" then
        if not RaceController.cfg.linePositions[RaceController.currentMap] then
            RaceController.cfg.linePositions[RaceController.currentMap] = {}
        end

        RaceController.cfg.linePositions[RaceController.currentMap].x2 = math.floor(callerPos[1] * 10) / 10
        RaceController.cfg.linePositions[RaceController.currentMap].y2 = math.floor(callerPos[2] * 10) / 10
        RaceController.msg(caller, "Set position 2 to (" .. RaceController.cfg.linePositions[RaceController.currentMap].x2 .. ", " .. RaceController.cfg.linePositions[RaceController.currentMap].y2 .. ")")
    end

    if cmd[1] == "/cfg" and cmd[2] then
        if not RaceController.cfg[cmd[2]] then
            RaceController.msg(caller, "Configuration option not found")
        else
            if not cmd[3] then
                if type(RaceController.cfg[cmd[2]]) == "number" or type(RaceController.cfg[cmd[2]]) == "string" then
                    RaceController.msg(caller, cmd[2] .. " == " .. RaceController.cfg[cmd[2]])
                else
                    RaceController.msg(caller, "Can only display string or number configuration settings")
                end
            else
                local setting = tonumber(cmd[3])

                if not setting or setting < 0 then
                    RaceController.msg(caller, "Configuration option must be a valid positive number")
                else
                    RaceController.cfg[cmd[2]] = setting
                    RaceController.msg(caller, "'" .. cmd[2] .. "' set to " .. cmd[3])
                end
            end
        end
    end

    if cmd[1] == "/start" then
        if RaceController.tableEmpty(RaceController.racers) then
            RaceController.msg(caller, "No players added!")

            return ""
        end

        if not RaceController.cfg.linePositions[RaceController.currentMap] or not RaceController.cfg.linePositions[RaceController.currentMap].x1 or not RaceController.cfg.linePositions[RaceController.currentMap].x2 then
            RaceController.msg(caller, "No finish line defined for this map!")

            return ""
        end

        local n = 5

        RaceController.timer("countdown", 1, 6, function()
            if n > 0 then
                RaceController.broadcast("Race starting in " .. n)
            else
                RaceController.broadcast("GO!")
                RaceController.running = true
                RaceController.startTime = os.clock()

                for _, racerData in pairs(RaceController.racers) do
                    racerData.lastLapClock = os.clock()
                end
            end

            n = n - 1
        end)
    end

    if cmd[1] == "/reset" then
        RaceController.running = false
        RaceController.racers = {}
        RaceController.racerCount = 0
        RaceController.timers = {}
        RaceController.broadcast("Script reset")
    end

    return ""
end)

local lastNilVehicleWarn = os.clock()

--RaceController.timer("interval", 0.1, 0, function()
hooks.register("Tick", "interval", function()
    if not RaceController.running then return end

    for racerID, racerData in pairs(RaceController.racers) do
        if vehicles[connections[racerID]:getCurrentVehicle()] then
            local racer = connections[racerID]
            local vehiclePos = vehicles[racer:getCurrentVehicle()]:getTransform():getPosition()
            local linePos = RaceController.cfg.linePositions[RaceController.currentMap]
            local distToFinish = RaceController.pointToLineDist(vehiclePos[1], vehiclePos[2], linePos.x1, linePos.y1, linePos.x2, linePos.y2)

            if distToFinish < RaceController.cfg.finishLineWidth and os.clock() - racerData.lastLapClock > RaceController.cfg.minLapTime and racerData.lap <= RaceController.cfg.laps then
                racerData.lap = racerData.lap + 1

                if racerData.lap <= RaceController.cfg.laps then
                    RaceController.broadcast(racer:getName() .. " is on lap " .. racerData.lap)
                end

                racerData.lastLapTime = os.clock() - racerData.lastLapClock

                if racerData.lastLapTime < racerData.fastestLap then
                    racerData.fastestLap = racerData.lastLapTime
                end

                racerData.lastLapClock = os.clock()

                if racerData.lap > RaceController.cfg.laps then
                    local overall = RaceController.secondsToClock(os.clock() - RaceController.startTime)
                    local fastest = RaceController.secondsToClock(racerData.fastestLap)
                    RaceController.racerCount = RaceController.racerCount - 1
                    RaceController.broadcast(racer:getName() .. " has finished with an overall time of " .. overall .. " and a fastest lap of " .. fastest)

                    if RaceController.racerCount == 0 then
                        RaceController.broadcast("Race finished!")
                        RaceController.running = 0
                        RaceController.racers = {}
                    end
                end
            end
        elseif os.clock() - lastNilVehicleWarn > 10 then
            RaceController.broadcast("WARNING: " .. connections[racerID]:getName() .. " has nil vehicle! Laps will not be counted - reload your vehicle!")
            lastNilVehicleWarn = os.clock()
        end
    end
end)

RaceController.print("Race controller loaded!")
