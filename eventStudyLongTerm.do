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
	}
}

//
// Calculate (1 + Ri,t)
foreach crypto in doge btc ada ltc eth {
	gen rel_`crypto' = `crypto'returns + 1
}

//
// Calculate (1+ E(Ri,t))
foreach i in 1 2 3 4 5 {
	foreach crypto in doge btc ada ltc eth {
		gen erl`i'_`crypto' = er_`crypto'_event`i' + 1
	}
}

// Note: Product of multiple terms is calculated by the exponential of the summation of ln of all terms
foreach i in 1 2 3 4 5 {
	foreach crypto in doge btc ada ltc eth {
	
		// Calculate product of (1 + Ri,t) from day 11 to day 100 after event day 0
		egen bhar_`crypto'_event`i'_a = total(ln(rel_`crypto')) if event`i' > 10 & event`i' <=100
		replace bhar_`crypto'_event`i'_a=exp(bhar_`crypto'_event`i'_a)
	
		// Calculate product of (1+ E(Ri,t)) from day 11 to day 100 after event day 0
		egen bhar_`crypto'_event`i'_b = total(ln(erl`i'_`crypto')) if event`i' > 10 & event`i' <=100
		replace bhar_`crypto'_event`i'_b = exp(bhar_`crypto'_event`i'_b)
		
		// Calculate BHAR
		gen bhar_event`i'_`crypto' = bhar_`crypto'_event`i'_a - bhar_`crypto'_event`i'_b
		
		drop bhar_`crypto'_event`i'_a bhar_`crypto'_event`i'_b
	}
}

//
// Calculate BHAR mean and variance for each event by taking the average of BHAR across 5 cryptocurrencies
foreach i in 1 2 3 4 5 {	
	egen bhar_mean_event`i'=rowmean(bhar_event`i'*)

	foreach crypto in doge btc ada ltc eth {
		gen sqrdiff_bhar_event`i'_`crypto' = (bhar_event`i'_`crypto' - bhar_mean_event`i') ^ 2
	}
	
	egen sum_sqrdiff_bhar_event`i' = rowtotal(sqrdiff_bhar_event`i'*)
	
	gen var_bhar_event`i' = sum_sqrdiff_bhar_event`i' / 4 // N-1
	
	drop sqrdiff_bhar_event`i'_* sum_sqrdiff_bhar_event`i'
}

//
// Calculate t statistic of mean BHAR for each event
foreach i in 1 2 3 4 5 {	
	gen ttest_longterm_event`i' = bhar_mean_event`i' / sqrt(var_bhar_event`i') * sqrt(5)
}

saveold Longterm_finalresults.dta, version(12) replace