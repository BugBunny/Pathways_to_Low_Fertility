*
* Produces figures for the Pathways to Low Fertility paper, together with
* the summary indices of the pattern of fertility change presented in Table A2
*
* Ian Timaeus and Tom Moultrie
*
* Last edited: 2019-11-22
*
* All these figures except Figure A4 use the graphdata4.dta file as input. This
* is created from the outputdata.xlsx sheet by excel_to_stata_graphs.do. Figure
* A.4 uses paritynomore.dta, which is produced by parity_nomore.do. Figure 3 is
* produced In Excel from outputdata.xlsx; Figure 7 is produced by choropleth8.do
* and finalised in Inkscape.
*
* The graphs are largely formatted using the grstyle package.
*
* The graphs for publication are exported as pdf's. The graphs can also be cut
* and pasted into Word as Windows EMFs or exported as png's for web use.
*
* (To suppress the figures and only produce Table A2, type global drawgraphs 0 
* at the command prompt before running fert1.ado / final_graphs.do)
*
*
version 15.1
clear all

cd "${project_dir}001Figures/"
scalar s_drawgraphs = strpos("$drawgraphs","0")~=1
*
* Use grstyle package to set up the appearance of the figures
*
graph set window fontface garamond
set scheme s2color
grstyle clear, erase
grstyle init
grstyle set graphsize 17cm 24cm
grstyle set plain, nogrid
grstyle set legend 6, nobox
grstyle anglestyle vertical_tick horizontal
grstyle set color YlGnBu, n(5)
grstyle set color gold: p1markline
grstyle set color teal: p2markline
grstyle set color emerald: p3markline
grstyle set symbol O D S T Th
grstyle anglestyle p5symbol 180
use "..\graphdata4.dta", clear
drop if full_mod_tfr==.

