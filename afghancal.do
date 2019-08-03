  ** STATA CODE TO TRANSLATE PERSIAN TO GREGORIAN CALENDAR**
  
  
**BIRTH DATES**
*MOTHERS*
 gen v010g= v010+621 /* Gregorian year at 21 March of Year of Birth*/
 gen leapyear = mod(v010g+1,4)==0 /*is the February of the following year a leap year? */
 gen v009day = runiformint(1,31) if inrange(v009,1,6)
 replace v009day=runiformint(1,30) if inrange(v009,7,11)
 replace v009day=runiformint(1,29+leapyear) if v009==12 
  
 gen momdays= (v009-1)*31 + v009day if inrange(v009,1,6) /*momdays= days from 21 Mar*/
 replace momdays=186+(v009-7)*30+v009day if inrange(v009,7,12)
 
 gen DoB = mdy(3,21,v010g)+momdays
 format DoB %d
 gen v009g=month(DoB)
 replace v010g=year(DoB)
 gen v011g = (year(DoB)-1900)*12+v009g
 move v009g v009
 move v010g v010
 move v011g v011
 move DoB v011
 la var v009g "Gregorian month of birth"
 la var v010g "Gregorian year of birth"
 la var v011g "Gregorian CMC of birth"
 la var DoB "Gregorian DoB - imputed"
 drop leapyear momdays v009day

 * CHILDREN*
 gen v211temp = 9999 if v201!=0
 local border 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20
 foreach item of local border {
 gen b2g_`item'= b2_`item'+621 /* Gregorian year at 21 March of Year of Birth*/
 gen leapyear_`item' = mod(b2g_`item'+1,4)==0
 gen b1_`item'day = runiformint(1,31) if inrange(b1_`item',1,6)
 replace b1_`item'day=runiformint(1,30) if inrange(b1_`item',7,11)
 replace b1_`item'day=runiformint(1,29+leapyear_`item') if b1_`item'==12 
 
 gen kiddays_`item'= (b1_`item'-1)*31 + b1_`item'day if inrange(b1_`item',1,6) /*kiddays= days from 21 Mar*/
 replace kiddays_`item'=186+(b1_`item'-7)*30+b1_`item'day if inrange(b1_`item',7,12)
 
 gen DoB_`item' = mdy(3,21,b2g_`item')+kiddays_`item'
 format DoB_`item' %d
 gen b1g_`item'=month(DoB_`item')
 replace b2g_`item'=year(DoB_`item')
 gen b3g_`item' = (b2g_`item'-1900)*12+b1g_`item'
 drop kiddays_`item'
 drop leapyear_`item'
 drop b1_`item'day
 move b1g_`item' b1_`item'
 move b2g_`item' b2_`item'
 move b3g_`item' b3_`item'
 move DoB_`item' b3g_`item'
 la var b1g_`item' "Gregorian month of birth"
 la var b2g_`item' "Gregorian year of birth"
 la var b3g_`item' "Gregorian CMC of birth"
 la var DoB_`item' "Gregorian DoB - imputed"
 replace v211temp = b3g_`item' if b3g_`item' < v211temp
 }
ren v211 v211p
ren v211temp v211
move v211 v211p
la var v211 "Gregorian CMC date of first birth"


 
 **Marriage Dates**
 gen v508g= v508+621 /* Gregorian year at 21 March of Year of marriage*/
 gen leapyearmarr = mod(v508g+1,4)==0 /*is the February of the following year a leap year? */
 gen v507day = runiformint(1,31) if inrange(v507,1,6)
 replace v507day=runiformint(1,30) if inrange(v507,7,11)
 replace v507day=runiformint(1,29+leapyearmarr) if v507==12 
  
 gen marrdays= (v507-1)*31 + v507day if inrange(v507,1,6) /*marrdays= days from 21 Mar*/
 replace marrdays=186+(v507-7)*30+v507day if inrange(v507,7,12)
 
 gen DoM = mdy(3,21,v508g)+marrdays
 format DoM %d
 gen v507g=month(DoM)
 replace v508g=year(DoM)
 gen v509g = (year(DoM)-1900)*12+v507g
 move v507g v507
 move v508g v508
 move v509g v509
 move DoM v509
 la var v507g "Gregorian month of 1st cohabitation"
 la var v508g "Gregorian year of 1st cohabitation"
 la var v509g "Gregorian CMC of 1st cohabitation"
 la var DoM "Gregorian DoM - imputed"
 drop leapyearmarr marrdays v507day
 
 **INTERVIEW DATES**
 gen v007g= v007+621 /* Gregorian year at 21 March of Year of Birth*/
 gen intdays= (v006-1)*31 + v016 if inrange(v006,1,6) /*momdays= days from 21 Mar*/
 replace intdays=186+(v006-7)*30+v016 if inrange(v006,7,12)
 gen DoI = mdy(3,21,v007g)+intdays
 format DoI %d
 gen v006g=month(DoI)
 gen v008g = (year(DoI)-1900)*12+v006g
 drop intdays 
 move v006g v006
 move v007g v007
 move v008g v008
 move DoI v008
 la var v006g "Gregorian month of interview"
 la var v007g "Gregorian year of interview"
 la var v008g "Gregorian CMC of interview"
 la var DoI "Gregorian date of interview"

 
**SWAP GREGORIAN AND PERSIAN DATES**
rename v006 v006p
rename v006g v006
rename v007 v007p
rename v007g v007
rename v008 v008p
rename v008g v008
rename v009 v009p
rename v009g v009
rename v010 v010p
rename v010g v010
rename v011 v011p
rename v011g v011

rename v507 v507p
rename v507g v507
rename v508 v508p
rename v508g v508
rename v509 v509p
rename v509g v509

rename b1_(##) b1p_(##)
rename b2_(##) b2p_(##)
rename b3_(##) b3p_(##)
rename b1g_(##) b1_(##)
rename b2g_(##) b2_(##)
rename b3g_(##) b3_(##)
	
