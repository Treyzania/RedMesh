-- HyperCoro v1.1
-- Author: Treyzania

--[[
    There's a few things in this API that look like they should be uncommented.
    If you think that you need them uncommented, the do so.  But don't ask me
    for help if you screw something up.  I barely understand this stuff, either.
]]

-- CONFIG

-- made ya' look!

-- END CONFIG

--== CODE ==--
local coros = {}

local nativepullevent = nil
local nativecreate = nil

verbose = true
local function vprint(text) if verbose then print(text) end end

function addCoroutine(name, coro) coros[name] = coro end
function getCoroutine(name) return coros[name] end

function removeCoroutine(name)
    local coro = coros[name]
    coros[name] = nil
    return coro
end

-- Never called locally, used as an abstraction layer.
local function coroPullEvent(filter)
    
    -- Stolen from http://www.computercraft.info/forums2/index.php?/topic/19908-run-code-in-background/, but modified to loop through a table.
    
    while true do
        
        local event = { nativepullevent() } -- Calls the native one.
        
        for k, v in pairs(coros) do
            
            if coroutine.status(v) == "suspended" then -- We to make sure it is not our function (now a coroutine) calling it.
                coroutine.resume(v, unpack(event)) -- Unpack( tbl ) returns the contents of the table.
            end
            
        end
        
        if sFilter == event[1] or not filter then -- If the event is the correct type, or there is no filter.
            return unpack(event)
        end
        
    end
    
end

function create(name, func, ...)
    
    vprint("Creating coroutine \"" .. name .. "\"...")
    
    local coro = coroutine.create(func)
    addCoroutine(name, coro)
    coroutine.resume(coro, ...)
    
    vprint("Done!")
    
    return coro
    
end

local function coroCreate_native(func)
    
    local coro = nativecreate(func)
    addCoroutine(tostring(func), coro)
    
end

function init()
    
    -- Abstract away `os.pullEvent` and `coroutine.create`.
    nativepullevent = os.pullEvent
    os.pullEvent = coroPullEvent
    --nativecreate = coroutine.create
    --coroutine.create = coroCreate_native
    
    vprint("HyperCoro initialization complete.")
    
end

function finish()
    
    os.pullEvent = nativepullevent
    --coroutine.create = nativecreate
    
    vprint("HyperCoro disengaged.")
    
end

-- END OF FILE