* Figure 2 - Comparison with UNPDs estimates of the TFR
if s_drawgraphs {
	#delimit ;
	twoway (scatter full_mod_tfr un_tfr if region=="Africa",
		  legend(label(1 "Sub-Saharan Africa")))
		(scatter full_mod_tfr un_tfr if region=="ex_USSR",
		  legend(label(2 "Europe and former USSR") size(small)))
		(scatter full_mod_tfr un_tfr if region=="LatAm",
		  legend(label(3 "Latin America")))
		(scatter full_mod_tfr un_tfr if region=="MENA",
		  legend(label(4 "Middle East and North Africa")))
		(scatter full_mod_tfr un_tfr if region=="S&EAsia",
		  legend(label(5 "South and Southeast Asia")))
		(line full_mod_tfr full_mod_tfr, lcolor(black)),
		legend(order(1 2 3 4 5) rows(2) region(lstyle(none)))
		xtitle("{bf:Total Fertility – United Nations Estimates}")
		ytitle("{bf:Parity-Age-Duration–Adjusted Total Fertility}") ;
	#delimit cr
	gr export "fig2.pdf", replace
}
* Drop 2 outlying sets of observations (Benin and Guatemala)
drop if drop
* Reductions in PPRs by order & Figure 4a
gen p0123 = full_ppr_0*full_ppr_1*full_ppr_2*full_ppr_3
gen p4567 = full_ppr_4*full_ppr_5*full_ppr_6*full_ppr_7
sort country year
by country: egen max3=max(p0123)
by country: egen min3=min(p0123)
by country: egen min7=min(p4567)
by country: egen max7=max(p4567)
by country: gen last3 = p0123[_N]
by country: gen last7 = p4567[_N]
gen reduc3 = max3-last3
gen reduc7 = max7-last7
regress reduc7 reduc3 if country~=country[_n-1]
gen p_indic = (max7-last7)>(max3-last3)+0.1
replace p_indic = -1 if (max7-last7)<(max3-last3)-0.1
label def pi -1"Smaller" 0"Similar" 1"Larger"
label val p_indic pi
drop min? max? last?
if s_drawgraphs {
	#delimit ;
	twoway  scatter reduc7 reduc3 if region=="Africa" ||
		scatter reduc7 reduc3 if region=="ex_USSR" ||
		scatter reduc7 reduc3 if region=="LatAm" ||
		scatter reduc7 reduc3 if region=="MENA" ||
		scatter reduc7 reduc3 if region=="S&EAsia" ||
		function y=x+.1, range(0 .7) lcolor(black) lpattern(dash) ||
		function y=x-.1, range(.1 .8) lcolor(black) lpattern(dash)|| ,
		  legend(off) ylabel(0(.2).8)
		xtitle("{bf:Reduction in Progression to the 4th Birth}")
		ytitle("{bf:Reduction in Progression from 4 to 8 Births}")
		title({bf:a. Reduction over Time in Progression across Higher and Lower Birth Orders},
		pos(11) size(medsmall))	name(fig4a, replace);
	#delimit cr
}
* Concavity & Figure 4b
gen work1 = full_ppr_4/2 + (full_ppr_5+full_ppr_3)/4
gen work2 = full_ppr_8/2 + (full_ppr_7+full_ppr_9)/4
gen slope4 = full_ppr_0-work1
gen slope8 = work1-work2
gen concave =  slope4/slope8
egen concavity = cut(concave), at (-20,0,1,3,30)
recode concavity -20=3
by country: replace concavity = concavity[_N]
label def concav 0"Convex" 1"Concave" 3"VConcave"
label val concavity concav
drop work? concave
if s_drawgraphs {
	#delimit ;
	twoway  scatter slope8 slope4 if region=="Africa" ||
		scatter slope8 slope4 if region=="ex_USSR" ||
		scatter slope8 slope4 if region=="LatAm" ||
		scatter slope8 slope4 if region=="MENA" ||
		scatter slope8 slope4 if region=="S&EAsia" ||
		function y=x, range(0 .4) lcolor(black) lpattern(dash) ||
		function y=x/3, range(0 0.7) lcolor(black) lpattern(dash)||
		if country~=country[_n+1], legend(off) ylabel(-.4(.2).4)
		xtitle({bf:Difference Between PPR{sub:0} and PPR{sub:4}})
		ytitle({bf:Difference Between PPR{sub:4} and PPR{sub:8}})
		title({bf:b. Recent Differences in Progression across Higher and Lower Birth Orders},
		pos(11) size(medsmall))	name(fig4b, replace);
* This third graph incorporates the legend
	#delimit ;
	twoway  scatter slope8 slope4 if region=="Africa",
		   legend(label(1 "Sub-Saharan Africa")) ||
		scatter slope8 slope4 if region=="ex_USSR",
		  legend(label(2 "Europe and former USSR")) ||
		scatter slope8 slope4 if region=="LatAm",
		  legend(label(3 "Latin America")) ||
		scatter slope8 slope4 if region=="MENA",
		   legend(label(4 "Middle East and North Africa")) ||
		scatter slope8 slope4 if region=="S&EAsia",
		   legend(label(5 "South and Southeast Asia")) ||
		if country~=country[_n+1], yscale(off) xscale(off)
		legend(order(1 2 3 4 5) rows(2)) name(lg, replace);
	#delimit cr
* Turn off drawing the plotregion
_gm_edit .lg.plotregion1.draw_view.set_false
* Stop combine expanding the legend's height to match the other graphs
_gm_edit .lg.ystretch.set fixed
grstyle set graphsize 24cm 17cm
graph combine fig4a fig4b lg, cols(1)
gr export "fig4.pdf", replace
grstyle set graphsize 17cm 24cm
graph drop fig4a fig4b leggraph
}
* Reduction in TFR
by country: egen maxtfr = max(full_mod_tfr)
by country: egen mintfr = min(full_mod_tfr)
by country: gen final_tfr = full_mod_tfr[_N]
gen reduc_tfr = maxtfr-final_tfr
gen decline = reduc_tfr<1.5
label def reduc 0" " 1"ΔTFR<1.5
label val decline reduc
gen byte pre_decline = final_tfr>6.5
label def pd 0" " 1"tfr>6.5"
label val pre_decl pd

* Increase in the conditional median
by country:egen minmed = min(full_cmed_all)
by country: gen lastmed = full_cmed_all[_N]
gen inc_med = lastmed - minmed
egen incr_cmed = cut(inc_med), at(0,3,6, 12, 96)
label def med 0"<3" 3"3-6" 6"6-12" 12 "12+"
label val incr_cmed med
drop minmed lastmed inc_med

* Final conditional median
by country: gen fcmed = full_cmed_all[_N]
egen final_cmed = cut(fcmed), at(0 42 48 100)
label def fcmed 0"<42" 42"42-48" 48"48+"
label val final_cmed fcmed
drop fcmed

