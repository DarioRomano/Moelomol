# Playtest: the title screen and saving

**For:** the project lead. **Why:** saving is tested on Linux, but whether
the save file is replaced correctly on Windows and macOS, and how the title
feels with each controller, can only be checked on real machines.

**Build:** the PR build of `title-and-saving` on Windows, macOS and Linux.
The save is `save.json` in the game's user folder (Windows:
`%APPDATA%\Godot\app_userdata\Moelomol`; macOS: `~/Library/Application
Support/Godot/app_userdata/Moelomol`; Linux:
`~/.local/share/godot/app_userdata/Moelomol`).

## Checks

Write a short note for each: fine / problem (what), and the machine.

1. **First start:** only New game and Quit. New game: the farm, day 1,
   6:00. Result:
2. **Saving on each platform:** sleep at the farmhouse door; quit; start
   again. Continue says the next day at the farm, and resumes there. Then
   sleep again and restart (this replaces an existing save: the step most
   likely to differ on Windows). Result per platform:
3. **The gate:** go down to Millbrook, read a note, take the crank, quit.
   Continue: in Millbrook at the top of the lane, the note in the satchel,
   the crank in the bag. Come home, quit, continue: at the farm's gate.
   Result:
4. **Falling:** fall in Millbrook, quit, continue: at the farm, the next
   morning. Result:
5. **New game over a save:** asks first, "Keep it" chosen; B / Escape goes
   back. Result:
6. **Controllers:** the menu with an Xbox pad, a DualSense, a Switch Pro
   pad (if available) and the Steam Deck: D-pad and stick move, A presses,
   B goes back. Any double moves with the stick? Result:
7. **Mouse:** hovering chooses, clicking presses. Result:
8. **The picture:** the farmhouse at dusk, the lit window, the cat on the
   roof. Does it set the tone? Did you notice anything about the cat?
   Result:
9. **Losing progress:** quitting mid-day loses what was done since the
   last sleep or gate (ADR-0017). Acceptable while there is no pause menu?
   Result:
