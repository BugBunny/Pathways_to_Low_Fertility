* prepare_1st_birth_files.do
* Tom Moultrie & Ian Timaeus
* (i)  Prepares 83 country-level 1st birth files from 317 DHS/RHS/WFS surveys 
*      for the 'Pathways to Low Fertility' paper. 
* (ii) Models 1st birth rates by age and quinqennium in each country using 
*      Poisson regression. The coefficients are inserted in outputdata.xlsx

**Housekeeping
version 15.0
clear all
set maxvar 10000

*macro drop _all
* User-specific directory paths:
*  - Store the input files in a "000DHS FL files" sub-directory of working_dir
*  - Working files are saved in country-specific sub-directories of working_dir
*  - Final country files and fitted models are stored in country-specific 
*    sub-directories of project_dir. They are NOT replaced in later runs.



**Create list of surveys
cd "${working_dir}000DHS FL files/"
fs *.dta
local fname "`r(files)'"

**Build up macro containing 2-letter country codes from list of surveys
local ccode ""
local current_ccode ""
quietly foreach fn1 of local fname {
	if substr("`fn1'", 1, 2) != "`current_ccode'" {
		local current_ccode = substr("`fn1'", 1, 2)
		local ccode = "`ccode' `current_ccode'"
	}
}
capture log close

