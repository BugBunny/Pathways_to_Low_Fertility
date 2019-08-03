*
* Draws the L. America and Old World maps in Figure 8 of the Pathways paper
*
* Ian Timaeus and Tom Moultrie
*
* Last modified: 2019-7-12
*
* THIS VERSION IS DESIGNED FOR USE WITH THE NATURAL EARTH 50m GRID SHAPE DATA 
*
* N.B the colours are repeated for countries in which spacing does and does not 
* occur; the legend is edited in graph editor; and the graph is pasted into 
* Inkscape to add cross-hatching to the spacing countries. Finally, the two 
* maps are pasted together in Powerpoint.
*
version 15.1

* Exit immediately if redrawing of the figures has been suppressed
if strpos("$drawgraphs","0")==1 exit

clear all

* Store the location of the coordinate file in a local macro
local GIS_coords "${working_dir}004GIS_data/ne_50m_admin_coord.dta"
if strlen("$working_dir") == 0 {
	local GIS_coords "C:/Users/ecpsitim/temp/004GIS/ne_50m_admin_coord.dta"
}

local project_dir "$project_dir"
if strlen("$working_dir") == 0 {
	local project_dir "C:/Users/ecpsitim/Documents/git/Stata/"
	local project_dir "`project_dir'Pathways_to_Low_Fertility_Private/"
}
cd "`project_dir'001Figures/"
use "../choropleth8.dta", clear

* Tidy up map
drop if _ID==.
drop if REGION_UN=="Seven seas (open ocean)" | REGION_WB=="Antarctica"
* Add in extra country outlines needed to link up our countries on the maps
replace region = "LatAm" if region=="" & REGION_WB=="Latin America & Caribbean" 
replace region = "Africa" if region=="" & REGION_WB=="Sub-Saharan Africa"
replace region = "MENA" if region=="" & ISO_A2~="MT" & /// leave out Malta
	REGION_WB=="Middle East & North Africa"
replace region = "S&EAsia" if region=="" & (REGION_WB=="South Asia" ///
	| inlist(ISO_A2, "LA", "MY")) // add in Laos and Malaysia
replace region = "Eur&ex-USSR" if NAME=="Northern Cyprus" | ///
	inlist(ISO_A2,"BG","CY","GR","RO","MK","TM") // add Balkans and Turkmenistan
	
gen oldworld = region~="LatAm" if region~=""

* Limiting vs curtailment
gen classif_1 = classification
replace classif_1 = 1 if inlist(classification, 1,2,3,10,11,12)
replace classif_1 = 2 if inlist(classification, 4,5,6,13,14,15)
replace classif_1 = 3 if inlist(classification, 7,8,9,16,17,18)

local colours1 `" "255 245 216" "106 81 163" "107 174 214" "187 222 205" "'

local map_opts `"clm(custom) clbreak(-1 0 1 2 3) "'
local map_opts `"`map_opts' id(_ID) fcolor(`colours1') "'
local map_opts `"`map_opts' plotregion(color(none)) mosize(none) "'
local map_opts `"`map_opts' osize(vthin ...) ndsize(vthin)"'

*Latin America map
grmap classif_1 using "`GIS_coords'" ///
  if (region=="LatAm" & ~inlist(ISO_A2,"AR","CL","FK","UY")) | ISO_A2=="GF", ///
  `map_opts' legenda(off)  
graph save Graph "LAmer_1.gph", replace

* Old World map
grmap classif_1 using "`GIS_coords'" if oldworld==1, `map_opts' legenda(on) 
graph save Graph "OldWorld_1.gph", replace

* Postponement & spacing
gen classif_2 = classification
replace classif_2 = 1 if inlist(classification, 1,4,7)
replace classif_2 = 2 if inlist(classification, 2,5,8)
replace classif_2 = 3 if inlist(classification, 3,6,9)
replace classif_2 = 4 if inlist(classification, 10,13,16)
replace classif_2 = 5 if inlist(classification, 11,14,17)
replace classif_2 = 6 if inlist(classification, 12)

local colours2 `" "255 245 216" "106 81 163" "106 127 188" "187 222 205" "'
local colours2 `" `colours2' "106 81 163"  "106 127 188" "187 222 205" "'

local map_opts `"clm(custom) clbreak(-1 0 1 2 3 4 5 6) "'
local map_opts `"`map_opts' id(_ID) fcolor(`colours2') "'
local map_opts `"`map_opts' plotregion(color(none)) mosize(none) "'
local map_opts `"`map_opts' osize(vthin ...) ndsize(vthin)"'

*Latin America map
grmap classif_2 using "`GIS_coords'" ///
  if (region=="LatAm" & ~inlist(ISO_A2,"AR","CL","FK","UY")) | ISO_A2=="GF", ///
  `map_opts' legenda(off)  
graph save Graph "LAmer_2.gph", replace

* Old World map
grmap classif_2 using "`GIS_coords'" if oldworld==1, `map_opts' legenda(on) 
graph save Graph "OldWorld_2.gph", replace

