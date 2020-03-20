local BTR_CORE = {};

--Don't mind me, I'm just functions

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

return BTR_CORE;
