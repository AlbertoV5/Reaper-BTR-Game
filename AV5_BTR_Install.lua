local info = debug.getinfo(1,'S')
local scriptPath = info.source:match[[^@?(.*[\\/])[^\\/]-$]]

reaper.SetExtState("BTR", "libPath", scriptPath, true)