clear
set more off
*=====LOOP THROUGH COUNTRIES AND PROCESS EACH COUNTRY'S =======================
*=====SURVEYS IF NO ANALYSIS FILE YET EXISTS FOR IT============================
quietly foreach dn1 of local ccode {
capture confirm file "${working_dir}`dn1'/`dn1'1b.dta" 
if _rc!=0 {
	**Create local macro containing list of surveys for this country
	local cfname ""
	quietly foreach fn1 of local fname {
		if substr("`fn1'",1,2)=="`dn1'" {
			local cfname = "`cfname' `fn1'"
		}
	}
	display "`cfname'"
	*=====BEGIN:: BASIC PREPARATION OF FILES FOR A SPECIFIC COUNTRY============
	local n_totN=0
	local n_svy=0
	foreach fn1 of local cfname {
	cd "${working_dir}000DHS FL files/"

	local WFS = substr("`fn1'",3,3)=="wfs"|substr("`fn1'",3,3)=="WFS"
	local RHS = substr("`fn1'",5,2) == "f_"

	use `fn1', clear	
	local n_svy=`n_svy'+1
if `WFS' {
	*===PROCESS A WFS FILE=====================================================
		* Drop most of the variables
		drop v211 v501 v509
		capture rename bdat_# bdat_(##)
		rename bdat_01 v211
		rename utyp_1 v501
		rename udat_1 v509
		drop b*  v1* v3*
		capture drop u*
		capture drop x*
		capture drop s*
		capture drop f*
		
		mvdecode _all, mv(99 999 9999 =.a \ 88 888 8888 = .)

		egen int year = median(int(v007/12))
		replace year = year + 1900
		gen str2 country = "`fn1'"
		egen marker = concat(country year)
		local marker = marker
		local country = country

		* merge with awfactt if available
		gen awfactt = .
		cd awfactt
		capture confirm file "`country'_awfactt.dta"
		if _rc == 0 {
			noisily merge m:1 v010 using "`country'_awfactt.dta", update
		}
		cd ..
	
		* Create unique mother's ID
		sort v003
		gen id_mother = _n
		label var id_mother "unique identifier for woman"

		**Create unique cluster and stata codes
		gen int uniqcluster = `n_svy' * 10000+group(v004)
		egen uniqstrata = group(v003)
		replace uniqstrata = 0 if v003 == .
		replace uniqstrata =`n_svy' * 10000+uniqstrata
		compress uniqstrata uniqcluster

		gen DHS_wt = v006/1000

		keep  v007 v008 v011 v208 v211 v501 v509 v701-v705 /*
			*/ awfactt id_mother DHS_wt year uniqclus uniqstrata 
	
		* Assign DHS names and codes to the kept variables
		* (Other variables in the DHS will be set to . during the append)
		rename v011 v013
		rename v008 v011
		rename v007 v008
		gen v007 = int(v008/12)
		recode v501 8=0 9=.
		rename v208 v201
		rename v701 v101
		rename v702 v102
		rename v703 v103
		rename v704 v106
		rename v705 v108
	}
	else if `RHS' {
	*===PROCESS THE RHS FILES==================================================	
		**Append women's records from creadas sub-directory
		cd creadas
		local wom_file = substr("`fn1'",1,6)
		local wom_file = "`wom_file'creadas.dta"
		append using `wom_file', gen(wom)
		capture drop if mefsel==. & wom==1
		cd ..

		**Drop most of the variables (some p2* ones are used)
		capture drop p1* p3* p4* p5* p6* p7* p8* p9*
		capture rename mhpaquete seg
		capture rename mhnum cues
		capture rename mhcues cues
		capture drop mhp*		
		capture rename mpaquete seg
 		capture drop mp*
		capture replace cues = v001 if cues==.
		capture drop v*
		
		mvdecode _all, mv(99 999 9999 =.a \ 88 8888 98 9898 = .)

		**Create unique mother's ID (gt02 has duplicate questionnaire numbers)
		capture drop cuesi
		capture drop cuesind
		capture replace cues = cuest if wom==1
		capture confirm numeric variable cues
		if _rc != 0  {
			capture confirm numeric variable c5
			if _rc == 0 {
				gen cues = c1*10000 + c2*1000 + c3*100 + c4*10 + c5
			}
			else {
				capture confirm numeric variable d5
				if _rc == 0 {
					gen cues = d1*10000 + d2*1000 + d3*100 + d4*10 + d5
				}
				else {
					capture confirm numeric variable d4
					if _rc == 0 {
						gen cues = d1*1000 + d2*100 + d3*10 + d4
					}
				}
			}
		}
		replace cues = 0 if cues==. | cues == .a
		replace hijocmc=. if wom==1
		sort cues entcmc mnaccmc hijocmc
		egen id_mother = group(cues entcmc mnaccmc)
		label var id_mother "id for women (unique within survey)"
	
		**Drop entire case if woman has any with missing DoBs
		bys id_mother: egen flagDoB = count(hijocmc)		
		by id_mother: replace flagDoB = _N - flagDoB
		noisily drop if flagDoB>1
		drop flagDoB
		by id_mother: gen v201 = _N-1

		**Calculate child's birth order
		sort id_mother hijocmc
		by id_mother: gen bord = _n if wom==0
		**Drop all the higher-order births and the records of parous women
		drop if (bord~=1 & wom==0) | (id_mother==id_mother[_n-1] & wom==1)

		capture drop country
		gen str2 country = "`fn1'"
		
		**Calculate year and cmc of interview
		capture drop year
		gen int year = real(substr("`fn1'",3,2))
		gen int v007 = year
		capture confirm numeric variable entmes
		if _rc !=0 gen entmes = .
		gen int v008 = v007*12 + entmes
		replace year = 1900 + year + 100*(year<1942)		
		capture confirm numeric variable entcmc
		if _rc == 0 {
			replace v007 = int(entcmc/12) 
			replace v007 = v007 + 1900 if v007 < 1900
			replace v008 = entcmc 
			replace v008 = v008 - 1900*12 if v008 > (1900*12)
			drop year
			egen year = median(v007)
		}
		egen marker = concat(country year)
		local marker = marker
		local country = country

		**Create unique cluster and strata codes
		capture rename segcorr seg
		capture rename segment seg
		capture rename segmco1 seg
		if "`country'" != "py" capture rename sector seg
		capture rename segme seg
		capture rename segmei seg
		capture confirm numeric variable seg
		if _rc !=0 gen int seg = 0
		replace seg = 0 if seg == .
		egen uniqcluster = group(seg)
		replace uniqcluster = uniqcluster + `n_svy'*10000
		capture rename strata estrato
		capture confirm numeric variable estrato
		if _rc != 0 gen estrato = 0
		replace estrato = 0 if estrato == .
		egen uniqstrata = group(estrato)
		replace uniqstrata = uniqstrata + `n_svy'*10000
		compress uniqstrata uniqcluster

		** Generate DHS woman's variables
		rename hijocmc v211
		replace v211 = v211 - 1900*12 if v211>1900*12
		label var v211 "date of 1st birth (cmc)"
		rename mnaccmc v011
		replace v011 = v011 - 1900*12 if v011>1900*12
		* five-year age group
		capture confirm numeric variable edad
		if _rc != 0 {
			rename p201ed edad /* py98 */
			replace edad = int(edad/5) - 2
		}
		capt replace edad = int(p201ed/5)-2 if wom==0 & "`marker'"=="py1996"		
		capt replace edad = int(p202edad/5)-2 if wom==0 & "`marker'"=="es2003"
		rename edad v013 

		capture rename regsal region
		rename region v101
		* Simplify marital status to ever-married for calculation single below
		capture rename ecivil estciv
		rename estciv v501
		if "`country'" == "gu" {
			recode v501 1=0 else=1
		}
		else {
			if "`country'" == "py" | "`country'"=="cr" {
				recode v501 6=0 else=1
			}
			else {
				recode v501 max=0 else=1
			}
		}
		* Date of 1st marriage is rarely available
		* (though the variables may be hidden in a few more files)
		gen int v509 = .
		capture confirm numeric variable p224ano
		if _rc == 0 {
			replace v509 = p224ano*12 + p224mes
			replace v509 = p224ano*12 + int(1+uniform()*12) if v509 == .
		}
		
		rename pesomef DHS_wt
		replace DHS_wt = 1 if DHS_wt == .
		
		*Only keep the DHS compatible variables
		keep  v007 v008 v011 v013 v101 v201 v211 v501 v509 /*
			*/  year id_mother DHS_wt uniqstrata uniqcluster
		gen awfactt = .
	}
	else {
	*===PROCESS THE DHS FILES==================================================
		* Drop most of the variables
		drop v3* v4* v6* v7* h* m*
		capture drop v8*
		capture drop s*
		capture drop d*
		capture drop w*
		
		**Create IDs (Allocate a sequence number to surveys within country)
		gen country = substr(v000,1,2)

		* ET Data uses a coptic calendar
		if substr("`fn1'", 1, 2)=="et" {
			replace v008=v008+92
			replace v007=int((v008-1)/12)+1900
			replace v011=v011+92
			replace v211=v211+92
			replace v509=v509+92
		}
		
		* NP Data uses a Nepalese calendar
		if substr("`fn1'", 1, 2)=="np" {
			if v000=="NP3" {
				replace v008=v008+519
				replace v007=int((v008-1)/12)+1900
				replace v011=v011+519
				replace v211=v211+519
				replace v509=v509+519
				}
			else {
				replace v008=v008-681
				replace v007=int((v008-1)/12)+1900
				replace v011=v011-681
				replace v211=v211-681
				replace v509=v509-681
				}
			}
		
		*AF Data uses a Persian calendar
		if substr("`fn1'", 1, 2)=="af" {
		do "${project_dir}afghancal.do"
		}
		
		egen int year = median(v007)
		replace year = 100 if year==0
		replace year = year + 1900 if year < 200
		egen marker = concat(country year)
		local marker = marker
		local country = country
		* Sort on survey and identifiers and create unique woman's ID
		drop if v005 == 0 /* A few early surveys have records for refusals */
		sort v001 v002 v003
		gen id_mother = _n
		label var id_mother "unique identifier for woman"
		**Create unique cluster and strata codes for each survey
		capture confirm numeric variable v020
		if _rc != 0 {
			gen v020 = .
		}
		capture confirm numeric variable v021
		if _rc != 0 {
			gen v021 = .
		}	
		capture confirm numeric variable v022
		local errmsg2 ""
		if _rc != 0 {
			gen v022 = .
			local errmsg2 "** ERROR: V022 IS MISSING **"
		}	
		capture confirm numeric variable v023
		if _rc != 0 {
			gen v023 = .
		}	
		capture confirm numeric variable v024
		if _rc != 0 {
			gen v024 = .
		}	
		capture confirm numeric variable v025
		if _rc != 0 {
			gen v025 = .
		}
		capture confirm numeric variable v026
		if _rc != 0 {
			gen v026 = .
		}
		capture confirm numeric variable awfactt
		if _rc != 0 {
			gen awfactt = .
		}	
		
		egen v001a=group(v001)
		gen uniqcluster = `n_svy' * 10000 + v001a
		egen tempstrata=group(v101 v102)
		gen uniqstrata = `n_svy' * 10000 + tempstrata
		replace uniqstrata = `n_svy' * 10000 + v022 if v022 !=.
		compress uniqstrata uniqcluster
		drop tempstrata
		
		gen DHS_wt = v005/1000000
		
		* Find 1st births in ES file
		if substr("`fn1'", 1, 2)=="es" {
		local births "01 02 03 04 05 06"
		foreach birth of local births {
			replace v211 = b3_`birth' if bord_`birth'==1
		}
		}
		
		order v000, before(v001)
		keep v000-v013 v020-v026 v10* v201 v211 v501 v509  /*
		*/ awfactt id_mother DHS_wt year uniqclus uniqstrata
	 
		*==END:: BASIC PREPARATION OF FILES=====================================
	}
	*===END OF SEPARATE PROCESSING OF WFS, RHS AND DHS=========================
	gen n_woman = _N
	local n_totN = `n_totN' + _N
	**Save prepared survey file in working directory
	cd ..
	sort id_mother
	compress
	capture cd `country'
	if _rc != 0 {
		!md `country'
		cd `country'
	}
	save `marker'_prep.dta, replace
	noisily display "`fn1' `n_svy' `errmsg' `errmsg2' `n_totN' "
	}
