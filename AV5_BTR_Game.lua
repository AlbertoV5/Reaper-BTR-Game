--Booleans
randomMap = false
drawMidiShapes = false
--Values
beatOffset = 1 
beatMult = 1.0 --Multiplier for beat, 0.5 is 1/8 and 2 is 1/2 on music notation.

--Advanced
midiScale = {60,68,72,80} --Note for each track in order 1 to 4
missHitColor = 33554431.0

enableDebug = false
--[[
Script: Beat the Reaper Game

Description: 
Press keys to the beat of your song, achieve the highest score to show 
all of your clients your key pressing skills while producing hot tapes.

TO DO: 
-FIX THE VALID ITEM LIST ISSUE.

Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]
reaper.ClearConsole()
time_start = reaper.time_precise()
bpm = reaper.Master_GetTempo()
--BEAT
BEAT = 60/bpm*beatMult --Beat duration depending on BPM
markerOffset = BEAT*beatOffset

--Control
valid_items = {} --Don't change, 1 list per track
beatMap = {}
beatSpawnCounter = 0 --Starts at 0
p_score = 0 --Player Score

--Key
_key = 1 
uiKey = " " 
local holding_elapsed 
local max_holding_time = 1 

--Tempo
TempoEnvelopes = {{0},{1000}}
t_i = 2 --Index for Tempo Envelopes, start at 2

--Load Core
local info = debug.getinfo(1,'S')
scriptPath = info.source:match[[^@?(.*[\\/])[^\\/]-$]]
local BTR = require(scriptPath.."AV5_BTR_Lib")
local MAP = require(scriptPath.."AV5_BTR_LibMap")

SONG_DURATION_BEATS = BTR.GetSongLength(4)
SONG_DURATION_BARS = math.floor(SONG_DURATION_BEATS+4/4)

-- FUNCTIONS --

local function sc(v)
   if enableDebug == true then reaper.ShowConsoleMsg(tostring(v) .. "\n") end
end

local function ShowScore(keyPressed) --Constant Update
	gfx.setfont(1,"Impact",36)
	gfx.x, gfx.y = 0,0 
	gfx.drawstr("Score: "..tostring(p_score).." / "..tostring(beatSpawnCounter).."\nKey Pressed: "..tostring(keyPressed))
	gfx.update()
end

local function FinalScore() --FINAL SCORE SCREEN
	gfx.x, gfx.y = 0, 0 
	gfx.drawstr("Final Score = "..
		tostring(p_score).." / "..
		tostring(beatSpawnCounter)..
		"\nPercentage: "..tostring(p_score/beatSpawnCounter)) 
	gfx.update()
	if gfx.getchar() == 27 then
		return
	end
    reaper.defer(FinalScore)
end

local function LoadMap()
	if randomMap == true then 
		beatMap = BTR.RandomMap2(100,1,2)
	else
		beatMap = MAP.ReadMap()
		--reaper.ShowConsoleMsg(tostring(beatMap[2][2]))
		if beatMap == nil  then
			playingState = 100 end --STOP IT
	end
	return beatMap
end

local function SongPosition(beatMap)
	beatPos_beat = beatMap[1][1]
	nextBeat = beatPos_beat*BEAT
	levelLength = beatMap[#beatMap][1]
	songLength = reaper.TimeMap2_beatsToTime(0, levelLength) + 3 --out time
end

local function EvaluateTempo() --Adapt, Improve, Overcome
	if elapsed > (TempoEnvelopes[t_i][1]) then --position compare
		bpm = TempoEnvelopes[t_i][2] --new bpm
		--sc(bpm)
		BEAT =  60/bpm*beatMult
		markerOffset = BEAT*beatOffset
		if t_i+1 > #TempoEnvelopes then
		else t_i = t_i + 1 end
	end
end

local function Update()
	time = reaper.GetPlayPosition()
    elapsed = time - time_start

	char = gfx.getchar() 
   	if char == 27 then --ESC
   		reaper.Main_OnCommand(1016, 1) 
   		return
   	elseif char == 32 then --Space Bar
   		reaper.Main_OnCommand(1008, 1) --pause
   		return
   	end

	if char > 0 and _key ~= char then
		holding_start = reaper.time_precise() 
		_key = char
	else
		holding_elapsed = 0
	end

	if _key == char and holding_elapsed < max_holding_time then
		holding_elapsed = reaper.time_precise() - holding_start
		if _key ==  49 then uiKey = "1" BTR.DeleteItem(1) end --a  97, q 113,  
	   	if _key == 50 then uiKey = "2" BTR.DeleteItem(2) end --s  w 119, 
	   	if _key == 51 then uiKey = "3" BTR.DeleteItem(3) end --d  e 101, 
	   	if _key == 52 then uiKey = "4" BTR.DeleteItem(4) end --f  r  114 
	   	ShowScore(uiKey)
	end

	if #valid_items > 0 then
		_pos = reaper.GetMediaItemInfo_Value(valid_items[1], "D_POSITION")
		_len = reaper.GetMediaItemInfo_Value(valid_items[1], "D_LENGTH")
		if _pos + _len < elapsed then
			table.remove(valid_items,1)
		end
	end

    if  elapsed > songLength then
    	BTR.EndGame(p_score, beatSpawnCounter)
 		FinalScore() 
        return
    else
	    if elapsed + markerOffset > nextBeat and beatPos_beat ~= levelLength then     --Update each time a beat happens, NEEDS to change for tempo change
	    	ShowScore(uiKey)
	    	EvaluateTempo()
	    	beatSpawnCounter = beatSpawnCounter + 1 
	    	nextBeat = beatMap[beatSpawnCounter][1]*BEAT
    		beatPos_beat = beatMap[beatSpawnCounter][1]

    		BTR.NewItem(beatMap[beatSpawnCounter][2],nextBeat + markerOffset,nextBeat + markerOffset + beatMap[beatSpawnCounter][3]*BEAT)
	    end
       	reaper.defer(Update)
    end
end

local function Pause()
	char = gfx.getchar() 
	ShowScore(uiKey)
	if char == 27 then --Esc
		reaper.Main_OnCommand(1016, 1, 0) 
   		return
   	elseif char == 32 then --Space Bar
   		reaper.Main_OnCommand(1008,1)
   		return reaper.defer(Update)
   	else
   	reaper.defer(Pause)
   end
end

--PROCESS
if reaper.CountTempoTimeSigMarkers(0) > 1 then
	TempoEnvelopes = BTR.HandleTempoEnvelopes()
end
playingState = reaper.GetPlayState()
BTR.CleanUpItems({1,4})

beatMap = LoadMap()
SongPosition(beatMap)

if playingState == 0 then 
	time_start = BTR.Start()
	ShowScore(uiKey)
	Update()
	Pause()
else
	currCursor = reaper.GetCursorPosition()
	reaper.Main_OnCommand(1016, 1, 0)
	reaper.SetEditCurPos(currCursor, true, true)
end
