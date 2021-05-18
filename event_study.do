*********************************************************************************************************
* Replication File for the article: "Monitoring War Destruction from Space Using Machine Learning"
* Authors: H. Mueller, A. Groeger, J. Hersh, A. Matranga, and J. Serrat
* Input: Second-stage prediction output
* Output: Figure 5 (main article) and Table S2 (Supplementary Information)
* Program: Stata 14.2, 
*********************************************************************************************************

* ************************************
* ********** Preamble ****************
* ************************************

clear all
clear matrix
prog drop _all
pause off
set more off

*install required Stata packages
ssc install palettes
ssc install outreg2
ssc install coefplot

*Set paths ($path contains the second-stage prediction output files, $output will contain the exported figure/table)

global path ""
global output ""

* ************************************
* ****** Construct dataset ***********
* ************************************

*combine second-stage predictions by city

import delimited "$path\prediction_MLcleaned_all_aleppo.csv", clear 							
tempfile prediction_MLcleaned_all_aleppo
save `prediction_MLcleaned_all_aleppo'
import delimited "$path\prediction_MLcleaned_all_daraa.csv", clear 							
tempfile prediction_MLcleaned_all_daraa
save `prediction_MLcleaned_all_daraa'
import delimited "$path\prediction_MLcleaned_all_deir-ez-zor.csv", clear							
tempfile prediction_MLcleaned_all_deir
save `prediction_MLcleaned_all_deir'
import delimited "$path\prediction_MLcleaned_all_hama.csv", clear 							
tempfile prediction_MLcleaned_all_hama
save `prediction_MLcleaned_all_hama'
import delimited "$path\prediction_MLcleaned_all_homs.csv", clear 							
tempfile prediction_MLcleaned_all_homs
save `prediction_MLcleaned_all_homs'
import delimited "$path\prediction_MLcleaned_all_raqqa.csv", clear							
tempfile prediction_MLcleaned_all_raqqa
save `prediction_MLcleaned_all_raqqa'

append using `prediction_MLcleaned_all_aleppo'
append using `prediction_MLcleaned_all_daraa'
append using `prediction_MLcleaned_all_deir'
append using `prediction_MLcleaned_all_hama'
append using `prediction_MLcleaned_all_homs'

rename city join_city
encode join_city, gen(city) 
replace join_city="deir" if join_city=="deir-ez-zor"

*generate binary predictions based on second-stage random forest prediction (cutoff optimized to reach 50 percent recall in the test sample)

local target=0.5

preserve
gen tpr_target=`target'
drop if destroyed==.
gsort - random_forest_pred
generate positives = sum(destroyed)
generate negatives = sum(1-destroyed)
egen allpositives = total(destroyed)
generate precision=positives/(positives+negatives)
generate tpr = positives/allpositives
generate cutoff= random_forest_pred if tpr<tpr_target & tpr[_n+1]>=tpr_target
summarize cutoff
local cutoff=r(min)
restore 

generate pred_binary=random_forest_pred>`cutoff' //cutoff: 0.1489855

*merge with event data

replace date=subinstr(date, "-", "", 2)
destring date, replace
sort city patch_id date

bys city patch_id: gen wave=_n

*adjust city-waves to correspond to first time period available in 2016

replace wave=wave+1 if join_city=="daraa"
replace wave=wave+3 if join_city=="deir"
replace wave=wave+2 if join_city=="hama"
replace wave=wave+4 if join_city=="homs"
replace wave=wave+3 if join_city=="raqqa"

*merge LiveUAmap events

merge 1:1 join_city patch_id wave using "$path\liveuamap_events", force //3,668 cell-event obs merged

*declare panel structure

egen cell_id = group(city patch_id)
egen city_wave = group(city wave)
xtset cell_id wave

*generate binary indicators

foreach var of varlist event_bomb event_all {
gen bin_`var'=1 if `var'>0 & `var'!=.
replace bin_`var'=0 if bin_`var'==. & wave>7 & wave<21
}

