**THIS FILE CREATES A LIST OF THE EARLIEST AND LATEST MEDIAN SURVEY DATES*
* Tom Moultrie & Ian Timaeus

**Housekeeping
version 15.1
clear all
set maxvar 10000

cd "${working_dir}/003tempmediandates"


**Create list of surveys
fs *yr.dta
local fname "`r(files)'"

**Build up macro containing 2-letter country codes from list of surveys
local ccode ""
local current_ccode ""
foreach fn1 of local fname {
		local current_ccode = substr("`fn1'", 1, 2)
		local ccode = "`ccode' `current_ccode'"		
	}

display "`ccode'"
capture log close
set more off
local xxx=5
*=====LOOP THROUGH COUNTRIES =======
quietly foreach dn1 of local ccode {
	local cellref1 ""
	local cellref2 ""
	local cellref3 ""
	
	use `dn1'yr.dta,clear
	egen earliest = min(year)
	egen latest = max(year)
	keep in 1
	
	local earl= earliest
	local late = latest
	
	noisily display "`dn1'" " " "`xxx'" " " "`earl'" " " "`late'"
	
	local cellref1 A`xxx'
	local cellref2 B`xxx'
	local cellref3 C`xxx'
	putexcel set mediandates, modify 
	putexcel `cellref1'="`dn1'"
	putexcel `cellref2'="`earl'"
	putexcel `cellref3'="`late'"
	local xxx=`xxx'+1
	}

