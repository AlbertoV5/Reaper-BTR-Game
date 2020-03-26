local BTR_MAP = {};

--[[
Script: Beat the Reaper - Load Maps

Description: 

Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]

local function GETOS()
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		return "\\"
	else
		return "/"
	end
end

function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
    	--reaper.ShowConsoleMsg(tostring(filename).."\n")
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

function BTR_MAP.ReadFile()
	projectPath = reaper.GetProjectPath("")
	--reaper.ShowConsoleMsg(tostring(projectPath).."\n")
	allFiles = scandir(projectPath)
	for i = 1, #allFiles do
		if string.find(allFiles[i],".json") ~= nil then
			return projectPath..GETOS()..allFiles[i]
		end
	end
	return nil
end

function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

function BTR_MAP.ReadMap()
	jsonFile = BTR_MAP.ReadFile()
	if jsonFile == nil then
		reaper.MB("NO .JSON FILE FOUND","AV5",0)
		return nil
	else
		--reaper.ShowConsoleMsg(tostring(jsonFile))
		lines2 = {}
		for line in io.lines(jsonFile) do
			table.insert(lines2,tostring(line))
			--reaper.ShowConsoleMsg(tostring(line))
		end
		
		decodedJson = {}
		bar_flag = 0
		itemCount = 0
		for i = 1, #lines2 do
			line_ = lines2[i]:gsub('\t', '')
			if string.match(line_,"Item") ~= nil then
				itemCount = itemCount + 1
				item_num = itemCount
				decodedJson[item_num] = {}
			end
			if string.match(line_,"Beat") ~= nil then
				beat_num = string.gsub(mysplit(line_,":")[2],",","")
				beat_num = tonumber(beat_num)
				table.insert(decodedJson[item_num],beat_num)
			end
			if string.match(line_,"Track") ~= nil then
				track_num = string.gsub(mysplit(line_,":")[2],",","")
				track_num = tonumber(track_num)
				table.insert(decodedJson[item_num],track_num)
			end
			if string.match(line_,"Length") ~= nil then
				beat_len = string.gsub(mysplit(line_,":")[2],",","")
				beat_len = tonumber(beat_len)
				table.insert(decodedJson[item_num],beat_len)
			end
		end
		return decodedJson
	end
end


return BTR_MAP;


