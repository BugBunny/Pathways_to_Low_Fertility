* prepare_birth_files.do
* Tom Moultrie & Ian Timaeus

* (i)  Prepares 83 country-level birth-based files from 317 DHS/RHS/WFS surveys 
*      for the 'Pathways to Low Fertility' paper. 
* (ii) Models birth rates by parity, interval duration and quinqennium in each
*      country using Poisson regression. The coefficients are inserted in 
*      outputdata.xlsx
* N.B. First births by age and quniqennium are processed and modelled separately

**Housekeeping
version 15.0
clear all
set maxvar 10000

**Create list of surveys
cd "${working_dir}000DHS FL files/"
fs *.dta
local fname "`r(files)'"

**Build up macro containing 2-letter country codes from list of surveys
local ccode ""
local current_ccode ""
foreach fn1 of local fname {
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
capture confirm file "${working_dir}`dn1'/`dn1'.dta" 
if _rc!=0 {
	**Create local macro containing list of surveys for this country
	local cfname ""
	quietly foreach fn1 of local fname {
		if substr("`fn1'",1,2)=="`dn1'" {
			local cfname = "`cfname' `fn1'"
		}
	}
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
		drop v509
		rename udat_1 v509
		drop v1* v3* 
		capture drop u*
		capture drop x*
		capture drop s*
		capture drop f*
		
		mvdecode _all, mv(99 999 9999 =.a \ 88 888 8888 = .)
	
		local deadkids = v208 - v213
		local errmsg = cond(`deadkids'<=15, " ", "ERROR: MAX DEAD KIDS > 15")
	
		egen int year = median(int(v007/12))
		replace year = year + 1900
		gen str2 country = "`fn1'"
		egen marker = concat(country year)
		local marker = marker
		local country = country

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

		**Make birth order variables consistent by dropping leading zeros
		drop bsex_*
		rename bord_(##) b0_(##)
		rename bdat_(##) b3_(##)
		capture renpfix b0_0 b0_
		capture renpfix b3_0 b3_

		keep  b0_* b3_*  v007 v008 v011 v208 v509 v626 /*
			*/ v701-v705 id_mother DHS_wt year uniqclus uniqstrata
		
		* Assign DHS names and codes to the kept variables
		* (Other variables in the DHS will be set to . during the append)
		rename v011 v013
		rename v008 v011
		rename v007 v008
		gen v007 = int(v008/12)
		rename v208 v201

		rename v701 v101
		rename v702 v102
		rename v703 v103
		rename v704 v106
		rename v705 v108
				
		**Reshaping, renaming, and labelling

		reshape long b0_ b3_, i(id_mother) j(bord)
		ren b0_ b0
		ren b3_ b3
		label var bord "birth order number"
		label var b0 "child is twin"
		label var b3 "date of birth (cmc)"
		
		*Already done in the ISSA files but there's no harm in doublechecking
		drop if b0 == .

		gen long id = (year-1900)*1000000 + id_mother*100 + bord
		sort id
	}
	else if `RHS' {
	*===PROCESS THE RHS FILES==================================================	
		**Drop most of the variables (some p2* ones are used)
		capture drop p1* p3* p4* p5* p6* p7* p8* p9*
		capture rename mhpaquete seg
		capture rename mhnum cues
		capture rename mhcues cues
		capture drop mhp*		
		capture rename mpaquete seg
 		capture drop mp*
		capture replace cues = v001 if cues==.
		capture rename viv living
		capture rename vivo living
		capture drop v*
		
		mvdecode _all, mv(99 999 9999 =.a \ 88 8888 98 9898 = .)

		gen str2 country = "`fn1'"
		
		**Calculate year and cmc of interview
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

		**Create unique mother's ID (GT02 has duplicate questionnaire numbers)
		capture rename mhnum cues
		capture rename mhcues cues
		capture confirm numeric variable cues
		if _rc != 0 {
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
		sort cues entcmc mnaccmc hijocmc
		egen id_mother = group(cues entcmc mnaccmc)
		label var id_mother "unique identifier for woman"

		**Eliminate any cases with missing DoBs
		bys id_mother: egen flagDoB = count(hijocmc)		
		by id_mother: replace flagDoB = _N - flagDoB
		noisily drop if flagDoB>1

		** Calculate unique id for individual child
		sort id_mother hijocmc
		by id_mother: gen bord = _n
		gen long id = (year-1900)*1000000 + id_mother*100 + bord
		gen border = bord
		sort id_mother id

		**Create unique cluster and stata codes
		capture rename segcorr seg
		capture rename segment seg
		capture rename segmco1 seg
		capture rename mhpaquete seg
		capture rename mpaquete seg
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
		replace uniqstrata =`n_svy' * 10000+uniqstrata
		compress uniqstrata uniqcluster

		** Generate DHS woman's variables
		rename mnaccmc v011
		replace v011 = v011 - 1900*12 if country != "py" | v007 > 2000
		capture confirm numeric variable edad
		if _rc != 0 {
			capture confirm numeric variable p202edad
			if _rc == 0 {
				gen int edad = int(p202edad/5) - 2 /* es03 */
			} 
			else {
				gen int edad = int(p201ed/5) - 2 /* py95 & py98 */
			}
		}
		rename edad v013 
		capture rename regsal region
		rename region v101
		by id_mother: gen v201 = _N
		capture rename ecivil estciv
		* Simplify marital status to ever-married for calculation single below
		rename estciv v501
		if "`country'" == "gu" {
			recode v501 1=0 else=1
		}
		else {
			if "`country'" == "py" | "`country'" == "cr" {
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

		**Generate DHS birth variables
		rename nacmult b0
		replace b0 = b0[_n+1]-1 if b0[_n+1]>1 & id_mother==id_mother[_n+1]
		replace b0 = 1 if b0[_n+2]==3 & id_mother==id_mother[_n+2]
		rename hijocmc b3
		replace b3 = b3 - 1900*12 if country != "py" | v007 > 2000
		label var bord "birth order number"
		label var b0 "child is twin"
		label var b3 "date of birth (cmc)"
		
		by id_mother: egen tcd = sum(living==2)
		local deadkids = tcd
		drop tcd		
	
		keep year id_mother DHS_wt uniqstrata uniqcluster v007 v008 v011 /*
			*/ v013 v101 v201 v501 v509 id border bord b0 b3
	}
	else {
	*===PROCESS THE DHS FILES==================================================
		* Drop most of the variables
		drop v4* v6* v7* h* m*
		capture drop v8*
		capture drop s*
		capture drop d*
		capture drop w*
		
		**Create IDs (Allocate a sequence number to surveys within country)
		gen country = substr(v000,1,2)
		local deadkids = v206 + v207
		local errmsg = cond(`deadkids'<=15, " ", "ERROR: MAX DEAD KIDS > 15")

		* ET Data uses a coptic calendar
		if substr("`fn1'", 1, 2)=="et" {
			replace v008=v008+92
			replace v007=int((v008-1)/12)+1900
			replace v011=v011+92
			replace v509=v509+92
		}
		
		* NP Data uses a Nepalese calendar
		if substr("`fn1'", 1, 2)=="np" {
			if v000=="NP3" {
				replace v008=v008+519
				replace v007=int((v008-1)/12)+1900
				replace v011=v011+519
				replace v509=v509+519
			}
			else {
				replace v008=v008-681
				replace v007=int((v008-1)/12)+1900
				replace v011=v011-681

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
		gen long id_mother = _n
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
		
		egen v001a=group(v001)
		gen uniqcluster = `n_svy' * 10000 + v001a
		egen tempstrata=group(v101 v102)
		gen uniqstrata = `n_svy' * 10000 + tempstrata
		replace uniqstrata = `n_svy' * 10000 + v022 if v022 !=.
		compress uniqstrata uniqcluster
		drop tempstrata
		
		gen DHS_wt = v005/1000000
		
		keep bidx* bord* b0* b3* v000-v013 v020-v026 v10* v201 /*
		*/ v501 v509 id_mother DHS_wt year uniqclus /*
		*/ uniqstrata
	 
		**Make birth history variables consistent by dropping leading zeros
		capture renpfix bord_0 bord_
		capture renpfix bidx_0 bidx_
		capture renpfix b0_0 b0_
		capture renpfix b3_0 b3_
		**Reshaping, renaming, and labelling
		reshape long bord_ bidx_ b0_ b3_ , i(id_mother) j(border) 
		ren bord_ bord
		ren bidx_ bidx
		ren b0_ b0
		ren b3_ b3
		capture drop if bidx==.
		capture drop bidx* 
		capture drop bord0* 
		capture drop bord1* 
		capture drop bord2* 
		capture drop bord3* 
		capture drop bord4* 
		capture drop bord5* 
		capture drop bord6* 
		capture drop bord7* 
		capture drop bord8* 
		capture drop bord9*
		label var bord "birth order number"
		label var b0 "child is twin"
		label var b3 "date of birth (cmc)"
		gen long id = (year-1900)*1000000 + id_mother*100 + bord
		sort id
		
		* ET Data uses a coptic calendar
		if substr("`fn1'", 1, 2)=="et" {
			replace b3=b3+92
		}
		
		* NP Data uses a Nepalese calendar
		if substr("`fn1'", 1, 2)=="np" {
			if v000=="NP3" {
				replace b3=b3+519
			}	
			else {
				replace b3=b3-681
			}
		}
	sort id
	}
	*===END OF SEPARATE PROCESSING OF WFS, RHS AND DHS==========================
	
	**Save prepared survey file in working directory
	gen n_woman = _N
	local n_totN = `n_totN' + _N
	cd ..
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
	fs *.dta
	display r(files)
	local getfile "use "
	foreach file in `r(files)' {
			`getfile' `file'
			local getfile "append using "
	}
	
	gen DHS_wta=DHS_wt
	replace DHS_wt=DHS_wt*(`n_totN'/`n_svy')/n_woman
	drop n_woman
	order year id* uniq* DHS* border bord b0 b3 
	order v* , seq
	
	**Generate binary never-married at birth of previous child
	gen byte single = .
	replace single = 1 if (b3<v509 & v509 != .) | v501==0	
	replace single = 0 if b3>=v509 
		label variable single "Never Married"
	label define marriedlbl 0 "Ever married" 1 "Never married"
	label values single marriedlbl
	drop v509
	** Drop multiple births to get maternity intervals
	** N.B keep the last one so bord equals parity in the following interval
	sort year id_mother bord
	drop if b3==b3[_n+1] & id_mother==id_mother[_n+1]
	rename bord parity 
	sort year id_mother parity
	replace id = _n
	recode parity 11/max=10
	label variable parity "Parity at start maternity interval"
	**Code up interval durations
	gen enddate = b3[_n+1]
	replace enddate = v008 if id_mother != id_mother[_n+1]
	replace b3 = b3 - 1/6 if b3==v008
	**STSET data
	by year id_mother: gen byte closed = _n != _N
	noisily stset enddate, id(id) failure(closed==1) origin(b3) 
	**Split intervals into segments for hazard analysis 
	stsplit durseg, at (9 18 (6) 72 84 (12) 144 180) after(b3)
	label variable durseg "Birth interval duration segment"
	**Divide intervals into 5-year age groups
	stsplit motherage, at (180(60)600) after (v011)
	recode motherage min/179=1 180/239=2 240/299=3 300/359=4 360/419=5  /*
		*/ 420/479=6 480/539=7 540/599=8 600/max=9
	label define motherage 1"<15" 2"15-19" 3"20-24" 4"25-29" 5"30-34" /*
		*/ 6"35-39" 7"40-44" 8"45-49" 9"50+"
	label values motherage motherage
	label var motherage "Mothers age at exposure"
	
	* Divide intervals between five-year calendar periods
	stsplit fiveyrperiod, every(60) after(time=55*12+1)
	drop if fiveyrperiod <= 0
	replace fiveyrperiod = fiveyrperiod/60
	* The 1985 DHS in El Salvador collected five-year birth histories!
	capture drop if v000=="ES" & year==1985 & fiveyrperiod<=4
	label define fiveyrperiod 1"1960-64" 2"1965-69" 3"1970-74" /*
		*/ 4"1975-79" 5"1980-84" 6"1985-89" 7"1990-94" 8"1995-99" /*
		*/ 9"2000-04" 10"2005-09" 11"2010-14" 12"2015-2019"
	label values fiveyrperiod fiveyrperiod
	label var fiveyrperiod "Quinqennium at exposure"
		
	**Generate midpoint interval segment for use as continuous variable
	gen contdur = (_t0 + _t)/2
	label variable contdur "Midpoint of exposure segment"
	**Generate square and log of birth interval duration
	gen dursegsq = contdur^2
	label variable dursegsq "Square of interval duration"
	gen durseglog = ln(contdur)
	label variable durseglog "Log of interval duration"
	
	**Generate years from 1987.5 for use as continuous variable
	gen contdate = (b3 + contdur - 1051)/12
	label var contdate "Midpoint of segment relative to 30-6-1987"
	**Generate exposure variable
	gen exposure = _t - _t0
	noisily drop if exposure < 0.0001 | exposure==.
	label variable exposure "Exposure"
	
	**Survey set data on child's id
	svyset id [pw=DHS_wt], strata(uniqstrata) singleunit(centered)
	
	**Save file in working directory
	cd "${working_dir}"
	capture cd `dn1'
	if _rc != 0 {
		!md `dn1'
		cd `dn1'
	}
	compress
	save "`dn1'", replace
	cd "${working_dir}`dn1'"
	** Erase temporary files
	fs *_prep.dta
	quietly foreach file in `r(files)' {
		erase `file' 
	}
noisily display "All-survey file created for `dn1'"
}
}
*=========END: PROCEDURE TO SET UP DATA========================================
*=========ANALYSIS OF DATA=====================================================
foreach dn1 of local ccode {
cd "${working_dir}`dn1'"
capture confirm file "${working_dir}`dn1'/`dn1'.ster" 
if _rc!=0 {
	use `dn1', clear
	* Fixed characteristics (within interval): parity
	* Time-varying characteristics: interval duration, period, woman's age 
	*								(ever-used, never-mar)
	* Dimensions on which the _effects_ vary:
	* Effect fixed: woman's age
	* Varies by date: period, parity, (ever-use, never-marr)
	* Varies by interval duration only: duration segment
	* Varies by both duration and date: duration, duration^2, ln(duration)
	fvset base 2 parity
	fvset base 4 motherage
	fvset base 6 fiveyrperiod
	fvset base 30 durseg
	svy:poisson _d i.motherage i.parity i.fiveyrperiod i.durseg   /*
		*/ i.parity#c.contdate c.contdur#c.contdate               /*
		*/ c.contdur#c.contdur#c.contdate c.durseglog#c.contdate,  /*
		*/ e(exposure)
	estimates save `dn1'.ster, replace
	
	cd "${project_dir}"
	putexcel set outputdata, modify sheet(`dn1') 
	matrix temp1=r(table)
	matrix beta=temp1[1..1,1...]
	matrix pvalue=temp1[4..4,1...]
	local sysdate = c(current_date)
	local systime= c(current_time)
	putexcel A1="Current general model coefficients pasted at `sysdate' `systime'"
	putexcel A4="`dn1'"
	putexcel A5="`dn1'"
	putexcel B5="p-value"
	putexcel B2=matrix(beta), names
	putexcel C5=matrix(pvalue) 
}	
}

