args path outpath
cd "`path'"

import delimited "performance_stats.csv", clear

generate totalsamples=labels+labels1
generate sharepositive=labels1/totalsamples
drop date
preserve
keep city numberofdates obs totalsamples sharepositive 
export excel using "`outpath'\summarystats", firstrow(variables) replace
restore

keep city sharepositive auc_full avprecision1to1_1 avprecision1to1_sp ///
avprecision1to1_full avprecision_1 avprecision_sp avprecision_full
order city sharepositive auc_full avprecision1to1_1 avprecision1to1_sp ///
avprecision1to1_full avprecision_1 avprecision_sp avprecision_full

export excel using "`outpath'\table1", firstrow(variables) replace
