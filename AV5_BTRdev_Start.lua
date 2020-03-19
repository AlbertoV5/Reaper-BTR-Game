--User Variables
--Booleans
useProjectTempo = true -- set false to input custom tempo below
randomMap = true -- don't tweak, reading .csv not implemented yet
randomBeatMult = false -- don't tweak, feature not implemented yet
--Values
user_bpm = 120 --In case you want to set tempo different to session's
beatOffset = 1 --OFFSET ON BEATS FOR SPAWNING
countDown = 1 --Beats to wait before spawning beats
hitbox_pre = 0 --ITEM HITBOX in amount of beats (min = 0)
hitbox_pos = 1 --ITEM HITBOX in amount of beats (min = 1)
random_x_in_y = {1,1} -- x in y chance of an item spawning
SONG_DURATION = 145 --Song Duration in seconds
beatMult = 1.0 --Multiplier for beat, 0.5 is 1/8 and 2 is 1/2 on music notation.
--Advanced
debug = false
--[[
Script: Beat the Reaper - Small rhythm game for your Reaper Projects

Description: 
Press keys to the beat of your song, achieve the highest score to show 
all of your clients your key pressing skills while producing hot tapes.

Installation: 
Run AV5_BTR_Setup.lua to setup your session, then assign a hotkey to this script.

How to Play:
1.The project will play and items will appear on your edit window.
2.Try to hit your Q W E R keys according to the tracks 1 2 3 4 to delete the items.
3.If you do it on beat, you'll get a point, if you miss you will lose a point.
4.You can see your score at the end of the song. It will be saved to a new track. 40702 <-new track bottom of tcp
5.

Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]

time_start = reaper.time_precise()
bpm = reaper.Master_GetTempo()
--BEAT

--Constants
BEAT = 60/bpm*beatMult --Beat duration depending on BPM
SONG_DURATION_BEATS = math.ceil(SONG_DURATION*(1/BEAT)) --Song Duration in beats, round up
SONG_DURATION_BEATS = 320 --Beat mapping length

--Other
markerOffset = BEAT*beatOffset
hitbox_beat_pre = BEAT*hitbox_pre --HITBOX
hitbox_beat_pos = BEAT*hitbox_pos --HITBOX
beatCounter = 1 --Starting point of the beat counter
refreshCounter = 1 --Starting point of key refresh counter
valid_items = {{},{},{},{}} --1 list for each track, 1 to 4 
local name, x, y, w, h = "Beat the Reaper Game", 300, 100, 0, 1080 --UI

--Control
TempoEnvelopes = {}
t_i = 2 --index of list of Tempo Envelopes
beatBuffer = BEAT*countDown --saves the time in seconds of the beat mapping
--Gameplay
_key = 1 --pressed key, start as ~= 0
tkp = " " --pressed key for UI
holding_elapsed = 0 --for key pressed
beatSpawnCounter = 0
p_score = 0 --Player Score

local function c(str)
   if debug then reaper.ShowConsoleMsg(tostring(str) .. "\n") end
end

local function HandleTempoEnvelopes() --just read te
	local te_list = {}
	for i = 1, reaper.CountTempoTimeSigMarkers(0) do
		te_list[i] = {}
		t_val, t_tpos, t_mpos, t_bpos, t_bpm, t_tsn, t_tsd, t_linear = reaper.GetTempoTimeSigMarker(0, i-1)
		table.insert(te_list[i],t_tpos)
		table.insert(te_list[i],t_bpm)
	end
	return te_list
end

local function EvaluateTempo2()
	if elapsed > (TempoEnvelopes[t_i][1]) then --position compare
		bpm = TempoEnvelopes[t_i][2] --new bpm
		c(bpm)
		BEAT = 60/bpm*beatMult --Beat duration depending on BPM
		markerOffset = BEAT*beatOffset
		if t_i+1 > #TempoEnvelopes then
		else t_i = t_i + 1 end
	end
end

local function Score() --FINAL SCORE SCREEN
	gfx.x, gfx.y = 0, 0 
	gfx.drawstr("Final Score = "..tostring(p_score).." / "..tostring(beatSpawnCounter).."\nPercentage: "..tostring(p_score/beatSpawnCounter)) 
	gfx.update()
	if gfx.getchar() == 32 then
		return
	end
    reaper.defer(Score)
end

local function RandomMap(numOfBeats)
	local mapList = {} 
	for i = 1, numOfBeats do
		if random_x_in_y[1] > math.random(0,random_x_in_y[2]) then -- if 1 > 5
			mapList[i] = math.random(1,4) --Place an item in track id (1 to 4)
		else
			mapList[i] = 0 -- No item at 0
		end
	end
	return mapList
end

local function NewItem(trackNum,pos_current,pos_offset) 
	if #valid_items[trackNum] > 0 then 
		if 	reaper.GetMediaItemInfo_Value(valid_items[trackNum][1], "D_POSITION")+BEAT < pos_current then --Checks for Position of item
			table.remove(valid_items[trackNum],1) -- ITEM PASSED (first in list) REMOVE ITEM AS (TRACK,#)
		end
	end
	local track = reaper.GetTrack(0, trackNum)
	reaper.CreateNewMIDIItemInProj(track,pos_current+pos_offset,pos_current+pos_offset+BEAT) --Track, START, END
	local newest_item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
	table.insert(valid_items[trackNum],newest_item) -- Adds the recently created item to the list of specific track
	c("NEW ITEM at track: "..tostring(trackNum)..", item: "..tostring(newest_item))
end

local function ShowScore(keyPressed)
	gfx.setfont(1,"Impact",36)
	gfx.x, gfx.y = 0,0 
	gfx.drawstr("Score: "..tostring(p_score).." / "..tostring(beatSpawnCounter).."\nKey Pressed: "..tostring(keyPressed))
	gfx.update()
end

local function DeleteItem(id) -- track id
	local playHead = reaper.GetPlayPosition() 
	if #valid_items[id] > 0 then --PROCESS delete item
		local d_item = valid_items[id][1] --CLOSEST ITEM TO PLAYHEAD
		local d_track = reaper.GetTrack(0, id)
		local d_pos = reaper.GetMediaItemInfo_Value(d_item, "D_POSITION")
		--COMPARE
		i_start = d_pos - hitbox_beat_pre
		i_end = d_pos + hitbox_beat_pos
		
		if playHead > i_start and i_end > playHead then -- if playHead between 1 beat before and 1 beat after item start
			c("Hit one"..tostring(d_item))
			reaper.DeleteTrackMediaItem(d_track, d_item) --this is buggy
			--reaper.SetMediaItemSelected(d_item, true) 
			--reaper.Main_OnCommand(40699, 1) --CUT BY COMMAND INSTEAD OF DELETETRACKMEDIAITEM
			p_score = p_score + 1
			table.remove(valid_items[id],1) -- ITEM DELETED (first in list) REMOVE ITEM AS (TRACK,#)
			reaper.UpdateArrange()
		else --YOU MISSED!
			p_score = p_score - 1 
			table.remove(valid_items[id],1) -- ITEM MISSED (first in list) REMOVE ITEM AS (TRACK,#)
		end
	else -- YOU PRESSED THE KEY AND THERE WAS NO ITEM D:
			p_score = p_score - 1 
			table.remove(valid_items[id],1) -- ITEM MISSED (first in list) REMOVE ITEM AS (TRACK,#)
	end
end

local function Update() --System cycles update, around 30 ms
	time = reaper.time_precise()
    elapsed = time - time_start
	char = gfx.getchar() -- Read key presses
   	if char == 32 then reaper.Main_OnCommand(1016, 1, 0) return end --STOP on space bar

	if char > 0 and _key ~= char then --If key is pressed skip this one
		holding_start = reaper.time_precise() 
		_key = char
	else
		holding_elapsed = 0 --Clean variable when no key pressed or char = 0
	end
	c(char)

	if _key == char and holding_elapsed < 1 then --if key is pressed and held for less than 1 second DON'T CHEAT >:(
		holding_elapsed = reaper.time_precise() - holding_start
		if _key ==  49 then tkp = "1" DeleteItem(1) end --a  97, q 113,  
	   	if _key == 50 then tkp = "2" DeleteItem(2) end --s  w 119, 
	   	if _key == 51 then tkp = "3" DeleteItem(3) end --d  e 101, 
	   	if _key == 52 then tkp = "4" DeleteItem(4) end --f  r  114 
	   	ShowScore(tkp)
	end

    if elapsed > beatBuffer then     --Update each time a beat happens, NEEDS to change for tempo change
    	ShowScore(tkp)
    	EvaluateTempo2()
    	beatBuffer = beatBuffer + BEAT
    	track_id = beatMap[beatCounter]
    	if track_id > 0 then
    		NewItem(track_id,beatBuffer,markerOffset) -- track, position, length
			reaper.UpdateArrange()
			beatSpawnCounter = beatSpawnCounter + 1 --To Compare with Score
    	end
    	beatCounter = beatCounter + 1
    end

    if elapsed > SONG_DURATION then
    	reaper.Main_OnCommand(1016, 1, 0)--Stop
    	time_start = reaper.time_precise()
		Score(reaper.time_precise()) --Ending
        return
    else
        reaper.defer(Update)
    end
end

local function Start()
	--CLEAN UP ITEMS ON TRACKS 1 to 4
	local trackRange = {1,4}
	for i = trackRange[1], trackRange[2] do
		selectedTrack = reaper.GetTrack(0, i)
		for i = 1, reaper.CountTrackMediaItems(selectedTrack) do
			reaper.SetMediaItemSelected(reaper.GetTrackMediaItem(selectedTrack, i-1), true) --Select all items on track
		end
	end
	reaper.Main_OnCommand(40699, 1) --Delete all selected items
	--SETUP
	gfx.init(name, x, y, 0, w, h) --INITIALIZE WINDOW
	reaper.SetEditCurPos(0.0, true, true)
	time_start = reaper.time_precise()
	reaper.Main_OnCommand(1007, 1, 0)--Play
end

--PROCESS
pS = reaper.GetPlayState()
if debug == true then reaper.ClearConsole() end
if useProjectTempo == true then bpm = reaper.Master_GetTempo() else bpm = user_bpm end
TempoEnvelopes = HandleTempoEnvelopes() --List of [1] pos in beats and [2] value

--INITIALIZE MAP
beatMap = {}
if randomMap == true then beatMap = RandomMap(SONG_DURATION_BEATS) end

if  pS == 0 then 
	Start()
	ShowScore(" ")
	Update()
else
	currCur = reaper.GetCursorPosition()--Get Position
    reaper.Main_OnCommand(1016, 1, 0)--Stop
	reaper.SetEditCurPos(currCur, true, true) --Set Position
end

reaper.atexit(Update) --Clean up
reaper.atexit(Score) --Clean up

