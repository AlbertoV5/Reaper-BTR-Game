local BTR_CORE = {};

function BTR_CORE.RandomMap(numOfBeats)
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

function BTR_CORE.RandomMap2(numOfItems,r1,r2)
	local mapList = {}
	local add = 0
	for i = 1, numOfItems do
		check = math.random(r1,r2)
		if check == 1 then
			beatPos = i
			trackNum = math.random(1,4)
			beatLen = 1
			combo = {beatPos,trackNum,beatLen}
			table.insert(mapList,combo)
		end
	end
	return mapList
end

function BTR_CORE.HandleTempoEnvelopes() --read all Tempo Env points in project
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

function BTR_CORE.CleanUpItems(trackRange)
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

function BTR_CORE.Start() --Starts the Game
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
 
function BTR_CORE.DrawMidiShape(trackNum,newItem)
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

function BTR_CORE.EndGame(playerScore,maxScore)
	CreateScoreTrack(playerScore,maxScore)
end

function BTR_CORE.GetSongLength(extraBeats)
	lastItem = reaper.GetMediaItem(0, reaper.CountTrackMediaItems(reaper.GetTrack(0, 0))-1) 
	itemPos = reaper.GetMediaItemInfo_Value(lastItem, "D_POSITION")
	itemLength = reaper.GetMediaItemInfo_Value(lastItem, "D_LENGTH")
	itemEnd = itemPos + itemLength
	retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, itemEnd)
	return fullbeats
end


function BTR_CORE.DeleteItem(trackID) -- track id
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


function BTR_CORE.NewItem(trackNum,pos_current,offset,pos_len) 
	if #valid_items[trackNum] > 0 then 
		d_item_pos = reaper.GetMediaItemInfo_Value(valid_items[trackNum][1], "D_POSITION")
		d_item_len = reaper.GetMediaItemInfo_Value(valid_items[trackNum][1], "D_LENGTH")
		if elapsed > d_item_pos+d_item_len then
			table.remove(valid_items[trackNum],1) -- ITEM PASSED (first in list) REMOVE ITEM AS (TRACK,#)
		end
	end	
	local track = reaper.GetTrack(0, trackNum)
	reaper.CreateNewMIDIItemInProj(track,pos_current+offset,pos_len) --Track, START, END
	local newest_item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
	if drawMidiShapes == true then BTR.DrawMidiShape(trackNum,newest_item) end

	table.insert(valid_items[trackNum],newest_item) -- Adds the recently created item to the list of specific track
	--sc("NEW ITEM at track: "..tostring(trackNum)..", item: "..tostring(newest_item))
end


return BTR_CORE;
