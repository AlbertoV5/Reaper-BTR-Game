--Booleans
randomMap = false
drawMidiShapes = false
--Values

beatOffset = 1 --OFFSET ON BEATS FOR SPAWNING
countDown = 0 --Beats to wait before spawning items
hitbox_pre = 0 --ITEM HITBOX in amount of beats (min = 0)
hitbox_pos = 1 --ITEM HITBOX in amount of beats (min = 1)
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

--Constants
BEAT = 60/bpm*beatMult --Beat duration depending on BPM

--Other
markerOffset = BEAT*beatOffset
hitbox_beat_pre = BEAT*hitbox_pre --HITBOX
hitbox_beat_pos = BEAT*hitbox_pos --HITBOX

--Control
beatBuffer = BEAT*countDown --Most important part of Update()
valid_items = {{},{},{},{}} --Don't change, 1 list per track
beatMap = {}
beatCounter = 0
beatSpawnCounter = 0 --Starts at 0
p_score = 0 --Player Score

--Key
_key = 1 --pressed key
tkp = " " --pressed key for UI
local holding_elapsed --Key press control
max_holding_time = 1 --time in seconds for key press hold

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
	gfx.drawstr("Final Score = "..tostring(p_score).." / "..tostring(beatSpawnCounter).."\nPercentage: "..tostring(p_score/beatSpawnCounter)) 
	gfx.update()
	if gfx.getchar() == 32 then
		return
	end
    reaper.defer(FinalScore)
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

local function Wait()
	time = reaper.time_precise()
	elapsed = time - time_start
	if elapsed > 3 then
		return
	else
		reaper.defer(Wait)
	end
end


local function Update() --System cycles update, around 30 ms
	time = reaper.time_precise()
    elapsed = time - time_start
	char = gfx.getchar() -- Read key presses
   	if char == 32 then reaper.Main_OnCommand(1016, 1, 0) 
   		BTR.EndGame(p_score, beatSpawnCounter)
 		FinalScore() --Ending
   		return 
   	end --STOP on space bar

	if char > 0 and _key ~= char then --If key is pressed skip this one
		holding_start = reaper.time_precise() 
		_key = char
	else
		holding_elapsed = 0 --Clean variable when no key pressed or char = 0
	end

	if _key == char and holding_elapsed < max_holding_time then --DON'T CHEAT >:(
		holding_elapsed = reaper.time_precise() - holding_start
		if _key ==  49 then tkp = "1" BTR.DeleteItem(1) end --a  97, q 113,  
	   	if _key == 50 then tkp = "2" BTR.DeleteItem(2) end --s  w 119, 
	   	if _key == 51 then tkp = "3" BTR.DeleteItem(3) end --d  e 101, 
	   	if _key == 52 then tkp = "4" BTR.DeleteItem(4) end --f  r  114 
	   	ShowScore(tkp)
	end

    if  elapsed > songLength then
    	time_start = reaper.time_precise()
    	reaper.Main_OnCommand(1016, 1, 0)--Stop
    	BTR.EndGame(p_score, beatSpawnCounter)
 		FinalScore() --Ending
        return
    else
	    if elapsed + markerOffset > nextBeat and beatPos ~= levelLength then     --Update each time a beat happens, NEEDS to change for tempo change
	    	ShowScore(tkp)
	    	EvaluateTempo()
	    	beatSpawnCounter = beatSpawnCounter + 1 
	    	nextBeat = beatMap[beatSpawnCounter][1]*BEAT
    		beatPos = beatMap[beatSpawnCounter][1]
			beatTrack = beatMap[beatSpawnCounter][2]
			beatLength = nextBeat + markerOffset + beatMap[beatSpawnCounter][3]*BEAT
    		BTR.NewItem(beatTrack,nextBeat,markerOffset,beatLength)
	    end
       	reaper.defer(Update)
    end
end

--PROCESS
playingState = reaper.GetPlayState()
if reaper.CountTempoTimeSigMarkers(0) > 1 then
	TempoEnvelopes = BTR.HandleTempoEnvelopes() --List of [1] pos in beats and [2] value
end

if randomMap == true then 
	beatMap = BTR.RandomMap2(100,1,2)
else
	beatMap = MAP.ReadMap()
	--reaper.ShowConsoleMsg(tostring(beatMap[2][2]))
	if beatMap == nil  then
		playingState = 100 end --STOP IT
end

beatPos = beatMap[1][1]
nextBeat = beatPos*BEAT
levelLength = beatMap[#beatMap][1]
songLength = reaper.TimeMap2_beatsToTime(0, levelLength) + 3

if  playingState == 0 then 
	BTR.CleanUpItems({1,4}) --Clean on tracks x to y
	time_start = BTR.Start()
	ShowScore(tkp)
	Update()
else --If playing or recording, stop
	currCursor = reaper.GetCursorPosition()
    reaper.Main_OnCommand(1016, 1, 0)
	reaper.SetEditCurPos(currCursor, true, true)
end

--reaper.atexit(Update) 
--reaper.atexit(FinalScore)