*=========END OF PREPARATION OF INDIVIDUAL SURVEY FILES========================
*=========BEGIN: PROCEDURE TO CONCATENATE AND SET UP COUNTRY FILES=============
* need to install fs package: "ssc install fs", one time only
	clear
	fs *prep.dta
	display r(files)
	local getfile "use "
	foreach file in `r(files)' {
			`getfile' `file'
			local getfile "append using "
	}
**/ADDED HERE -- LINES TO SIMPLIFY MEDIAN DATES
	save "`dn1'1b", replace
	keep year
	save "${working_dir}/003tempmediandates/`dn1'yr.dta",replace
	use "`dn1'1b", clear
**/ END ADDED

	gen DHS_wta=DHS_wt
	replace DHS_wt=DHS_wt*(`n_totN'/`n_svy')/n_woman
	drop n_woman
	
	* Tidy up dataset
	sort year id_mother
	gen id = _n
 	order v* , seq
	order year id* uniq* DHS*		
	
	**Generate binary indicating pre-marital conception of first child
	gen byte pmc = .
	replace pmc = 0 if v509<.
	replace pmc = 1 if ((v211-rnormal(8.8,0.427))<v509 & v509<.) | v501==0
	drop v509
	
	label variable pmc "Pre-marital conception"
	label define marriedlbl 0 "Ever married" 1 "Never married"
	label values pmc marriedlbl
	**Code up interval durations
	gen enddate = v211
	replace enddate = v008 if v211==.
	**STSET data
	gen byte closed = v211<.
	gen age12 = v011 + 144
	noisily stset enddate, id(id) failure(closed==1) origin(age12) scale(12)
	**Split intervals into segments for hazard analysis 
	stsplit agegp, at (14 15 16 17 18 19 20 21 22 23 24 25 30 35 40 45) /*
		*/ after(v011)
	replace agegp = 12 if agegp==0
	label variable agegp "Age group"
	label define motherage 12"12-13" 25"25-29" 30"30-34" 35"35-39" 40"40-44" /*
		*/ 45"45-49"
	label values agegp motherage
	
	* Divide intervals between five-year calendar periods
	stsplit fiveyrperiod, every(5) after(time=55*12+1)
	drop if fiveyrperiod<=0
	replace fiveyrperiod = fiveyrperiod/5
	* The 1985 DHS in El Salvador collected five-year birth histories!
	capture drop if v000=="ES" & year==1985 & fiveyrperiod<=4
	label define fiveyrperiod  1"1960-64" 2"1965-69" 3"1970-74" /*
		*/ 4"1975-79" 5"1980-84" 6"1985-89" 7"1990-94" 8"1995-99" 9"2000-04" /*
		*/ 10"2005-09" 11"2010-14" 12"2015-2019"
	label values fiveyrperiod fiveyrperiod 
	label var fiveyrperiod "Quinqennium at exposure" 
		
	**Generate years from 1987.5 for use as continuous variable
	gen contdate = (age12/12 + (_t0+_t)/2 - 87.5833)
	label var contdate "Midpoint of segment relative to 30-6-1987"
	**Generate exposure variable, adding in single women if ever-married sample
	gen exposure = _t - _t0
	noisily drop if exposure < 0.0001 | exposure==.
	replace exposure = exposure * awfactt/100 if awfactt<.
	label variable exposure "Exposure"
	
	**Survey set data on mother's id
	svyset id [pw=DHS_wt], strata(uniqstrata) singleunit(centered)
	
	**Save file in working directory
	cd "$working_dir"
	capture cd `dn1'
	if _rc != 0 {
		!md `dn1'
		cd `dn1'
	}
	compress
	save "`dn1'1b", replace
	cd "${working_dir}`dn1'"
	** Erase temporary files
	fs *_prep.dta
	quietly foreach file in `r(files)' {
		erase `file' 
	}
noisily display "All-survey 1st birth file created for `dn1'"
}
}
*=========END: PROCEDURE TO SET UP DATA========================================
*=========ANALYSIS OF DATA=====================================================
foreach dn1 of local ccode {
cd "${working_dir}`dn1'"
capture confirm file "${working_dir}`dn1'/`dn1'1b.ster" 
if _rc!=0 {
	use "`dn1'1b", clear
	fvset base 20 agegp
	fvset base 6 fiveyrperiod
	svy:poisson _d i.agegp i.fiveyrperiod i.agegp#c.contdate, e(exposure)
	estimates save "`dn1'1b.ster"
	
	* Save estimates to outputdata.xlsx
	cd "${project_dir}"
	putexcel set outputdata, modify sheet("`dn1'") 
	matrix temp1=r(table)
	matrix beta=temp1[1..1,1...]
	matrix pvalue=temp1[4..4,1...]
	local sysdate = c(current_date)
	local systime= c(current_time)
	putexcel A10="Current first birth coefficients pasted at `sysdate' `systime'"
	putexcel A13="`dn1'"
	putexcel A14="`dn1'"
	putexcel B14="p-value"
	putexcel B11=matrix(beta), names
	putexcel C14=matrix(pvalue) 
}	
}


