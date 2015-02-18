function doFile(name)
    
    shell.run("copy", name, "/")
    
end

print("RedMesh API Installer v1.1")
print("Working...")

shell.setDir("/disk")

doFile("redmesh")
doFile("base64")
doFile("sha1")

doFile("DediRouter")

print("Done!")

