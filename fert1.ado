capture program drop fert1
*! fert1 v1.1 10feb2019
program fert1
version 15.1
args path1 path2

global project_dir= "`path1'"
global working_dir= "`path2'" 

***************************************************
*****************_REFORMAT PATHS TO_***************
****_ADD A TRAILING '\' TO PATH IF NOT PRESENT_****
*******_AND THEN REPLACE ALL '\' WITH '/'_*********
***************************************************

if usubstr("${project_dir}",(ustrlen("${project_dir}")),1) != "\" {
global project_dir="${project_dir}"+"\"
}

if usubstr("${working_dir}",(ustrlen("${working_dir}")),1) != "\" {
global working_dir="${working_dir}"+"\"
}

global project_dir = subinstr("${project_dir}","\","/",99)
global working_dir = subinstr("${working_dir}","\","/",99)

global project_dir = strltrim("${project_dir}")
global working_dir = strltrim("${working_dir}")

cd "${project_dir}"

***************************************************
***************_END REFORMATTING OF PATHS_*********
***************************************************



***************************************************
*****_CHECK NECESSARY ADO FILES ARE INSTALLED_*****
*****_add other packages below e.g. spmap etc_*****
***************************************************
	foreach package in fs grstyle  {
 		capture which `package'
 		if _rc==111 ssc install `package'
	}
***************************************************
******************_END ADO CHECK_******************
***************************************************


***************************************************
***********_RUN THE VARIOUS DO FILES_**************
***************************************************
	do "prepare_birth_files.do"
	cd "${project_dir}"
	do "prepare_1st_birth_files.do"
	cd "${project_dir}"
	do "mediandates.do" 
	window stopbox note "You need to open outputdata.xlsx, force the recalculation of" /*
	 */ "the sheet, and allow the data table to update before proceeding." /*
	 */ " " "Press OK only once you are certain that this has been done."
	cd "${project_dir}"
	do "excel_to_stata_graphs.do"
	cd "${project_dir}"
	do "parity_nomore.do"
	cd "${project_dir}"
	do "final_graphs.do"
	cd "${project_dir}"
	do "choropleth8.do"


	display "Hello world!"
*****END RUN THE VARIOUS DO FILES*****

end
