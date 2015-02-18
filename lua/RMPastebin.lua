
local function install(key, filename)
    
    print("PB -> " .. filename)
    shell.run("pastebin get", key, filename)
    
end

print("== RedMesh Pastebin Installer v1.0 ==")
textutils.slowPrint("Installing RedMesh v1.0 + dependencies...")

-- The majority of the program...
install("asdfasdf", "redmesh")
install("asdfsdf", "hypercoro")
install("asdfrsdAFx", "base64")
install("asdfaeasDC", "sha1")

textutils.slowPrint("Done installing!")
textutils.slowPrint("Be sure to read the documentation!")

-- *I'm all about that slow-slow-slow-slow-slowPrint, no fastPrint.*
