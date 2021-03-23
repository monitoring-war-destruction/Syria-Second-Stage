args city path outpath

*local path D:\Dropbox\Prediction Refugees\Results\other cities april 2020\

*make dense prediction merge
cd "`path'"

import delimited "only_prediction.csv", varnames(1) clear
saveold grid_dense_prediction.dta, replace

import delimited "`city'_noimages.csv", varnames(1) clear

merge 1:1 patch_id date using grid_dense_prediction.dta

drop if _merge!=3
*drop image

generate pred_binary=prediction>0.731
replace pred_binary=. if prediction==.

egen totalpos=total(pred_binary*destroyed)
egen totaldestr=total(destroyed)
generate tpr=totalpos/totaldestr

summarize tpr
*drop pred_binary totalpos totaldestr tpr

keep city patch_id date prediction destroyed latitude longitude no_analysis
export delimited using "`outpath'\prediction_`city'.csv", replace
