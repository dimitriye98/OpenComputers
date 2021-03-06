local pipes = require("pipes")
local blinkState = false
local args = {...}

--local screen = component.list('screen')()
--for address in component.list('screen') do
--    if #component.invoke(address, 'getKeyboards') > 0 then
--        screen = address
--    end
--end

local gpu = args[1] --component.list("gpu", true)()
local w, h
if gpu then
    --component.invoke(gpu, "bind", screen)
    w, h = component.invoke(gpu, "getResolution")
    component.invoke(gpu, "setResolution", w, h)
    component.invoke(gpu, "setBackground", 0x000000)
    component.invoke(gpu, "setForeground", 0xFFFFFF)
    component.invoke(gpu, "fill", 1, 1, w, h, " ")
end
local y = 1
local x = 1

local function checkCoord()
    if x < 1 then x = 1 end
    if x > w then x = w end
    if y < 1 then y = 1 end
    if y > h then y = h end
end

local preblinkbg = 0x000000
local preblinkfg = 0x000000

local function unblink()
    if blinkState then
        blinkState = not blinkState
        local char, fg, bg = component.invoke(gpu, "get", x, y)
        preblinkbg = blinkState and bg or preblinkbg
        preblinkfg = blinkState and fg or preblinkfg
        local oribg, obpal = component.invoke(gpu, "setBackground", blinkState and 0xFFFFFF or preblinkbg)
        local orifg, ofpal = component.invoke(gpu, "setForeground", blinkState and 0x000000 or preblinkfg)
        component.invoke(gpu, "set", x, y, char  or " ")
        component.invoke(gpu, "setBackground", oribg)
        component.invoke(gpu, "setForeground", orifg)
    end
end

local function reblink()
    if not blinkState then
        blinkState = not blinkState
        local char, fg, bg = component.invoke(gpu, "get", x, y)
        preblinkbg = blinkState and bg or preblinkbg
        preblinkfg = blinkState and fg or preblinkfg
        local oribg, obpal = component.invoke(gpu, "setBackground", blinkState and 0xFFFFFF or preblinkbg)
        local orifg, ofpal = component.invoke(gpu, "setForeground", blinkState and 0x000000 or preblinkfg)
        component.invoke(gpu, "set", x, y, char  or " ")
        component.invoke(gpu, "setBackground", oribg)
        component.invoke(gpu, "setForeground", orifg)
    end
end

local scrTop = 1
local scrBot = nil

local function scroll()
    unblink()
    scrBot = scrBot or h
    x = 1
    if y == h then
        component.invoke(gpu, "copy", 1, scrTop + 1, w, scrBot - scrTop, 0, -1)
        component.invoke(gpu, "fill", 1, scrBot, w, 1, " ")
    else
        y = y + 1
    end
    reblink()
end

local printBuf = ""

local function printBuffer()
    if #printBuf < 1 then return end
    component.invoke(gpu, "set", x, y, printBuf)
    if x == w then
        scroll()
    else
        x = x + unicode.len(printBuf)
        checkCoord()
    end
    printBuf = ""
    if pipes.shouldYield() then
        os.sleep()
    end
end

local function backDelChar()
    if #printBuf > 0 then
        printBuf = unicode.sub(printBuf, 1, unicode.len(printBuf) - 1)
    else
        x = x - 1
        unblink()
        component.invoke(gpu, "set", x, y, " ")
        reblink()
    end
end

---Char handlers

local charHandlers = {}

function charHandlers.base(char)
    if char == "\n" then
        printBuffer()
        scroll()
    elseif char == "\r" then
        unblink()
        printBuffer()
        x = 1
        reblink()
    elseif char == "\t" then
        printBuf = printBuf .. "  "
    elseif char == "\b" then
        backDelChar()
    elseif char == "\x1b" then
        charHandlers.active = charHandlers.control
        charHandlers.control(char)
    elseif char:match("[%g%s]") then
        printBuf = printBuf .. char
    end
end

local mcommands = {}
local swap = false

mcommands["7"] = function()
    local fc, fp = component.invoke(gpu, "getForeground")
    local bc, bp = component.invoke(gpu, "getBackground")
    
    component.invoke(gpu, "setForeground", bc, bp)
    component.invoke(gpu, "setBackground", fc, fp)
    swap = true
end

