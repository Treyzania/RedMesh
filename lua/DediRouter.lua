args = {...}

--== PROGRAM ==--
local name = args[1]
local monitorPeri = nil

local function waiter()
    while true do os.sleep(60) end
end

function handler(data)
    
    local sender = data["sender"]
    local proto = data["protocol"]
    local msg = data["message"]
    local symbol = "?"
    
    if data["type"] == "p2p" then symbol = "P2P" end
    if data["type"] == "broadcast" then symbol = "PGT" end
    
    print("M:" .. sender .. "/" .. base64.from_base64(proto) .. "(" .. symbol .. "):" .. base64.from_base64(msg))
    
end

function monitorHandler(data)
    
    local mp = monitorPeri -- Alias
    local c = monitorPeri.isColor()
    
    term.redirect(mp)
    
    local w, h = mp.getSize()
    local x, y = term.getCursorPos()
    if (y >= h) then
        term.scroll(1)
        y = y - 1
    end
    term.setCursorPos(1, y + 1)
    
    if c then mp.setTextColor(colors.white) end
    term.write("P:")
    
    if c then mp.setTextColor(colors.red) end
    term.write(data["sender"])
    if c then mp.setTextColor(colors.gray) end
    term.write("->")
    if c then mp.setTextColor(colors.lime) end
    term.write(data["dest"])
    
    if c then mp.setTextColor(colors.green) end
    term.write(" @" .. tostring(os.day()) .. "-" .. textutils.formatTime(os.time(), true))
    
    if c then mp.setTextColor(colors.blue) end
    term.write(" ")
    term.write(base64.from_base64(data["protocol"]))
    if c then mp.setTextColor(colors.white) end
    term.write("(")
    if c then mp.setTextColor(colors.yellow) end
    term.write(string.sub(base64.from_base64(data["message"]), 1, 8))
    if c then mp.setTextColor(colors.white) end
    term.write(")")
    
    term.redirect(term.native())
    
end

-- Args check.
if #args <= 1 then
    print("Usage: DediRouter <RedMesh name> <router1> [router2 [router3[...]]]")
    error("Exiting...")
    shell.exit()
end

print("== RedMesh Network Dedicated Router ==")
print("Computer ID:    " .. os.getComputerID())
print("Computer Label: " .. os.getComputerLabel())
print("MeshNet Name:   " .. name)

os.loadAPI("redmesh")
redmesh.setVerbose(true)
redmesh.registerHandler(handler)

local monitored = false
local b = true
for i, v in ipairs(args) do
    
    if b then
        b = false
    else
        
        local first2 = string.sub(v, 1, 2)
        local after = string.sub(v, 3, -1)
        
        if first2 == "-D" then
            monitorPeri = peripheral.wrap(after)
            monitorPeri.setTextScale(0.5)
            monitorPeri.clear()
            if monitorPeri.isColor() then monitorPeri.setTextColor(colors.lightGray) end
            monitorPeri.setCursorPos(1, 1)
            monitorPeri.write("Beginning log...")
            monitored = true
        elseif first2 == "-M" then
            -- Add the sides to the list.
            redmesh.addSide(after, "*")
        else
            print("Ignoring argument \"" .. v .. "\".")
        end
        
    end
    
end

if monitored then redmesh.registerHandler(monitorHandler) end

redmesh.init(name)

print("All init complete, proceding to main...")
print("=================================================")

if pcall(waiter) then
    print("wtf? y u exit?")
    os.reboot()
else
    os.reboot()
end

