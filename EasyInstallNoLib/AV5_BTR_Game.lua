--User Variables
SONG_DURATION_BEATS = 273 --INPUT THE DURATION OF YOUR SONG IN BEATS
--Booleans
useProjectTempo = true -- set false to input custom tempo below
randomMap = true -- don't tweak, reading .csv not implemented yet
randomBeatMult = false -- don't tweak, feature not implemented yet
--Values
user_bpm = 120 --In case you want to set tempo different to session's
beatOffset = 1 --OFFSET ON BEATS FOR SPAWNING
countDown = 1 --Beats to wait before spawning items
hitbox_pre = 0 --ITEM HITBOX in amount of beats (min = 0)
hitbox_pos = 1 --ITEM HITBOX in amount of beats (min = 1)
beatMult = 1.0 --Multiplier for beat, 0.5 is 1/8 and 2 is 1/2 on music notation.

random_x_in_y = {5,7} -- x in y chance of an item spawning
midiScale = {60,68,72,80} --Note for each track in order 1 to 4
missHitColor = 33554431.0
--Advanced
enableDebug = false
--[[
Script: Beat the Reaper - 

Description: 
Press keys to the beat of your song, achieve the highest score to show 
all of your clients your key pressing skills while producing hot tapes.

Installation: 
1. Place all 3 BTR scripts in the same directory.
2. Run AV5_BTR_Setup.lua to setup your session, then assign a hotkey to this script.

How to Play:
1.The project will play and items will appear on your edit window.
2.Try to hit your 1 2 3 4 keys according to the tracks 1 2 3 4 to delete the items.
3.If you do it on beat, you'll get a point, if you miss you will lose a point.

To Do:
-Add Create a Track with a Midi item of length of your score when closing the game.

Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]

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
beatCounter = 1 --Reaper first beat on ruler
beatBuffer = BEAT*countDown --Most important part of Update()
valid_items = {{},{},{},{}} --Don't change, 1 list per track
local holding_elapsed --Key press control
max_holding_time = 1 --time in seconds for key press hold
beatMap = {}

--Gameplay: Don't change starting values
_key = 1 --pressed key
tkp = " " --pressed key for UI
beatSpawnCounter = 0 --Starts at 0
p_score = 0 --Player Score
TempoEnvelopes = {{0},{1000}}
t_i = 2 --Index for Tempo Envelopes, start at 2
--Load Core

function RandomMap(numOfBeats)
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

function HandleTempoEnvelopes() --read all Tempo Env points in project
	local te_list = {}
	if reaper.CountTempoTimeSigMarkers(0) > 0 then
		for i = 1, reaper.CountTempoTimeSigMarkers(0) do
			te_list[i] = {}
			t_val, t_tpos, t_mpos, t_bpos, t_bpm, t_tsn, t_tsd, t_linear = reaper.GetTempoTimeSigMarker(0, i-1)
			table.insert(te_list[i],t_tpos)
			table.insert(te_list[i],t_bpm)
		end
	else
		te_list = {{0},{1000}} --There are no tempo envelopes
	end
	return te_list
end

function CleanUpItems(trackRange)
--CLEAN UP ITEMS ON TRACKS 1 to 4
	reaper.Main_OnCommand(40289, 1) --Unselect First
	for i = trackRange[1], trackRange[2] do
		selectedTrack = reaper.GetTrack(0, i)
		for i = 1, reaper.CountTrackMediaItems(selectedTrack) do
			reaper.SetMediaItemSelected(reaper.GetTrackMediaItem(selectedTrack, i-1), true) --Select all items on track
		end
	end
	reaper.Main_OnCommand(40699, 1) --Delete all selected items
end

function Start() --Starts the Game
	local name, x, y, w, h = "Beat the Reaper Game", 300, 100, 0, 1080 --UI
	--SETUP
	gfx.init(name, x, y, 0, w, h) --INITIALIZE WINDOW
	reaper.SetEditCurPos(0.0, true, true)
	reaper.Main_OnCommand(1007, 1, 0)--Play
	return reaper.time_precise()
end

local function InsertNote(midinote,itemTake) 
	reaper.MIDI_InsertNote(itemTake, false, false, 840, 960, 1, midinote, 100, false) 
end
 
function DrawMidiShape(trackNum,newItem)
	local activeTake = reaper.GetMediaItemTake(newItem, 0)
	InsertNote(midiScale[trackNum],activeTake)
end

local function CreateScoreTrack(playerScore,maxScore)
	local trackHeight = 100
	local trackName = "Score: "..tostring(math.ceil(1000*playerScore/maxScore)/10).."%, "
	..tostring(playerScore).." out of "..tostring(maxScore)
	reaper.Main_OnCommand(40702, 1) --Create track at bottom
	local scoreTrack = reaper.GetTrack(0, reaper.CountTracks(0)-1)
	reaper.GetSetMediaTrackInfo_String(scoreTrack, "P_NAME", trackName, true)
	reaper.SetMediaTrackInfo_Value(scoreTrack, "I_HEIGHTOVERRIDE",trackHeight) --Change height to 200
	reaper.SetTrackSelected(scoreTrack, true) --SELECT
	reaper.Main_OnCommand(40358,1) --RANDOM COLORS
	--reaper.SetTrackSelected(scoreTrack, false) --DESELECT
	reaper.CreateNewMIDIItemInProj(scoreTrack, 0, playerScore, false)
end

function EndGame(playerScore,maxScore)
	CreateScoreTrack(playerScore,maxScore)
end

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

local function NewItem(trackNum,pos_current,pos_offset) 
	if #valid_items[trackNum] > 0 then 
		if 	reaper.GetMediaItemInfo_Value(valid_items[trackNum][1], "D_POSITION")+BEAT < pos_current then --Checks for Position of item
			table.remove(valid_items[trackNum],1) -- ITEM PASSED (first in list) REMOVE ITEM AS (TRACK,#)
		end
	end	
	local track = reaper.GetTrack(0, trackNum)
	reaper.CreateNewMIDIItemInProj(track,pos_current+pos_offset,pos_current+pos_offset+BEAT) --Track, START, END
	local newest_item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
	DrawMidiShape(trackNum,newest_item)
	table.insert(valid_items[trackNum],newest_item) -- Adds the recently created item to the list of specific track
	--sc("NEW ITEM at track: "..tostring(trackNum)..", item: "..tostring(newest_item))
end

local function DeleteItem(trackID) -- track id
	local playHead = reaper.GetPlayPosition() 
	if #valid_items[trackID] > 0 then --THERE IS AN ITEM IN THE TRACK
		local d_item = valid_items[trackID][1] --CLOSEST ITEM TO PLAYHEAD
		local d_track = reaper.GetTrack(0, trackID)
		local d_pos = reaper.GetMediaItemInfo_Value(d_item, "D_POSITION")
		--COMPARE
		i_start = d_pos - hitbox_beat_pre
		i_end = d_pos + hitbox_beat_pos
		
		if playHead > i_start and i_end > playHead then -- if playHead between 1 beat before and 1 beat after item start
			--sc("Hit one"..tostring(d_item))
			reaper.DeleteTrackMediaItem(d_track, d_item) --sometimes this bugs out
			p_score = p_score + 1
			table.remove(valid_items[trackID],1) -- ITEM DELETED (first in list) REMOVE ITEM AS (TRACK,#)
			reaper.UpdateArrange()
		else --THERE IS AN ITEM AND YOU MISSED
			p_score = p_score - 1 
			reaper.SetMediaItemInfo_Value(d_item,"I_CUSTOMCOLOR", missHitColor) --No longer destructable
			reaper.UpdateArrange()
			table.remove(valid_items[trackID],1) -- ITEM MISSED (first in list) REMOVE ITEM AS (TRACK,#)
		end
	else -- YOU PRESSED THE KEY AND THERE WAS NO ITEM in the item list D:
			p_score = p_score - 1 
			--table.remove(valid_items[trackID],1)
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

	if _key == char and holding_elapsed < max_holding_time then --DON'T CHEAT >:(
		holding_elapsed = reaper.time_precise() - holding_start
		if _key ==  49 then tkp = "1" DeleteItem(1) end --a  97, q 113,  
	   	if _key == 50 then tkp = "2" DeleteItem(2) end --s  w 119, 
	   	if _key == 51 then tkp = "3" DeleteItem(3) end --d  e 101, 
	   	if _key == 52 then tkp = "4" DeleteItem(4) end --f  r  114 
	   	ShowScore(tkp)
	end

    if SONG_DURATION_BEATS < beatCounter-beatOffset then
    	reaper.Main_OnCommand(1016, 1, 0)--Stop
    	BTR.EndGame(p_score, beatSpawnCounter)
 		FinalScore() --Ending
        return
    else
	    if elapsed > beatBuffer then     --Update each time a beat happens, NEEDS to change for tempo change
	    	ShowScore(tkp)
	    	EvaluateTempo()
	    	beatBuffer = beatBuffer + BEAT
	    	track_id = beatMap[beatCounter]
	    	beatCounter = beatCounter + 1
	    	if track_id > 0 then
	    		if beatCounter < SONG_DURATION_BEATS then
		    		NewItem(track_id,beatBuffer,markerOffset)
					reaper.UpdateArrange()
					beatSpawnCounter = beatSpawnCounter + 1 
				end
	    	end
	    end
       	reaper.defer(Update)
    end
end

--PROCESS
pS = reaper.GetPlayState()
reaper.ClearConsole()
if useProjectTempo == true then bpm = reaper.Master_GetTempo() else bpm = user_bpm end
if reaper.CountTempoTimeSigMarkers(0) > 1 then
	TempoEnvelopes = andleTempoEnvelopes() --List of [1] pos in beats and [2] value
end

--INITIALIZE MAP
if randomMap == true then beatMap = RandomMap(SONG_DURATION_BEATS+2) end

if  pS == 0 then 
	CleanUpItems({1,4}) --Clean on tracks x to y
	time_start = Start()
	ShowScore(tkp)
	Update()
else --If playing or recording, stop
	currCursor = reaper.GetCursorPosition()
    reaper.Main_OnCommand(1016, 1, 0)
	reaper.SetEditCurPos(currCursor, true, true)
end

--Clean up
--reaper.atexit(Update) 
--reaper.atexit(FinalScore)

