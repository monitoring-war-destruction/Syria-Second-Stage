args city path outpath

*local path D:\Dropbox\Prediction Refugees\Results\other cities april 2020\

*make dense prediction merge
cd "`path'"

import delimited "testset.csv", varnames(1) clear
saveold testset.dta, replace

import delimited "`city'_noimages.csv", varnames(1) clear

merge 1:1 patch_id date city using testset.dta

export delimited using "`outpath'\prediction_`city'.csv", replace
