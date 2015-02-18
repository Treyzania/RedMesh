-- RedMesh v1.0
-- Author: Treyzania

-- CONFIG

local cacheTime = 0.25 -- 6 in-game hours, ~5 minutes
local savePackets = false -- DON'T ENABLE.  NYI!

local configDir = "/redmesh.cfg/" -- Make sure to have the trailing '/'.

-- END CONFIG

local ident = "__noname"
local rnProtocolName = "redmesh"
local recv = nil
local verbose = false

local recent = {}
local messageHandlers = {}
local modemSides = {}

local oldrednetreceive = nil

-- Some verbosity functions.
function setVerbose(val)
    verbose = val
    pcall(function() hypercoro.verbose = val end)
end
function vprint(text) if verbose then print(text) end end

local function savePacket(pkt)
    
    local sig = pkt["contents"]["signature"]
    local file = fs.open(configDir .. "pktlog/" .. tostring(sig) .. ".rmp", "w");
    
    file:write(textutils.serialize(pkt))
    file:close()
    
end

function rawTime()
    return os.day() + (os.time() / 24)
end

local function msgSig(str, curTime)
    
    local t = curTime or rawTime()
    
    return sha1.sha1(str .. os.getComputerID() .. t)
    
end

local function cacheSignature(sig)
    
    recent[sig] = rawTime()
    
end

local function callHandlers(data)
    
    vprint("Calling handlers...")
    
    for i, v in ipairs(messageHandlers) do
        
        local r, err = pcall(function() v(data) end)
        
        -- This feels cheaty.
        if r then
            -- Everything looks all fine and dandy.
        else
            error("\nE: on " .. tostring(v) .. ": " .. tostring(err), 1)
        end
        
    end
    
end

local function removeExpiredCaches()
    
    local t = rawTime()
    
    for k, v in pairs(recent) do
        
        if (t - v) > cacheTime then
            
            recent[k] = nil -- "Remove" it.
            
        end
        
    end
    
end

local function processable(sig)
    
    local s, err = pcall(removeExpiredCaches) -- Sometimes this errors.
    
    --print("Checking ", sig)
    
    local t = rawTime()
    
    local cacheResult = recent[sig] -- Nil if it's safe, something that's true if it's still cached.
    
    -- Update the cache.
    recent[sig] = t
    
    -- If it's nil then we're golden!
    return (type(cacheResult) == "nil")
    
end

local function pushDownwards(data)
    
    vprint("Pushing packet ", data, " to lower levels...")
    
    os.queueEvent("rednet_message", senderId, msg, mProto)
    callHandlers(data)
    
end

local function makeEnvelope(contents)
    
    local env = {}
    
    env["sender_id"] = os.getComputerID()
    env["type"] = contents["type"]
    env["contents"] = contents
    
    return env
    
end

local function makePgtPacket(dest, message, mType, proto)
    
    local t = rawTime()
    
    -- Forms the body table of the request.
    local body = {}
    body["dest"] = dest -- "*" for broadcasts.
    body["sender"] = ident
    body["sender_id"] = os.getComputerID()
    body["signature"] = msgSig(message, t)
    body["time"] = t
    body["type"] = mType
    body["protocol"] = base64.to_base64(proto)
    body["message"] = base64.to_base64(message)
    
    return body
    
end

local function repropegate(mType, data)
    
    -- Simple enough.  Should get it everywhere else.
    rednet.broadcast(textutils.serialize(makeEnvelope(data)), rnProtocolName)
    
end

function send(dest, message, proto)
    
    if not proto then error("no protocol") end
    
    -- Hopefully gets the message everywhere.
    rednet.broadcast(textutils.serialize(makeEnvelope(makePgtPacket(tostring(dest), message, "p2p", proto))), rnProtocolName)
    
end

function broadcast(message, proto)
    
    if not proto then error("no protocol") end
    
    local packet = makePgtPacket("*", message, "broadcast", proto)
    
    processable(packet["sig"])
    
    -- Hopefully gets it to everywhere, somehow.
    rednet.broadcast(textutils.serialize(makeEnvelope(packet)), rnProtocolName)
    
end

local function recvLoop()
    
    print("RedMesh loop started!")
    
    while true do
        
        local sender, msg, proto = rednet.receive(rnProtocolName, 30)
        
        local env = {}
        
        if sender then
            
            local a, b = pcall(function() env = textutils.unserialize(msg) end) -- This was buggin me for HOURS!  It's not "deserialize!"
            
            if a then -- Tries to deserialize.
                
                local mType = env["type"]
                local sender = env["sender_id"]
                local data = env["contents"]
                
                local senderId = data["sender_id"]
                local mProto = base64.from_base64(data["protocol"])
                local msg = base64.from_base64(data["message"])
                local sig = data["signature"]
                
                if savePackets then savePacket(env) end
                
                if processable(sig) then
                    
                    if mType == "p2p" then
                        
                        local dest = data["dest"]
                        --vprint("P2P packet...")
                        
                        if dest == ident then
                            --vprint("...got it!")
                            pushDownwards(data)
                        else
                            --vprint("...repropegating!")
                            repropegate("p2p", data) -- Pass it along if it isn't ours.
                        end
                        
                    end
                    
                    if mType == "broadcast" then
                        
                        --vprint("Broadcast packet!")
                        
                        pushDownwards(data)
                        repropegate("broadcast", data)
                        
                    end
                    
                end
                    
            else
                vprint("Error in de-serialization, sender is " .. tostring(sender) .. ", \"" .. b .. "\".")
            end
            
        else
            -- Nothing happens.
        end
        
    end
    
end

local function run()
    
    -- This function is just to restart the main loop if some error happens.
    
    while true do
        
        local yn, err = pcall(recvLoop)
        print("ERROR: ", err)
        
    end
    
end

-- Handlers called as "handler(data)", where data is env["contents"].
function registerHandler(handler)
    
    vprint("Added handler " .. tostring(handler) .. ".")
    
    local index = #messageHandlers + 1;
    messageHandlers[index] = handler;
    return index;
    
end

local function newrednetreceive(protocol, timeout)
    
    if not protocol then error("no protocol; string expected, got " .. type(protocol or nil)) end
    return oldrednetreceive(protocol, timeout) -- Should work as expected.
    
end

function init(id)
    
    vprint("Loading RedMesh APIs...")
    
    os.loadAPI("sha1")
    os.loadAPI("base64")
    os.loadAPI("hypercoro")
    
    hypercoro.init()
    
    vprint("Done!  Beginning internals...")
    
    textutils.deserailzie = textutils.unserialize
    
    if not fs.exists(configDir) then
        fs.makeDir(configDir) end
    if not fs.exists(configDir .. "pktlog/") then
        fs.makeDir(configDir .. "pktlog/") end
    
    -- Replace the old rednet method with the correct, better one.
    oldrednetreceive = rednet.receive
    rednet.receive = newrednetreceive
    
    ident = tostring(id)
    
    recv = hypercoro.create("redmesh.recvloop", run)
    
    vprint("RedMesh init complete!")
    vprint("READY TO ROCK AND ROLL BABY!")
    
end

function addSide(side, modemType)
    
    vprint("Adding modem on " .. side .. "(" .. modemType .. ").")
    rednet.open(side)
    modemSides[side] = modemType
    
end

-- END OF FILE
