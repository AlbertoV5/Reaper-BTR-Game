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
	return reaper.GetPlayPosition()
end

local function InsertNote(midinote,itemTake) 
	reaper.MIDI_InsertNote(itemTake, false, false, 840, 960, 1, midinote, 100, false) 
end
 
function BTR_CORE.DrawMidiShape(trackNum,newItem)
	local activeTake = reaper.GetMediaItemTake(newItem, 0)
	InsertNote(midiScale[trackNum],activeTake)
end

local function CreateScoreTrack(playerScore,maxScore)
	local trackHeight = 50
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
	reaper.Main_OnCommand(1016, 1, 0)
	CreateScoreTrack(playerScore,maxScore)
end

function BTR_CORE.GetSongStart()
	local first_item = reaper.GetTrackMediaItem(reaper.GetTrack(0, 0), 0)
	local item_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
	_1, _2, _3, beatPos, _4 = reaper.TimeMap2_timeToBeats(0, item_pos)
	return beatPos
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
	if #valid_items > 0 then 
		local d_item = valid_items[1]
		local d_track = reaper.GetTrack(0, trackID)
		if reaper.GetMediaItemTrack(d_item) == d_track then
			local d_pos = reaper.GetMediaItemInfo_Value(d_item, "D_POSITION")
			local d_len = reaper.GetMediaItemInfo_Value(d_item, "D_LENGTH")
			local i_end = d_pos + d_len
			
			if playHead > d_pos and i_end > playHead then
				--sc("Hit one"..tostring(d_item))
				reaper.DeleteTrackMediaItem(d_track, d_item) 
				p_score = p_score + 1
				table.remove(valid_items,1)
				reaper.UpdateArrange()
			else
				p_score = p_score - 1 
				--reaper.SetMediaItemInfo_Value(d_item,"I_CUSTOMCOLOR", missHitColor) --No longer destructable
				--table.remove(valid_items,1) -- ITEM MISSED (first in list) REMOVE ITEM AS (TRACK,#)
			end
		end
	else 
		p_score = p_score - 1 
	end
end


function BTR_CORE.NewItem(trackNum,pos_spawn,pos_len) 
	local track = reaper.GetTrack(0, trackNum)
	reaper.CreateNewMIDIItemInProj(track,pos_spawn,pos_len) --Track, START, END
	local newest_item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
	if drawMidiShapes == true then BTR.DrawMidiShape(trackNum,newest_item) end

	table.insert(valid_items,newest_item) 
end


return BTR_CORE;
