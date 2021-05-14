args path outpath
cd "`path'"

import delimited "performance_stats.csv", clear

generate totalsamples=labels+labels1
generate sharepositive=labels1/totalsamples
drop date
preserve
keep city numberofdates obs totalsamples sharepositive 
export excel using "`outpath'\table1", firstrow(variables) replace
restore

keep city avprecision_1 avprecision_sp avprecision_full auc_full
order city avprecision_1 avprecision_sp avprecision_full auc_full

export excel using "`outpath'\table2", firstrow(variables) replace
