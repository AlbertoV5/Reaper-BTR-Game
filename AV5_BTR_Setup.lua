--User Variables
randomTrackColor = false
--
numberOfTracks = 4 --Set randomTrackColor to true if using 4+ tracks
colorList = {19005439.0,33227519.0,25231112.0,33227392.0}
trackHeight = 200
--[[
Script: Beat the Reaper Setup
Description: 
Grabs your item and pastes it on a new project, then setsup the project for
Beat the Reaper.
Script by Alberto Valdez at av5sound.com and u/Sound4Sound
--]]

--
local function CopyFile()
	if reaper.CountSelectedMediaItems(0) > 0 then
		reaper.Main_OnCommand(40698, 1)--Copy
		return true
	else
		reaper.MB("No Item Selected","AV5",0)
		return false
	end
end

local function NewProject()
	reaper.Main_OnCommand(40026,1)--Save
	reaper.Main_OnCommand(40023, 1)--New Project
end

local function PasteFile()
	for i = 1, reaper.CountTracks(0) do --Delete all tracks
		reaper.DeleteTrack(i-1)
	end
	reaper.Main_OnCommand(40001, 1)
	reaper.SetTrackSelected(reaper.GetTrack(0, 0), true) --Track 0
	reaper.Main_OnCommand(40058,1)--Paste Items Current Project
end


local function NewTracks()
	local trackList = {}
	for i =1, numberOfTracks do
		reaper.Main_OnCommand(40001, 1)
	end

	for i = 1, reaper.CountTracks(0) do
		trackList[i] = reaper.GetTrack(0, i-1) --Get Track object
		if i == 1 then -- For guide track
			reaper.GetSetMediaTrackInfo_String(
			trackList[i], "P_NAME", "Guide Track", true)
			reaper.SetMediaTrackInfo_Value(
				trackList[i], "I_HEIGHTOVERRIDE",50) --Change height to 200
		else -- For list of track for i > 1
			reaper.GetSetMediaTrackInfo_String(
			trackList[i], "P_NAME", tostring(i-1), true)
			reaper.SetMediaTrackInfo_Value(
				trackList[i], "I_HEIGHTOVERRIDE",trackHeight) --Change height to 200
			if randomTrackColor == false then 
				reaper.SetMediaTrackInfo_Value(trackList[i], "I_CUSTOMCOLOR", colorList[i-1]) end
		end
		if randomTrackColor == true then 
			reaper.SetTrackSelected(trackList[i], true) --SELECT
			reaper.Main_OnCommand(40358,1) --RANDOM COLORS
			reaper.SetTrackSelected(trackList[i], false) --DESELECT
		end
	end
end

local function GetZoom()
	zoomLevel = reaper.GetHZoomLevel()
	reaper.adjustZoom(200, 1, true, -1)
end

if CopyFile() == true then
	NewProject()
	PasteFile()
	NewTracks()
	GetZoom()
	reaper.SetMasterTrackVisibility(0)
	reaper.SetEditCurPos(0, true, true) -- Cursor 0
end


