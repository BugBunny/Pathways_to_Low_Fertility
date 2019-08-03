*
* Creates the digraphs.dta and graphdata4.dta file used to draw the figures 
* for the Pathways to Low Fertility paper
*
* Tom Moultrie and Ian Timaeus
*
* Last edited 2019-2-10
*
version 15.1
clear all
set more off
*macro drop _all
*global project_dir "C:/Users/ecpsitim/Documents/git/Stata/Pathways_to_Low_Fertility/"
*global project_dir "C:/Users/01404747/OneDrive - University of Cape Town/Academic/Applications and Projects/AfricanFertility2015/"
cd "${project_dir}001Figures"

* Create Stata digraphs file from master lists in Excel Inventory workbook
* adding in mediandates of first and last surveys
import excel using "${project_dir}DataInventory_All_3_programmes.xlsx", ///
	firstrow case(lower) clear
drop if exclude==1
keep country digraph region subregion
sort country
drop if country==""
duplicates drop
move digraph country
sort digraph
save "${project_dir}digraphs.dta",replace
import excel digraph=A earliest=B latest=C using ///
	"${working_dir}/003tempmediandates/mediandates.xlsx",  clear
destring earliest latest, replace
replace digraph=strupper(digraph)
merge 1:1 digraph using "${project_dir}digraphs.dta"
drop _merge
save "${project_dir}digraphs.dta",replace

* Import graphdata from Excel outputdata workbook and merge with digraphs
import excel using "../outputdata.xlsx", sheet("Data for Stata graphs") ///
	cellrange(A2:NP85) firstrow case(lower) clear
merge 1:1 digraph using "../digraphs.dta"
drop _merge
move country base_q60_1
move region base_q60_1
move subregion base_q60_1
move earliest base_q60_1
move latest base_q60_1

reshape long base_q60_ base_b60_ base_med_ base_cmed_ base_mode_ ///
	full_mod_tfr_ full_cmed_2_ full_cmed_3_ full_cmed_4_ full_cmed_5_ ///
	full_cmed_6_ full_cmed_7_ full_cmed_8_ full_cmed_9_ full_cmed_10_ ///
	full_cmed_11_  full_cmed_all_ full_ppr_0_ full_ppr_1_ full_ppr_2_ ///
	full_ppr_3_ full_ppr_4_ full_ppr_5_ full_ppr_6_ full_ppr_7_ full_ppr_8_ ///
	full_ppr_9_  full_b60_1_ full_b60_2_ full_b60_3_ full_b60_4_ full_b60_5_ ///
	full_b60_6_ full_b60_7_ full_b60_8_ full_b60_9_ full_b60_10_ ///
	full_b60_all_ full_m_9_ full_m_18_ full_m_24_ full_m_30_ full_m_36_ ///
	full_m_42_ full_m_48_ full_m_54_ full_m_60_ full_m_66_ full_m_72_ ///
	full_m_84_ full_m_96_ full_m_108_ full_m_120_ full_m_132_ full_m_144_ ///
	full_m_180_ un_tfr_, i(country) j(period)

ren base_q60_ base_q60
ren base_b60_ base_b60
ren base_med_ base_med
ren base_cmed_ base_cmed
ren base_mode_ base_mode
ren un_tfr_ un_tfr
ren full_mod_tfr_ full_mod_tfr
ren full_cmed_#_ full_cmed_#
ren full_cmed_all_ full_cmed_all
ren full_ppr_#_ full_ppr_#
ren full_b60_#_ full_b60_#
ren full_b60_all_ full_b60_all
ren full_m_#_ full_m_#

gen year = (period*5)+1957.5
drop period
order year, before(region)
drop if base_q60==. | base_q60<0.1
drop if year < earliest-20 | year>latest

gen full_ppr_1plus = (full_mod_tfr-full_ppr_0)/full_mod_tfr

* The q60 variables contain 60b60 using the notation adopted in the paper
gen full_q60_all = 1 - (1-full_ppr_1plus)/(1-full_b60_all)
forvalues i = 1/9 {
            local j = `i' + 1
            local ppr  "full_ppr_`i'"
            local b60 "full_b60_`i'"
            gen full_q60_`i' = 1 - (1-`ppr')/(1-`b60')
}

list country year un_tfr full_mod_tfr if abs(un_tfr- full_mod_tfr)>=2 & ///
	un_tfr!=. & full_mod_tfr!=. 
** Use this listing, combined with the inventory, to drop observations 
** >=30 years before earliest survey, and after latest survey ** 
*
* Flag the records that are only included in Figure 1 of th epaper
*
gen byte drop = 0
replace drop = 1 if country=="El Salvador" & year<1975
replace drop = 1 if country=="Benin" & year<1970

cd ..
save graphdata4.dta, replace
