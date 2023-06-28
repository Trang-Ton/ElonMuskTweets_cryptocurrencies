// cd [path]
use Rawdata_final.dta

gen time=_n

//
// Calculate return of each cryptocurrency
gen dogereturns=(DOGE[_n]-DOGE[_n-1])/DOGE[_n-1]
gen btcreturns=(BTC[_n]-BTC[_n-1])/BTC[_n-1]
gen adareturns=(ADA[_n]-ADA[_n-1])/ADA[_n-1]
gen ltcreturns=(LTC[_n]-LTC[_n-1])/LTC[_n-1]
gen ethreturns=(ETH[_n]-ETH[_n-1])/ETH[_n-1]
gen CCMIXreturns=(CCMIX[_n]-CCMIX[_n-1])/CCMIX[_n-1]

// for each event with chosen time
local i=0
foreach time in 322 407 427 471 499 {
	local i = `i' + 1
	gen faketime`i'=`time'
	gen event`i' = time-faketime`i' // relative event time

	// in each event, calculate for each cryptocurrency
	foreach crypto in doge btc ada ltc eth {
		regress `crypto'returns CCMIXreturns if time > 0 & time <= `time'-10 // regression of data in estimation window
		mat A = e(b) // matrix from regression which hold the regression coefficients
		gen b_`crypto'_event`i' = A[1,1] // from regression, take beta coeffient which is the element of matrix A at row 1 column 1
		mat drop A
		gen er_`crypto'_event`i' = b_`crypto'_event`i' * CCMIXreturns // Expected return
		gen ar_`crypto'_event`i' = `crypto'returns - er_`crypto'_event`i' // Abnormal return
	}
	
	// Calculate mean AR across all cryptocurrencies
	egen AR_t_`i'=rowmean(ar*)
}

//
// Calculate CARs foreach event
foreach i in 1 2 3 4 5 {
	// issues of leakage information
	egen CARt_leakinfo`i' = total(AR_t_`i') if event`i'>=-10 & event`i'<=-1
	// day of announcement of event to general public
	egen CARt_announce`i'=total(AR_t_`i') if event`i'==0
	// delayed price adjustment
	egen CARt_pricedelay`i'=total(AR_t_`i') if event`i'>=1 & event`i'<=10
}

//
// Calculate variances in estimation window
foreach i in 1 2 3 4 5 {
	foreach crypto in doge btc ada ltc eth{
		quietly sum ar_`crypto'_event`i' if event`i'<=-10, detail
		matrix var_`i'=nullmat(var_`i')\r(Var), 10*r(Var)
		matrix colnames var_`i'=var`i'_AR_it var`i'_CAR_i
	}
	
	matrix var = nullmat(var), var_`i'
	matrix drop var_`i'
}

//
// Save the variances to other file for easier calculation
capture rm var_1.dta
svmatf, mat(var) fil(var_1.dta)
mat drop var
saveold Shortterm_final_calculations.dta, version(12) replace

use var_1.dta

//
// Calculate t statistic for CAR in the issue of leakage information window with var(CAR) = (-1-(-10)+1)*var(AR) or 10*var(AR) foreach event
local i = 0
foreach CAR_leak in -0.0283421 0.2369092 0.069566 0.2338927 0.078079 {

	local i = `i' + 1
	egen sum_var`i'_CAR_i = total(var`i'_CAR_i)
	gen var_CAR`i' = sum_var`i'_CAR_i / 5
	drop sum_var`i'_CAR_i
	gen ttest`i'_CAR_leak = `CAR_leak' / sqrt(var_CAR`i') * sqrt(5)
}

//
// Calculate t statistic for CAR at the day of event announcement with var(CAR) = (0-0+1)*var(AR) foreach event
local i = 0
foreach CAR_ann in 0.0009893 0.1098407 -0.0000813 0.0747189 0.2076953 {
	local i = `i' + 1
	egen sum_var`i'_AR_i = total(var`i'_AR_it)
	gen var_AR`i' = sum_var`i'_AR_i / 5
	drop sum_var`i'_AR_i
	gen ttest`i'_CAR_ann = `CAR_ann' / sqrt(var_AR`i') * sqrt(5)
}

//
// Calculate t statistic for CAR in the price adjustment window with var(CAR) = (10-1+1)*var(AR) or 10*var(AR) foreach event
local i = 0
foreach CAR_delay in 0.0560599 -0.1292181 -0.0549408 0.1681824 -0.0112453 {
	local i = `i' + 1
	gen ttest`i'_CAR_delay = `CAR_delay' / sqrt(var_CAR`i') * sqrt(5)
}

saveold Shortterm_final_ttest.dta, version(12) replace


