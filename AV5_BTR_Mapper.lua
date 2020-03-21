
bpm = reaper.Master_GetTempo()
--Constants
beatMult = 1
BEAT = 60/bpm*beatMult --Beat duration depending on BPM
tkp = " "
countDown = 1
holding_elapsed = 0
max_holding_time = 1
beatBuffer = BEAT*countDown
beatCounter = 1


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
	gfx.x, gfx.y = 50,50
	gfx.drawstr("Press Space Bar to Pause/Play"..
		"\nPress Escape to Exit"..
		"\nPress S to Save to map.csv"..
		"\nHit the track number key to add a beat"..
		"\nKey Pressed: "..tostring(keyPressed))
	gfx.update()
end


local function Update()
	elapsed = reaper.time_precise() - time_start
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
		if _key == 32 then reaper.Main_OnCommand(1008, 1, 0) end --Pause on SpaceBar
		if _key ==  49 then tkp = "1" CreateItem(1,1) end --a  97, q 113,  
	   	if _key == 50 then tkp = "2" CreateItem(2,1) end --s  w 119, 
	   	if _key == 51 then tkp = "3" CreateItem(3,1) end --d  e 101, 
	   	if _key == 52 then tkp = "4" CreateItem(4,1) end --f  r  114 
	   	ShowControls(tkp)
	end

	if elapsed > beatBuffer then --quantize positions
		ShowControls(tkp)
		beatBuffer = beatBuffer + BEAT
		beatCounter = beatCounter + 1
	end
	reaper.defer(Update)
end

time_start = reaper.time_precise() + reaper.GetPlayPosition()

local name, x, y, w, h = "Mapping Editor", 500, 300, 0, 1080 --UI
--SETUP
gfx.init(name, x, y, 0, w, h) --INITIALIZE WINDOW

ShowControls(tkp)
Update()





