
bpm = reaper.Master_GetTempo()
--Constants
incluyeProjectName = true

beatMult = 1
BEAT = 60/bpm*beatMult --Beat duration depending on BPM
tkp = " "
countDown = 1
holding_elapsed = 0
max_holding_time = 1
beatBuffer = BEAT*countDown
beatCounter = 1
guideTrack = 0
projectGrid = 0.25

enableDebug = false
--[[
Script: Beat the Reaper - Mapping Editor

Description: 

V0.1

Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]

--Index is bar, first number is beat, second is track 
j_bar_list = {
	{{2,1},{4,3}}, -- In bar 1, there are 2 items. First is in beat 2 and track 1, second in beat 4 and track 3
	{{3,2}}} --In bar 2, there is 1 item. Beat 3 and track 2.

local function GETOS()
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		return "\\"
	else
		return "/"
	end
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function SaveAllItemsToList()

	local firstItem = reaper.GetTrackMediaItem(reaper.GetTrack(0, 0), 0)
	local beatZero = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION")/BEAT

	local itemList = {}
	for i = 1, reaper.CountMediaItems(0) do
		item = reaper.GetMediaItem(0, i-1)
		itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")/BEAT - beatZero + 1
		itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")/BEAT
		track = reaper.GetMediaItem_Track(item)
		track_num = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

		if track_num > 1 and track_num < 4 then
			combo = {itemPos,track_num-1,itemLen}
			table.insert(itemList,combo)
		end
	end

	local sortedList = {}
	for k,v in spairs(itemList, function(t,a,b) return t[b][1] > t[a][1] end) do
    	table.insert(sortedList,{v[1],v[2],v[3]})
	end

	if enableDebug == true then
		for i = 1, #sortedList do
			reaper.ShowConsoleMsg("Beat: "..tostring(sortedList[i][1]).."\n")
			reaper.ShowConsoleMsg("Track: "..tostring(sortedList[i][2]).."\n")
			reaper.ShowConsoleMsg("Length: "..tostring(sortedList[i][3]).."\n")
			reaper.ShowConsoleMsg("\n")
		end
	end
	return sortedList
end

local function SaveToJson()
	pathToWrite = reaper.GetProjectPath("")

	filename = "mapping"
	if incluyeProjectName == true then 
		filename = GETOS()..filename.."_"..reaper.GetProjectName(0, "")
	end

	j_beat_list = SaveAllItemsToList()

	jsonFile = '{'
	for i = 1, #j_beat_list do			
		if j_beat_list ~= nil then
			j_beat = j_beat_list[i][1]
			j_beat_track = j_beat_list[i][2]
			j_beat_len = j_beat_list[i][3]
			jsonFile = jsonFile..
				'\n\t"Item":'..'{'..
				'\n\t\t"Beat":'..tostring(j_beat)..","..
				'\n\t\t"Track":'..tostring(j_beat_track)..","..
				'\n\t\t"Length":'..tostring(j_beat_len)..
				'\n\t\t}'
			if i < #j_beat_list then
				jsonFile = jsonFile..','
			end
		end
	end
	jsonFile = jsonFile..'\n}'
	filename = string.gsub(filename, ".RPP", "")
	file = io.open(pathToWrite..filename..".json","w+")
	file:write(jsonFile)
	file:close()
	reaper.MB("Project was Saved.","AV5",0)
end


local function CreateItem(track_id,itemDuration)
	local track = reaper.GetTrack(0, track_id)
	local startPos = beatBuffer - BEAT --Close to playhead
	local endPos = itemDuration*BEAT + startPos --End is a beat * duration after startPos

	reaper.CreateNewMIDIItemInProj(track, startPos, endPos)
	reaper.UpdateArrange()
end

local function ShowControls(keyPressed) --Constant Update
	gfx.setfont(1,"Impact",36)
	gfx.x, gfx.y = 0,0 
	gfx.drawstr("Mapper Controls: \n")
	gfx.setfont(1,"Impact",24)
	gfx.x, gfx.y = 20,50
	gfx.drawstr("Press Space Bar to Pause/Play."..
		"\n-a- to move Left. -d- to move Right."..
		"\n-s- to Save mapping to project folder"..
		"\nHit the track number key to add an Item."..
		"\nKey Pressed: "..tostring(keyPressed)..
		"\nPress Escape to Exit.")
	gfx.update()
end

local function SpaceBar(beatBuffer)
	if reaper.GetPlayState() == 1 then
		--savedPlayPosition = reaper.GetPlayPosition() --save position of playhead
		savedBeatBuffer = beatBuffer

		reaper.Main_OnCommand(1008, 1) --STOP --PAUSE

	elseif reaper.GetPlayState() == 2 then
		--reaper.SetEditCurPos(savedPlayPosition, true, true) --usepositionofplayhead
		beatBuffer = reaper.GetPlayState()

		reaper.Main_OnCommand(1007, 1) --PLAY
		time_start = reaper.GetPlayPosition()
	end
	return beatBuffer
end

local function MoveLeft()
	cursor = reaper.GetCursorPosition()
	reaper.SetEditCurPos(cursor - BEAT,true, true)
end

local function MoveRight()
	cursor = reaper.GetCursorPosition()
	reaper.SetEditCurPos(cursor + BEAT,true, true)
end

local function ToggleMuteGT()
	local track = reaper.GetTrack(0, guideTrack)
	if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 0 then
		reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
	else
		reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
	end
end

local function Update()
	--elapsed = reaper.time_precise() - time_start
	elapsed = reaper.GetPlayPosition()

	char = gfx.getchar()
	if _key == 27 then reaper.Main_OnCommand(1016, 1, 0) return end --Exit and Stop on Escape
	if char > 0 and _key ~= char then --If key is pressed skip this one
		holding_start = reaper.time_precise() 
		_key = char
	else
		holding_elapsed = 0 --Clean variable when no key pressed or char = 0
	end

	if _key == char and holding_elapsed < max_holding_time then --DON'T CHEAT >:(
		holding_elapsed = reaper.time_precise() - holding_start
		if _key == 32 then beatBuffer = SpaceBar(beatBuffer) end --Stop and Plays
		if _key ==  49 then tkp = "1" CreateItem(1,1) end --a  97, q 113,  
	   	if _key == 50 then tkp = "2" CreateItem(2,1) end --s  w 119, 
	   	if _key == 51 then tkp = "3" CreateItem(3,1) end --d  e 101, 
	   	if _key == 52 then tkp = "4" CreateItem(4,1) end --f  r  114 
	   	if _key == 97 then tkp = "<-" MoveLeft() end
	   	if _key == 100 then tkp = "->" MoveRight() end
	   	if _key == 109 then tkp = "m" ToggleMuteGT() end
	   	if _key == 115 then tkp = "s" SaveToJson() end
	   	ShowControls(tkp)
	end

	if elapsed > beatBuffer then --quantize positions
		ShowControls(tkp)
		beatBuffer = beatBuffer + BEAT
		beatCounter = beatCounter + 1
	end
	reaper.defer(Update)
end


local name, x, y, w, h = "Mapping Editor", 500, 300, 1200, 0 --UI
--SETUP
gfx.init(name, x, y, 0, w, h) --INITIALIZE WINDOW

reaper.ClearConsole()

reaper.SetProjectGrid(0, projectGrid)

--START UP
user1 = reaper.MB("Welcome to the Beat the Reaper Mapping Editor.\nPress OK to start.","AV5",1)

if user1 == 1 then
	reaper.Main_OnCommand(1007, 1) --PLAY
	time_start = reaper.GetPlayPosition()
	ShowControls(tkp)
	Update()
else
end