*generate leads/lags

sort cell_id wave

foreach var of varlist event_bomb {
foreach num in 1 2 3 4 5 {
gen bin_`var'_L`num'=L`num'.bin_`var'
gen bin_`var'_F`num'=F`num'.bin_`var'
}
}

*replace missing values

foreach var of varlist bin_event_bomb bin_event_bomb_L1 bin_event_bomb_F1 bin_event_bomb_L2 bin_event_bomb_F2 bin_event_bomb_L3 bin_event_bomb_F3 bin_event_bomb_L4 bin_event_bomb_F4 bin_event_bomb_L5 bin_event_bomb_F5{
replace `var'=0 if `var'==. & wave>2
}

*generate event time variable

gen event_date=wave if bin_event_all==1
bysort cell_id (event_date): replace event_date=event_date[1]

*generate post dummy

sort cell_id wave
foreach var of varlist bin_event_bomb  {
gen help1=event_date+6
gen help2=1 if help1==wave & `var'_L5==1
bys cell_id: carryforward help2, gen(`var'_post)
replace `var'_post=0 if `var'_post==.
drop help*
}
 
* ************************************
* *********** Output *****************
* ************************************

*TABLE S2, COLUMN(1)

su random_forest_pred_sp if bin_event_bomb!=. //mean dependent variable

reghdfe random_forest_pred_sp  bin_event_bomb_F5 bin_event_bomb_F4 bin_event_bomb_F3 bin_event_bomb_F2 bin_event_bomb_F1 ///
           bin_event_bomb bin_event_bomb_L1 bin_event_bomb_L2 bin_event_bomb_L3 bin_event_bomb_L4 bin_event_bomb_L5 bin_event_bomb_post, absorb(cell_id  city_wave)  ///
           vce(cl cell_id)
		   
estimates store random_forest_pred_sp_all

outreg2 using "$output\tableS2_c1.tex", replace tex

*TABLE S2, COLUMN(2)

su random_forest_pred if bin_event_bomb!=. //mean dependent variable

reghdfe random_forest_pred  bin_event_bomb_F5 bin_event_bomb_F4 bin_event_bomb_F3 bin_event_bomb_F2 bin_event_bomb_F1 ///
           bin_event_bomb bin_event_bomb_L1 bin_event_bomb_L2 bin_event_bomb_L3 bin_event_bomb_L4 bin_event_bomb_L5 bin_event_bomb_post, absorb(cell_id  city_wave)  ///
           vce(cl cell_id)
		   
estimates store random_forest_pred_all

outreg2 using "$output\tableS2_c2.tex", replace tex

*FIGURE 5

colorpalette HTML, globals

coefplot  (random_forest_pred_sp_all, offset(-0.2) lab(Spatial smoothing only) msymbol(S) mlcolor(black) mfcolor($CornflowerBlue) ciopts(lcol($CornflowerBlue))) (random_forest_pred_all, offset(0.2) lab(Full spatial/temporal smoothing) msymbol(D) mlcolor(black) mfcolor(maroon) ciopts(lcol(maroon))),  fcol(maroon) col(maroon) drop(bin_event_bomb_post _cons) vertical  ///
           xline(5.5, lcolor(navy) lpattern(dash)) yline(0) scheme(s1mono) ///
		   coeflabels( bin_event_bomb_F5=  "-5"  bin_event_bomb_F4 ="-4" bin_event_bomb_F3 = "-3" bin_event_bomb_F2 ="-2" bin_event_bomb_F1 ="-1" ///
		   bin_event_bomb="0"  bin_event_bomb_L1= "+1" bin_event_bomb_L2 ="+2" bin_event_bomb_L3 ="+3" bin_event_bomb_L4 ="+4" bin_event_bomb_L5 ="+5") ///
		   ytitle(Coefficient) xtitle(Event time)
		   
graph export "$output\figure5", as(pdf) replace