* Postponement (difference & ratio of reductions in B(60) and 60q60) & Figure 6a
by country: gen firstb60 = full_b60_all[1]
by country: gen lastb60 = full_b60_all[_N]
by country: gen firstq60 = full_q60_all[1]
by country: gen lastq60 = full_q60_all[_N]
gen reducb60 = firstb60 - lastb60
gen reducq60 = firstq60 - lastq60
regress reducq60 reducb60 if country~=country[_n+1] & full_mod_tfr<6
gen resid = reducq60 - (_b[_cons] + _b[reducb60]*reducb60)
egen swivel60b60 = cut(resid), at(-10, -.05, .01, 50)
recode swivel60b60 -.05=0 .01=1
label def swiv -10"Rises" 0"Constant" 1"Drops"
label val swivel60b60 swiv
drop firstq60 lastq60
if s_drawgraphs {
	#delimit ;
	twoway (scatter reducq60 reducb60 if region=="Africa")
		(scatter reducq60 reducb60 if region=="ex_USSR")
		(scatter reducq60 reducb60 if region=="LatAm")
		(scatter reducq60 reducb60 if region=="MENA")
		(scatter reducq60 reducb60 if region=="S&EAsia")
		(function y = _b[_cons]+.01+_b[reducb60]*x, range(-.1 .45) lcolor(black)
			lpattern(dash))
		(function y = _b[_cons]-.05+_b[reducb60]*x, range(-.1 .45) lcolor(black)
			lpatt(dash))
		if country~=country[_n+1],
		xlab(-.1(.1).4) xtitle("{bf:Drop in progression within 60 months, {it:B}(60)}")
		ytitle("{bf:Drop in progression at 60–120 months, {sub:60}{it:b}{sub:60}}")
		title("{bf:a. Reduction in progression at long durations, compared with shorter durations}",
		pos(11) size(medsmall)) legend(off) name(fig6a, replace);
	#delimit cr
}
* Spacing (reductions in B(30) and 30b30) and Figure 6b
gen B30 = exp(-.75*full_m_9)*exp(-.5* full_m_18)*exp(-.5* full_m_24)
by country: gen firstB30 = B30[1]
by country: gen lastB30 = B30[_N]
gen reducB30 = lastB30-firstB30
gen reduc30b30 = (1-lastb60)/lastB30 -(1-firstb60)/firstB30
regress reducB30 reduc30b30 if country~=country[_n+1]
gen rightshift = reducB30 - (_b[_cons] + _b[reduc30b30]*reduc30b30)
gen spacing = cond(rightshift>0.125, "Large drop", /*
*/	cond(rightshift>0, "Drops","Rises"))
drop B30 firstB30 lastB30 firstb60 lastb60
if s_drawgraphs {
	#delimit ;
	twoway (scatter reducB30 reduc30b30 if region=="Africa")
		(scatter reducB30 reduc30b30 if region=="ex_USSR")
		(scatter reducB30 reduc30b30 if region=="LatAm")
		(scatter reducB30 reduc30b30 if region=="MENA")
		(scatter reducB30 reduc30b30 if region=="S&EAsia")
		(function y = _b[_cons] + 0.125 + _b[reduc30b30]*x, range(-.15 .35)
			lcolor(black) lpatt(dash))
		(function y = _b[_cons]+_b[reduc30b30]*x, range(-.15 .35) lcolor(black)
			lpatt(shortdash)) if country~=country[_n+1], ylabel(-.2(.2).4)
		xlab(-.1(.1).3) 
		xtitle("{bf:Drop in progression at 30–60 months, {sub:30}{it:b}{sub:30}}")
		ytitle("{bf:Drop in progression within 30 months, {it:B}(30)}") 
		legend(off) name(fig6b, replace)
		title("{bf:b. Reduction in progression at short durations, compared with intermediate durations}",
		pos(11) size(medsmall));
	#delimit ;		
	twoway (scatter reducB30 reduc30b30 if region=="Africa",
			legend(label(1 "Sub-Saharan Africa")))
		(scatter reducB30 reduc30b30 if region=="ex_USSR",
			legend(label(2 "Europe and former USSR")))
		(scatter reducB30 reduc30b30 if region=="LatAm",
			legend(label(3 "Latin America")))
		(scatter reducB30 reduc30b30 if region=="MENA",
			legend(label(4 "Middle East and North Africa")))
		(scatter reducB30 reduc30b30 if region=="S&EAsia",
			legend(label(5 "South and Southeast Asia"))),
		legend(order(1 2 3 4 5) rows(2)) 
		xscale(off) yscale(off) name(lg, replace);
	#delimit cr
* Turn off drawing the plotregion
_gm_edit .lg.plotregion1.draw_view.set_false
* Stop combine expanding the legend's height to match the other graphs
_gm_edit .lg.ystretch.set fixed
grstyle set graphsize 24cm 17cm
graph combine fig6a fig6b lg, cols(1)
gr export "fig6.pdf", replace
grstyle set graphsize 17cm 24cm
graph drop fig6a fig6b lg
}
* Generate classification of countries from summary indices
drop if country==country[_n-1]
gen postponing = cond(incr_cmed==0 & final_cmed==0 & swivel60b60>=0, 0, 1)
replace postponing = 0 if (incr_cmed==3 & swivel60b60==1) | ///
	(incr_cmed<12 & swivel60b60==1 & spacing=="Large drop") | ///
	(incr_cmed<=3 & swivel60b60>=0 & spacing=="Large drop")
