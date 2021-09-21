function RaceController.print(...)
    print("[RaceController] " .. ...)
end

function RaceController.msg(ply, ...)
    ply:sendChatMessage("[RaceController] " .. table.concat({...}, " "))
end

function RaceController.broadcast(...)
    send_message_broadcast("[RaceController] " .. table.concat({...}, " "))
end

function RaceController.writeCfg()
    local cfgFile = io.open("./addons/racecontroller/config.json", "w")
    cfgFile:write(encode_json_pretty(RaceController.cfg))
    cfgFile:close()

    RaceController.print("Successfully wrote configuration")
end

function RaceController.loadDefaultCfg()
    RaceController.cfg = {
        laps = 3,
        minLapTime = 10,
        finishLineWidth = 2,
        linePositions = {},
        admins = {}
    }

    RaceController.print("Default configuration loaded")
end

function RaceController.readCfg()
    local f = io.open("./addons/racecontroller/config.json", "r")

    if not f then
        RaceController.loadDefaultCfg()
        RaceController.writeCfg()
        RaceController.print("Configuration file not found, new one created")

        return
    end

    local cfg = decode_json(f:read("*all"))

    if cfg then
        RaceController.cfg = cfg
        RaceController.print("Loaded configuration file")
    else
        RaceController.loadDefaultCfg()
        RaceController.print("Configuration invalid! Fix or delete existing configuration and type reloadcfg in the console")
    end

    f:close()
end

function RaceController.addRacer(ply)
    RaceController.racers[ply] = {
        lap = 1,
        lastLapTime = 0,
        lastLapClock = 0, --os.clock() at which the last lap was completed
        fastestLap = math.huge
    }
end

function RaceController.removeRacer(ply)
    RaceController.racers[ply] = nil
end

--https://stackoverflow.com/a/58411671
local function round(n)
    return n + (2 ^ 52 + 2 ^ 51) - (2 ^ 52 + 2 ^ 51)
end

function RaceController.secondsToClock(seconds)
    local neg = seconds < 0
    seconds = math.abs(seconds)
    local hours = string.format("%02.f", math.floor(seconds / 3600))
    local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
    local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))
    local milisecs = string.format("%02.f", round((seconds % 1) * 100))

    return (neg and "-" or "") .. mins .. ":" .. secs .. "." .. milisecs
end

function RaceController.isAdmin(ply)
    return RaceController.cfg.admins[ply:getSecret()] and true or false
end

--Determines the distance between a point and a line segment - used for the start/finish line
--https://stackoverflow.com/a/6853926
function RaceController.pointToLineDist(x, y, x1, y1, x2, y2)
    local A = x - x1
    local B = y - y1
    local C = x2 - x1
    local D = y2 - y1
    local dot = A * C + B * D
    local len_sq = C * C + D * D
    local param = -1

    --in case of 0 length line
    if len_sq ~= 0 then
        param = dot / len_sq
    end

    local xx
    local yy

    if param < 0 then
        xx = x1
        yy = y1
    elseif param > 1 then
        xx = x2
        yy = y2
    else
        xx = x1 + param * C
        yy = y1 + param * D
    end

    local dx = x - xx
    local dy = y - yy

    return math.sqrt(dx * dx + dy * dy)
end

function RaceController.splitString(input, sep)
    sep = sep or "%s"
    local t = {}

    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end

    return t
end

--Returns a player connection object when given a full or partial name, not case sensitive
function RaceController.findPlayerByName(name)
    if not name then return end

    for _, v in pairs(connections) do
        if string.find(string.lower(v:getName()), string.lower(name), nil, true) then return v end
    end
end

function RaceController.playerHasValidVehicle(ply)
    return vehicles[ply:getCurrentVehicle()] ~= nil
end

function RaceController.tableEmpty(tbl)
    return next(tbl) == nil
end

RaceController.timers = {}

function RaceController.timer(id, delay, reps, func)
    RaceController.timers[id] = {
        id = id,
        delay = delay,
        repsLeft = reps == 0 and math.huge or reps,
        func = func,
        lastRun = os.clock()
    }
end

local timersMarkedForRemoval = {}

hooks.register("Tick", "timerController", function()
    for _, t in pairs(RaceController.timers) do
        if os.clock() > t.lastRun + t.delay then
            t.func()
            t.lastRun = os.clock()
            t.repsLeft = t.repsLeft - 1

            if t.repsLeft == 0 then
                table.insert(timersMarkedForRemoval, t.id)
            end
        end
    end

    for _, v in pairs(timersMarkedForRemoval) do
        RaceController.timers[v] = nil
    end

    timersMarkedForRemoval = {}
end)

RaceController.print("Utils loaded!")