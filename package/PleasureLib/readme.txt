PleasureLib

Shared UE4SS Lua helpers for Lenna's Gothic 1 Remake mods.

Includes an API for localized native ON/OFF settings under
Settings -> Game -> Mods.

Install this folder into the game's UE4SS Mods directory:

G1R/Binaries/Win64/ue4ss/Mods/PleasureLib/

Optional: add this line before dependent mods in Mods/mods.txt:

PleasureLib : 1

Dependent mods should still include their own fallback loader so players do not
need to edit mods.txt manually.

For mod authors, see the canonical documentation at:

https://github.com/89pleasure/G1R-PleasureLib/wiki