replace postponing = 2 if incr_cmed==12 | final_cmed==48 | (incr_cmed==6 ///
	& final_cmed~=0 & swivel60b60<0)
gen byte classification = (final_tfr<6) * (1 + (postponing==1) ///
	+ (postponing==0)*2  + (concavity==1)*3 + (concavity==3)*6 ///
	+ (spacing=="Large drop")*9)
* ferttrans indicates the classification into pathways to low fertility
label def ferttrans 0 "Pre-transitional" 1"PP+_Limit" ///
	2"PP_Limit" 3"No_PP_Limit" 4"PP+_Mixed" 5"PP_Mixed"  ///
	6"No_PP_Mixed" 7"PP+_Stop" 8"PP_Stop" 9"No_PP_Stop" 10"PP+_Limit_Sp" ///
	11"PP_Limit_Sp" 12"No_PP_Limit_Sp" 13"PP+_Mixed_Sp" 14"PP_Mixed_Sp"  ///
	15"No_PP_Mixed_Sp" 16"PP+_Stop_Sp" 17"PP_Stop_Sp" 18"No_PP_Stop_Sp", replace
label val classification ferttrans

* Output results for Table A2, relabelling the regions in alphabetical order
replace region = "Eur&ex-USSR" if region=="ex_USSR"
replace subregion = "Eur&ex-USSR" if subregion=="ex_USSR"
replace subregion = "SouthEastAsia" if subregion=="SEAsia"
sort region subregion country year
tab1 p_indic concavity incr_cmed final_cmed swivel60b60 spacing ///
	if country~=country[_n-1]
list region subregion country final_tfr p_indic concavity incr_cmed  ///
	final_cmed swivel60b60 spacing classification ///
	if country~=country[_n-1], clean
pause on
pause Copy the table of entries for Table A2 if required. Then type end.
pause off

* Merge classification of countries to Natural Earth GIS data
gen NAME = country
replace NAME = "Dem. Rep. Congo" if NAME=="Congo (Dem. Rep.)"
replace NAME = "Kyrgyzstan" if NAME=="Kyrgyz Rep."
replace NAME = "eSwatini" if NAME=="Swaziland"
keep digraph region subregion country classification NAME
rename digraph DHS_digraph
sort NAME
preserve
	*cd "C:/Users/ecpsitim/temp/
	cd "${working_dir}004GIS/"
	use "ne_50m_admin_data.dta", clear
	keep _ID NAME REGION_UN REGION_WB ISO_A2
	sort NAME
	tempfile admindata
	save `admindata'
	*cd C:/Users/ecpsitim/Documents/git/Stata/Pathways_to_Low_Fertility_Private/
	cd "${project_dir}001Figures/"
restore
merge 1:1 NAME using `admindata'
tab _merge
drop _merge
sort country
save "..\choropleth8.dta", replace