mcommands["0"] = function()
    if swap then
        local fc, fp = component.invoke(gpu, "getForeground")
        local bc, bp = component.invoke(gpu, "getBackground")
        
        component.invoke(gpu, "setForeground", bc, bp)
        component.invoke(gpu, "setBackground", fc, fp)
    end
    swap = false
end

mcommands["1"] = function()end --Bold font
mcommands["2"] = function()end --Dim font
mcommands["3"] = function()end --Italic
mcommands["4"] = function()end --Underscore
mcommands["10"] = function()end --Select primary font (LA100)

mcommands["30"] = function()component.invoke(gpu, "setForeground", 0x000000)end
mcommands["31"] = function()component.invoke(gpu, "setForeground", 0xFF0000)end
mcommands["32"] = function()component.invoke(gpu, "setForeground", 0x00FF00)end
mcommands["33"] = function()component.invoke(gpu, "setForeground", 0xFFFF00)end
mcommands["34"] = function()component.invoke(gpu, "setForeground", 0x0000FF)end
mcommands["35"] = function()component.invoke(gpu, "setForeground", 0xFF00FF)end
mcommands["36"] = function()component.invoke(gpu, "setForeground", 0x00FFFF)end
mcommands["37"] = function()component.invoke(gpu, "setForeground", 0xFFFFFF)end

mcommands["40"] = function()component.invoke(gpu, "setBackground", 0x000000)end
mcommands["41"] = function()component.invoke(gpu, "setBackground", 0xFF0000)end
mcommands["42"] = function()component.invoke(gpu, "setBackground", 0x00FF00)end
mcommands["43"] = function()component.invoke(gpu, "setBackground", 0xFFFF00)end
mcommands["44"] = function()component.invoke(gpu, "setBackground", 0x0000FF)end
mcommands["45"] = function()component.invoke(gpu, "setBackground", 0xFF00FF)end
mcommands["46"] = function()component.invoke(gpu, "setBackground", 0x00FFFF)end
mcommands["47"] = function()component.invoke(gpu, "setBackground", 0xFFFFFF)end

mcommands["39"] = function()component.invoke(gpu, "setForeground", 0xFFFFFF)end
mcommands["49"] = function()component.invoke(gpu, "setBackground", 0x000000)end

local lcommands = {}

lcommands["4"] = function()end --Reset to replacement mode

local ncommands = {}

ncommands["6"] = function()io.write("\x1b[" .. math.floor(y) .. ";" .. math.floor(x) .. "R")end

local commandMode = ""
local commandBuf = ""
local commandList = {}

--TODO \x1b[C -- reset term to initial state
--TODO: REFACTOR INTO FUNCTION ARRAY

--TODO: p9-codes:
-- \x1b9[H];[W]R - set resolution
-- \x1b9[Row];[Col];[Height];[Width]F -- fill
-- \x1b9[Row];[Col];[Height];[Width];[Dest Row];[Dest Col]c -- copy

--Add fake gpu component for compat(?)

function charHandlers.control(char)
    if char == "\x1b" then
        commandList = {}
        commandBuf = ""
        commandMode = ""
        unblink()
        return
    elseif char == "[" then
        if commandMode ~= "" or commandBuf ~= "" then
            charHandlers.active = charHandlers.base
            reblink()
            return
        end
        commandMode = "["
        return
    elseif char == "(" then
        if commandMode ~= "" or commandBuf ~= "" then
            charHandlers.active = charHandlers.base
            reblink()
            return
        end
        commandMode = "("
        return
    elseif char == "9" and commandMode == "" and commandBuf == "" then
        commandMode = "9"
        return
    elseif char == ";" then
        commandList[#commandList + 1] = commandBuf
        commandBuf = ""
        return
    elseif char == "m" then
        commandList[#commandList + 1] = commandBuf
        if not commandList[1] or commandList[1] == "" then
            commandList[1] = "0"
        end
        for _, command in ipairs(commandList) do
            if not mcommands[command] then
                pipes.log("Unknown escape code: " .. tostring(command))
                break
            end
            mcommands[command]()
        end
    elseif char == "l" then
        commandList[#commandList + 1] = commandBuf
        if not commandList[1] or commandList[1] == "" then
            commandList[1] = "0"
        end
        for _, command in ipairs(commandList) do
            if not lcommands[command] then
                pipes.log("Unknown escape code: " .. tostring(command))
                break
            end
            lcommands[command]()
        end
    elseif char == "n" then
        commandList[#commandList + 1] = commandBuf
        if not commandList[1] or commandList[1] == "" then
            commandList[1] = "0"
        end
        for _, command in ipairs(commandList) do
            if not ncommands[command] then
                pipes.log("Unknown escape code: " .. tostring(command))
                break
            end
            ncommands[command]()
        end
    elseif char == "d" then 
        commandList[#commandList + 1] = commandBuf
        local n = tonumber(commandList[1]) or 1
        y = math.max(n, 1)
        checkCoord()
    elseif char == "R" and commandMode == "9" then --set resolution
        commandList[#commandList + 1] = commandBuf
        local nh, nw = tonumber(commandList[1]) or h, tonumber(commandList[2]) or w
        if x > nw then x = math.max(nw, 1) end
        if y > nh then y = math.max(nw, 1) end
        if component.invoke(gpu, "setResolution", nw, nh) then
            w = nw
            h = nh
        end
    elseif char == "r" then --set scroll region
        commandList[#commandList + 1] = commandBuf
        local nt, nb = tonumber(commandList[1]) or 1, tonumber(commandList[2]) or h
        scrTop = nt
        scrBot = nb
    elseif char == "H" or char == "f" then --set pos
        commandList[#commandList + 1] = commandBuf
        local ny, nx = tonumber(commandList[1]), tonumber(commandList[2])
        x = math.min(nx or 1, w)
        y = math.min(ny or 1, h)
        checkCoord()
    elseif char == "A" then --move up
        commandList[#commandList + 1] = commandBuf
        local n = tonumber(commandList[1]) or 1
        y = y - n
        checkCoord()
    elseif char == "B" then --move down
        if commandMode == "(" then
            charHandlers.active = charHandlers.base
            reblink()
            return
        end
        commandList[#commandList + 1] = commandBuf
        local n = tonumber(commandList[1]) or 1
        y = math.max(y - n, 1)
        checkCoord()
    elseif char == "C" then --move fwd
        commandList[#commandList + 1] = commandBuf
        local n = tonumber(commandList[1]) or 1
        x = x + n
        checkCoord()
    elseif char == "D" then --move back
        commandList[#commandList + 1] = commandBuf
        local n = tonumber(commandList[1]) or 1
        x = math.max(x - n, 1)
        checkCoord()
    elseif char == "G" then --Cursor Horizontal position Absolute
        commandList[#commandList + 1] = commandBuf
        x = tonumber(commandList[1]) or 1
        checkCoord()
    elseif char == "J" then --clear
        commandList[#commandList + 1] = commandBuf
        if commandList[1] == "2" then
            component.invoke(gpu, "fill", 1, 1, w, h, " ")
            x, y = 1, 1
        end
    elseif char == "K" then --Erase to end of line
        commandList[#commandList + 1] = commandBuf
        component.invoke(gpu, "fill", x, y, w - x, 1, " ")
    elseif char == "X" then --Erase next chars
        commandList[#commandList + 1] = commandBuf
        component.invoke(gpu, "fill", x, y, tonumber(commandList[1]) or 1, 1, " ")
    else
        commandBuf = commandBuf .. char
        return
    end
    charHandlers.active = charHandlers.base
    reblink()
    commandList = {}
    commandBuf = ""
    commandMode = ""
end

---Char handler end

charHandlers.active = charHandlers.base

local function _print(msg)
    if gpu then
        
        for char in msg:gmatch(".") do
            charHandlers.active(char)
        end
        
        printBuffer()
    end
end

pipes.setTimer(function()
    blinkState = not blinkState
    local char, fg, bg = component.invoke(gpu, "get", x, y)
    preblinkbg = blinkState and bg or preblinkbg
    preblinkfg = blinkState and fg or preblinkfg
    local oribg, obpal = component.invoke(gpu, "setBackground", blinkState and 0xFFFFFF or preblinkbg)
    local orifg, ofpal = component.invoke(gpu, "setForeground", blinkState and 0x000000 or preblinkfg)
    component.invoke(gpu, "set", x, y, char  or " ")
    component.invoke(gpu, "setBackground", oribg)
    component.invoke(gpu, "setForeground", orifg)
end, 0.5)

while true do
    local data = io.read(1)
    if io.input().remaining() > 0 then
        data = data .. io.read(io.input().remaining())
    end
    unblink()
    _print(data)
end
