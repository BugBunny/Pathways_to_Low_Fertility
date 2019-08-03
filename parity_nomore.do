* parity_nomore.do
*
* Builds collapsed file of % women wanting no more children by parity & survey 
* that is used for Figs 2 & A4 of the 'Pathways to Low Fertility' paper. Output
* file has 11 records for each DHS and WFS file in the "000DHS FL files" folder
*
* Last edited 2019-2-23
*
* Tom Moultrie & Ian Timaeus

**Housekeeping
version 15.1
set more off
clear all
set maxvar 10000
*macro drop _all
*global project_dir "C:/Users/ecpsitim/Documents/git/Stata/Pathways_to_Low_Fertility/"
*global working_dir "C:/Users/ecpsitim/Documents/Ian - static/"
capture erase "${project_dir}paritynomore.dta"

* PROCESS DHS FILES *

**Create list of surveys
cd "${working_dir}000DHS FL files"
fs ??????FL.dta
local fname "`r(files)'"

foreach dn1 of local fname {
		cd "${working_dir}000DHS FL files"
		use `dn1', clear
		
		* ET Data uses a coptic calendar
		if substr("`dn1'", 1, 2)=="et" {
			replace v008 = v008+92
			replace b3_01 = b3_01+92
			replace v007 = int(v008/12)+1900
			}
		* NP Data uses a Nepalese calendar
		if substr("`dn1'", 1, 2)=="np" {
			if v000=="NP3" {
				replace v008 = v008+519
				replace b3_01 = b3_01+519
				replace v007 = int(v008/12)+1900
				}
			else {
				replace v008 = v008-681
				replace b3_01 = b3_01-681
				replace v007 = int(v008/12)+1900
				}
			}
		*AF Data uses a Persian calendar
		if substr("`dn1'", 1, 2)=="af" {
		quietly do "${project_dir}afghancal.do"
		}
		
		keep v000 v201 v005 v007 v008 v501 v605 b3_01
		gen digraph = substr(v000,1,2)
		gen surveytype = "DHS"
		egen int year = median(v007)
		replace year = 100 if year==0
		replace year = year + 1900 if year < 200
						
		drop if v005==0 /* A few early surveys have records for refusals */
		gen DHS_wt = v005/1000000
		* Sample is married women with a birth in the last year or no child
		gen byte sample = ((v008-b3_01)<13 | v201==0) & inrange(v501,1,2)
		* Code of 6 means sterilized except in Wave 1, when it means infecund		
		gen byte wave1 = substr("`dn1'", 5, 1)=="0" 
		gen byte nomore = inrange(v605,5,6)
		replace nomore = v605==5 if wave1
		* Remove women who are infecund or missing on v506
		replace nomore = . if v605>=(7-wave1)
		drop if nomore==. | ~sample
		gen int parity10 = v201
		replace parity10 = 10 if inrange(parity10,10,90)
		collapse (mean) meannomore=nomore (count) n=v007 [aw=DHS_wt] ///
			, by (digraph year parity10 surveytype)
		cd "${project_dir}"
		capture confirm file "${project_dir}paritynomore.dta"
		if _rc!=0 {
			save "${project_dir}paritynomore.dta", replace
		}
		else {
			append using "${project_dir}paritynomore.dta"
			save "${project_dir}paritynomore.dta",replace
		}
}
*==END L0OP: PROCESSING OF DHS FILES ===================================
clear all

* PROCESS WFS FILES *

* Create list of surveys
cd "${working_dir}000DHS FL files"
fs ??WFS????.dta
local fname "`r(files)'"

foreach dn1 of local fname {
		cd "${working_dir}000DHS FL files"
		use `dn1', clear
		
		* Don't have to worry about non-standard calendars (Nepal) with WFS
		
		rename bdat_(##) bdat_(#)
		keep v006 v007 v008 v107 v208 v501 v503  bdat_1-bdat_24
		gen str2 digraph = strupper(substr("`dn1'", 1, 2))
		gen surveytype = "WFS"
		egen int year = median(1900+int(v007-1)/12)
		replace year = int(year)
		gen int bdat_0 = .
		
		drop if v006 == 0 /* A few early surveys have records for refusals */
		gen DHS_wt = v006/1000
		* Get date of her most recent birth for each woman		
		egen id=seq()
		reshape long bdat_, i(id) j(bord)
		keep if bdat<. | bord==0
		sort id bord
		keep if id~=id[_n+1]
		* Sample is married women with a birth in the last year or no child;
		* 4 LatAm WFS identified informal unions and asked women in them 
		* about their fertility preferences
		gen byte sample = ((v007-bdat_)<13 | v208==0) & (v107==1 | (v107<5 ///
			& digraph=="HT") | (v107<4 & inlist(digraph, "GY","MX","TT")))
		gen byte nomore = v503==1 | v501==2 if sample
		drop if nomore==.
		gen int parity10 = v208
		replace parity10 = 10 if inrange(parity10,10,90)
		collapse (mean) meannomore=nomore (count) n=v008 [aw=DHS_wt] ///
			, by (digraph year parity10 surveytype)
		compress
		cd "${project_dir}"
		capture confirm file "${project_dir}paritynomore.dta"
		if _rc!=0 {
			save "${project_dir}paritynomore.dta", replace
		}
		else {
			append using "${project_dir}paritynomore.dta"
			save "${project_dir}paritynomore.dta",replace
		}
}
*==END L0OP: PROCESSING OF WFS FILES ===================================
		
