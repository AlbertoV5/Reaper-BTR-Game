# Beat the Reaper Game V0.7

Small rhythm game for your Reaper Projects. Download Reaper: https://www.reaper.fm/download.php

### Description: 
Press keys to the beat of your song, achieve the highest score to show 
all of your clients your key pressing skills while producing bangers.

### Demo Videos
V0.1 video: https://www.youtube.com/watch?v=b7JHRZnzJrc

#### Use the scripts on EasyInstallNoLib for easier installation.

### Installation: 
1. Place all BTR scripts in the same directory.
2. Open Reaper -> Actions -> Show Action List -> Reascript -> Load...
3. Add AV5_BTR_Setup and AV5_BTR_Game to your Actions. You can add hotkeys or put them in a toolbar.
4. Select the music track you want to play with and Run AV5_BTR_Setup.
5. After the session is created, run AV5_BTR_Game.
6. Have fun :)

### Beat Mapping Editor
1. Run the BTR_Setup script to set up your session.
2. Load and run BTR_Mapper to start editing.
3. Follow controls on UI, use "s" to save all current items on tracks 1 to 4.
4. A .json file is created on your project path.
5. Run BTR_Game and start playing to your own mapping.

### How to Play:
1. The project will play and items will appear on your edit window.
2. Try to hit your 1 2 3 4 keys according to the tracks 1 2 3 4 to delete the items.
3. If you do it on beat, you'll get a point, if you miss you will lose a point.

### Changelog:
Version 0.7
- Added Beat Mapper functionality
- Added Load custom map functionality
- Changed Update function to reduce load
- Added automatic song length calculation

### To Do:
1. Improve UI. Controls on screen.
2. Improve check for valid items algorithm.
3. Add shorter and longer notes.

#### Script by Alberto Valdez at av5sound.com and u/Sound4Sound
