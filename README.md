# Pathways to Low Fertility
*Excel* sheets, *Stata* do files and other resources related to the 2020 article in *Demography* [Pathways to Low Fertility: 50 Years of Limitation, Curtailment, and Postponement of Childbearing](https://doi.org/10.1007/s13524-019-00848-5) by Ian Tim&aelig;us and Tom Moultrie.

## The dataspace

The project makes use of DHS, WFS, and RHS data, all of which contain full birth history data allowing the segmentation into fine lexis spaces of women's family formation processes. A listing of the data sets used is contained in *DataInventory.xlsx*. All publicly-accessible data from the 3 programmes are used, barring data from 9 WFS for countries in which no subsequent survey is available; and 2 DHS files (from Senegal) where data in the excluded files are duplicated in other files from the continuous DHS.

## Running the model

The model is built off the results of two separate statistical regression models. The first examines parity progression by age, duration, parity and time; the second examines entry into motherhood - that is, the risk of a first birth. Outputs from both regression models are used to develop an age-duration-parity-time model of fertility as outlined in [Timæus and Moultrie (2013)](httsp://doi.org/10.1017/S0021932012000648).

### 1. Getting started

All the code to prepare the outputs is contained in a *Stata* ado file (*fert1.ado*) which calls a number of do files in sequence. The output from the two regression models is written automatically to an *Excel* workbook (*outputdata.xlsx*). This spreadsheet then constructs the age-duration-parity-time fertility model and produces estimates that are then re-read into *Stata* to produce the tabulations, figures, and classifications in the main paper.

#### *fert1.ado*

To run the models, the version of *fert1.ado* on this site must be downloaded, and saved in your personal ado *Stata* directory. By default, this is `c:\ado\personal`

Two distinct paths are available to users seeking to reproduce the results. We have opted to place all command line do files and output in a project directory; and all input data and ancillary files in a second path, described by a working directory. Other users may prefer to use just the one. The required structures of those directories is set out below

#### Working directory structure

The root of the working directory must contain the following subdirectories:

- `workingdirectorypath/000DHS FL Files`, containing the original stata-formatted individual recode files from the DHS, WFS and RHS.
- `workingdirectorypath/003tempmediandates`, used as a repository for working with the various survey dates
- `workingdirectorypath/004GIS_data`, containing the shapefiles used in the production of the maps
- `workingdirectorypath/005paritynomore`, used as a repository for data created to analyse desire for more children by parity

The root of the project directory must contain the eight do files available on *GitHub*:

- *afghancal.do*
- *prepare_birth_files.do*
- *prepare_1st_birth_files.do*
- *mediandates.do*
- *excel_to_stata_graphs.do*
- *parity_nomore.do*
- *final_graphs.do*
- *choropleth8.do*

together with:

- the master output *Excel* workbook (*outputdata.xlsx*)
- the subdirectory  `projectdirectorypath/001Figures`, where output figures are stored.

### 2. Running the models

After installing *fert1.ado* in the appropriate directory, the syntax to run the models is
```
fert1 "path1" "path2"
```
where `path1` is the full path to the project directory and `path2` is the full path to the working directory.

Both paths, even if identical, must be specified. Each path must be encapsulated in double quotes (`"c:\ ... \ ..."`). For programming reasons, the ado file converts backslashes to forward slashes, and ensures that a trailing forward slash is present. For users, the easiest way to copy these paths is from within *Windows Explorer*. Navigate to your preferred path, and then right click the path and select 'Copy address as text'. This can then be pasted into *Stata* (with leading and trailing quotes).

The two prepare files perform the initial manipulations of the data files and prepare them for modelling. Data from multiple surveys from a single country are combined, preserving the sampling and weighting aspects of each survey. These files, which are then used in the regression model are stored in subdirectories of the root project directory, labelled with the DHS digraph for each country. The regression model is then run on the aggregated files in each country-digraph labelled directory. The results (coefficients and p values) are saved as stata regression outputs (_*.ster_), as well as written to a digraph-labelled sheet in *outputdata.xlsx*. Every time a model is run, date- and time-stamps are placed in the country-specific worksheets in *outputdata.xlsx*.

*afghancal.do* handles data from Afghanistan, which runs off a Persian calendar. This calendar is less easily manipulated than either the Coptic (Ethiopia) or Nepal Sambat (Nepal) calendars, which are handled directly within the prepare files.

The other do files are described in [4] below.

### 3. Production of output

The principal output of the model is in the form of a very large *Excel* workbook (*outputdata.xlsx*). There is one sheet per country, labelled with the DHS digraph for that country, containing the current modelled betas (coefficients) and their associated *p*-values from each of the two regressions performed.

These coefficients are then aggregated into four sheets, containing all coefficients and *p*-values for each country, from both regression models. These sheets are labelled:

- GM Coefficients: the general model betas
- GM pvalues: the general model *p*-values,
- 1b Coefficients: the first birth model betas
- 1b pvalues: the first birth model *p*-values

Output for a specific country, including figures equivalent to those in Fig. 2 of the paper can be obtained in the 'Fitted results' sheet by changing the country digraph in the dropdown box in cell C1. A data table, beginning at Cell B158 on this sheet contains all results for all countries, and is populated by means of recalculation.

The 'Digraphs and TFRs' sheet contains a list of digraphs, country names, as well as the series of TFRs from 1950-55 through to 2010-15 as derived from the UN Population Division's *[World Population Prospects](https://population.un.org/wpp/)* (currently using the 2017 edition). For new releases of the *WPP*, or when new countries are added to the model, the data in columns F:S of this sheet must be updated. After running *mediandates.do*, a window pops up in *Stata* requiring that *outputdata.xlsx* is opened, to allow certain data tables to be updated. Once the file has opened, press F9 to recalculate the sheet (it takes some time!), and resave it, with the same name in the same location. Having done that, click on "OK" on the popup window to allow processing of the data to proceed.

### 4. Production of tables and figures

The *mediandates.do* file simply records from the median date of each survey in each country, the median earliest and latest dates of the surveys conducted in each country. The output is stored in the `/003tempmediandates directory`, with output being written to an *Excel* file.

*excel_to_stata_graphs.do* reads in the contents of the *Data_Inventory.xlsx file* - a master list (useful for record keeping purposes) of exactly which files are contained in `c:\ ... \000DHS FL Files`. This workbook also holds the master list of regions and subregions. Edits and changes made here will govern the allocation of countries to regions and subregions in all the subsequent analysis. The do file then reads in the 'Data for Stata graphs' sheet of *outputdata.xlsx*, and merges this with the data on the earliest and latest median survey dates. The output data are reshaped to produce one record per country-quinquennium. Minor adjustments are made to the final data before they are saved as *graphdata4.dta*.

*parity_nomore.do* computes the proportions of not-declared-infecund married women who gave birth in the 12 months preceding each survey who respond that they want no more children. The resulting dataset (paritynomore) is stored in the 'NoMore by parity' sheet in *outputdata.xlsx* and used to produce Figures 3 and A4.

The production of all figures included in the paper, including the web appendix, is automated in two do files, *final_graphs.do* and *choropleth8.do*. The former file produces all figures, other than maps, as well as Table 2, the listing of diagnostics used to classify countries. It also writes out an working file *choropleth8.dta*. In the final step of the analysis, *choropleth8.do* uses the the latter file and *[NaturalEarth](https://www.naturalearthdata.com/)* 4.1.1 shapefiles to prepare the maps.