* Exclude SN and CM WFS data (all proportions "wanting no more" < 5%)
drop if digraph=="SN" & surveytype=="WFS"
drop if digraph=="CM" & surveytype=="WFS"

* Code to generate SURVEYNO		
sort parity10 digraph year
gen surveyno = 1 if parity10==0
replace surveyno = surveyno[_n-1]+1 if digraph==digraph[_n-1]
sort digraph year parity10
replace surveyno = surveyno[_n-1] if digraph==digraph[_n-1] & parity10!=0

compress
cd "${project_dir}"
export excel using "outputdata.xlsx", sheet("NoMore by parity") sheetreplace ///
	firstrow(variables)

/** The final version of Fig A4 is produced by final_graphs.do The final
* version of Fig 2 is produced in graphdata.xls using the proportions from 
* paritynomore.dta for the fourth panels of each country

merge m:1 digraph using "${project_dir}digraphs.dta"
drop if _merge!=3

set scheme s2color
grstyle clear, erase
grstyle init
grstyle set graphsize 21cm 29.7cm
grstyle set plain, nogrid
grstyle set legend 6, nobox
grstyle anglestyle vertical_tick horizontal
grstyle set color YlGnBu, ipolate(12)

replace surveyno = 13-surveyno

#delimit ;
twoway (line meannomore parity10 if surveyno==4 & n>=50)
	(line meannomore parity10 if surveyno==5 & n>=50)
	(line meannomore parity10 if surveyno==6 & n>=50)
	(line meannomore parity10 if surveyno==7 & n>=50)
	(line meannomore parity10 if surveyno==8 & n>=50)
	(line meannomore parity10 if surveyno==9 & n>=50)
	(line meannomore parity10 if surveyno==10 & n>=50)
	(line meannomore parity10 if surveyno==11 & n>=50)
	(line meannomore parity10 if surveyno==12 & n>=50) if parity10<=9, 
	subtitle(, fcolor(ltkhaki) lcolor(black) size(small))
	ytitle("Proportion wanting no more children", margin(right))
	by(country, iscale(*1.2) imargin(small) note("") rows(8) legend(at(84)
	pos(0))) ylab(0(0.2)1) xtitle("Parity", margin(top)) xlab(0(1)9)
	legend(order(12 11 10 9 8 7 6 5 4 - "" - "" - "") colfirst
	label(12 "1st survey") label(11 "2nd survey") label(10 "3rd survey")
	label(9 "4th survey") label(8 "5th survey") label(7 "6th survey")
	label(6 "7th survey") label(5 "8th survey") label(4 "9th survey")
	size(medium) rowgap(0.1) symxsize(8) cols(1));
#delimit cr
replace surveyno = 13-surveyno
grstyle set color YlGnBu, n(7)
* Extract example countries - Kenya
#delimit ;
twoway (line meannomore parity10 if surveyno==7 & n>=50) 
	(line meannomore parity10 if surveyno==6 & n>=50) 
	(line meannomore parity10 if surveyno==5 & n>=50) 
	(line meannomore parity10 if surveyno==4 & n>=50)
	(line meannomore parity10 if surveyno==3 & n>=50) 
	(line meannomore parity10 if surveyno==2 & n>=50) 
	(line meannomore parity10 if surveyno==1 & n>=50) if parity10<=10 
	& digraph=="KE", plotregion(lstyle(none)) 
	ytitle("Proportion wanting no more children", margin(right)) ylabel(0(0.2)1) 
	xscale(range(0 10)) xtitle("Parity", margin(top)) xlabel(0(1)9) 
	legend(order(7 6 5 4 3 2 1) label(7 "1977") label(6 "1988") 
	label(5 "1994")	label(4 "1999") label(3 "2005") label(2 "2010") 
	label(1 "2015") size(medsmall) rowgap(0.5) symxsize(10) cols(3) 
	region(lstyle(none)));
#delimit cr
* Extract example countries - India
#delimit ;
twoway (line meannomore parity10 if surveyno==4 & n>=50) 		
	(line meannomore parity10 if surveyno==3 & n>=50) 		
	(line meannomore parity10 if surveyno==2 & n>=50) 		
	(line meannomore parity10 if surveyno==1 & n>=50) if parity10<=10 
	& digraph=="IA", plotregion(lstyle(none)) 
	ytitle("Proportion wanting no more children", margin(right)) ylabel(0(0.2)1) 
	xscale(range(0 6)) xtitle("Parity", margin(top)) xlabel(0(1)10) 
	legend(order(4 3 2 1) label(4 "1993")	
	label(3 "1999") label(2 "2006") 
	label(1 "2015") size(mediumsmall) rowgap(0.5) symxsize(10) cols(4) 
	region(lstyle(none)));
#delimit cr
*/