if s_drawgraphs {
* Figure 5 - Median closed intervals against TFR
* Store a numeric list of regions in a matrix in alphabetical order of country
capture matrix drop R
use ../digraphs, clear
sort region
egen R = group(region)
sort country
mkmat R
* Identify the first country in the file for each region for the legend
foreach reg in "a" "e" "l" "m" "s" {
	local `reg' = 0
	}
local len = rowsof(R)
forvalues i = 1/`len' {
	if `a'==0 & R[`i',1]==1 local a = `i'
	if `e'==0 & R[`i',1]==5 local e = `i'	
	if `l'==0 & R[`i',1]==2 local l = `i'
	if `m'==0 & R[`i',1]==3 local m = `i'
	if `s'==0 & R[`i',1]==4 local s = `i'
	}
use "..\graphdata4.dta", clear
* Build list in `gr' of 83 country line commands with region-specific formats
local af_color `"gold "65 182 196" "51 117 172" "37 52 148" olive_teal "'
levelsof country, local(ctry)
foreach place in `ctry' {
	local pos: list posof "`place'" in local(ctry)
	local reg = R[`pos',1]
	* Use dashed lines for the African countries
	if `reg'==1 {
		local ls "shortdash"
	} 
	else {
		local ls "solid"
	}
	local cstyle: word `reg' of `af_color'
	local gr `"`gr' (line full_cmed_all full_mod_tfr if country=="`place'" "'
	local gr `"`gr' & full_mod_tfr<9, lcolor("`cstyle'") "'
	local gr `"`gr' lwidth("medthick") legend(on rows(2)) lpattern(`ls')) "'
}
#delimit ;
twoway `gr', ylab(24(12)60)  
	ytitle("{bf:Median Closed Interval (months)}") xscale(rev) xlab(2(2)8) 
	xtitle("{bf:Parity-Age-Duration–Adjusted Total Fertility}") 
	legend(order(`a' "Sub-Saharan Africa" `e' "Europe and former USSR" 
	`l' "Latin America" `m' "Middle East and North Africa" 
	`s' "South and Southeast Asia"))
#delimit cr
gr export "fig5.pdf", replace

* Convert to one record per quinquennium for Appendix figures A1 and A2
egen id = group(country year)
reshape long full_ppr_ full_b60_ full_cmed_ full_q60_ full_m_, i(id) j(order)
drop if order>9
rename full_ppr_ full_ppr
rename full_b60_ full_b60
rename full_q60_ full_q60
rename full_cmed_ full_cmed
replace country = "Central African Republic" if country=="Central African Rep."
replace country = "Kyrgyz Republic" if country=="Kyrgyz Rep."
replace country = "Dominican Republic" if country=="Dominican Rep."
replace country = "Congo (Democratic Rep.)" if country=="Congo (Dem. Rep.)"
replace country = "Congo (Republic)" if country=="Congo"
* Reinitialise graph style
grstyle set graphsize 21cm 29.7cm
grstyle set color hcl, viridis n(7)

* Figure A1 - PPRs
local quinquenlab `"label(1 "1965-1969") label(2 "1975-1979")"'
local quinquenlab `"`quinquenlab' label(3 "1985-1989") label(4 "1995-1999")"'
local quinquenlab `"`quinquenlab' label(5 "2005-2009") label(6 "2010-2014") "'
#delimit ;
twoway (line full_ppr order if year==1967.5 ||
	line full_ppr order if year==1977.5 ||
	line full_ppr order if year==1987.5 ||
	line full_ppr order if year==1997.5 ||
	line full_ppr order if year==2007.5 ||
	line full_ppr order if year==2012.5) if order<=9,
	subtitle(, fcolor(ltkhaki) lcolor(black) size(*.667)) by(country,
	iscale(*1.4) imargin(small) note("") rows(8)
	legend(at(84) pos(0))) legend(`quinquenlab' order(1 2 3 4 5 6) 
	rowgap(quarter_tiny) symxsize(10) size(large) cols(1)) ylab(0(0.2)1) 
	ytitle("{bf:Parity Progression Ratio}", margin(right) size(small))
	xlab(0(1)9) xtitle("{bf:Parity}", margin(top) size(small));
#delimit cr
graph save "figA1", replace
gr export "figA1.pdf", replace

* Figure A2 - Median closed intervals
local quinquenlab `"label(1 "1965-1969") label(2 "1975-1979")"'
local quinquenlab `"`quinquenlab' label(3 "1985-1989") label(4 "1995-1999")"'
local quinquenlab `"`quinquenlab' label(5 "2005-2009") label(6 "2010-2014") "'
#delimit ;
twoway (line full_cmed order if year==1967.5 ||
	line full_cmed order if year==1977.5 ||
	line full_cmed order if year==1987.5 ||
	line full_cmed order if year==1997.5 ||
	line full_cmed order if year==2007.5 ||
	line full_cmed order if year==2012.5) if order<=9,
	subtitle(, fcolor(ltkhaki) lcolor(black) size(*.667)) by(country,
	iscale(*1.4) imargin(small) note("") rows(8)
	legend(at(84) pos(0))) legend(`quinquenlab' order(1 2 3 4 5 6) 
	rowgap(quarter_tiny)  symxsize(10) size(large) cols(1))
	ylab(12(12)60) ytitle("{bf:Median Closed Birth Interval (months)}",
	margin(right) size(small)) xlab(1(1)9) xtitle("{bf:Birth Order}", 
	margin(top) size(small));
	#delimit cr
graph save "figA2", replace
gr export "figA2.pdf", replace

* Figure A3 - DSFRs: convert to one record per duration-segment
use "../graphdata4.dta", clear
replace country = "Central African Republic" if country=="Central African Rep."
replace country = "Kyrgyz Republic" if country=="Kyrgyz Rep."
replace country = "Dominican Republic" if country=="Dominican Rep."
replace country = "Congo (Democratic Rep.)" if country=="Congo (Dem. Rep.)"
replace country = "Congo (Republic)" if country=="Congo"
drop if full_m_9==. | drop
keep country-subregion full_m_*
egen id = group(country year)
reshape long full_m_, i(id) j(duration)
ren full_m_ full_m
local quinquenlab `"label(1 "1965-1969") label(2 "1975-1979")"'
local quinquenlab `"`quinquenlab' label(3 "1985-1989") label(4 "1995-1999")"'
local quinquenlab `"`quinquenlab' label(5 "2005-2009") label(6 "2010-2014") "'
#delimit ;
line full_m duration if year==1967.5
	|| line full_m duration if year==1977.5
	|| line full_m duration if year==1987.5
 	|| line full_m duration if year==1997.5
	|| line full_m duration if year==2007.5
	|| line full_m duration if year==2012.5,
	subtitle(, fcolor(ltkhaki) lcolor(black) size(*.667)) by(country,
	iscale(*1.4) imargin(small) note("") rows(8) legend(at(84) pos(0)))
	legend(`quinquenlab' order(1 2 3 4 5 6) rowgap(quarter_tiny) symxsize(10)
	size(large) cols(1)) ylab(0(0.2)1) xlab(0(36)180, labsize(small)) 
	ytitle("{bf:Fertility Rate}", margin(right) size(small)) 
	xtitle("{bf:Interval Duration (months)}", margin(top) size(small));
#delimit cr
graph save "figA3", replace
gr export "figA3.pdf", replace

* Figure A4 - Women who want no more children by survey
import excel using "../outputdata.xlsx", sheet("NoMore by parity") ///
	firstrow clear
merge m:1 digraph using "../digraphs.dta"
replace country = "Central African Republic" if country=="Central African Rep."
replace country = "Kyrgyz Republic" if country=="Kyrgyz Rep."
replace country = "Dominican Republic" if country=="Dominican Rep."
replace country = "Congo (Democratic Rep.)" if country=="Congo (Dem. Rep.)"
replace country = "Congo (Republic)" if country=="Congo"
drop if _merge!=3
* Surveys are re-numbered from last to 1st to get fewer "hot" lines. The labels 
* and their ordering are then "re-reversed" from 1st up.
grstyle set graphsize 21cm 29.7cm
grstyle set color hcl, viridis n(9)
#delimit ;
twoway 	(line meannomore parity10 if surveyno==1 & n>=50)
	(line meannomore parity10 if surveyno==2 & n>=50)
	(line meannomore parity10 if surveyno==3 & n>=50)
	(line meannomore parity10 if surveyno==4 & n>=50)
	(line meannomore parity10 if surveyno==5 & n>=50)
	(line meannomore parity10 if surveyno==6 & n>=50)
	(line meannomore parity10 if surveyno==7 & n>=50)
	(line meannomore parity10 if surveyno==8 & n>=50)
	(line meannomore parity10 if surveyno==9 & n>=50) if parity10<=9,
	subtitle(, fcolor(ltkhaki) lcolor(black) size(*.667))
	by(country, iscale(*1.4) imargin(small) note("") rows(8) legend(at(84)
	pos(0))) ylab(0(0.2)1) xtitle("{bf:Parity}", margin(top) size(small))
	xlab(0(1)9)	ytitle("{bf:Proportion of Women Wanting No More Children}",
	marg(right) size(small)) legend(colfirst label(1 "1st survey")
	label(2 "2nd survey") label(3 "3rd survey")	label(4 "4th survey")
	label(5 "5th survey") label(6 "6th survey")	label(7 "7th survey") 
	label(8 "8th survey") label(9 "9th survey")	size(medium) rowgap(0.1) 
	symxsize(8) cols(1));
#delimit cr
graph save "figA4", replace
gr export "figA4.pdf", replace
}
