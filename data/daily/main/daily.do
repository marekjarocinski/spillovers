import delimited using "daily_Daily.txt", varnames(1) clear
rename date temp
gen date = date(temp,"YMD"), before(temp)
format date %td
drop temp
foreach var of varlist will* {
    replace `var'=100*ln(`var')
}
gen spr_will_smllrgcap = willsmlcap - willlrgcap
keep date *will*
save "daily_Daily.dta", replace

import delimited using "daily_Daily_Close.txt", varnames(1) clear
rename date temp
gen date = date(temp,"YMD"), before(temp)
format date %td
drop temp
rename bamlc0a2caa bofaml_us_aa_oas
rename bamlc0a2caaey bofaml_us_aa_yld
rename bamlc0a4cbbb bofaml_us_bbb_oas
rename bamlc0a4cbbbey bofaml_us_bbb_yld
rename bamlh0a0hym2 bofaml_us_hyld_oas
rename bamlhe00ehyioas bofaml_ea_hyld_oas
foreach var of varlist will* {
    replace `var'=100*ln(`var')
}
keep date *hyld*
save "daily_Daily_Close.dta", replace

* zero coupon yields by Gurkaynak, Sack, Wright (2006) from
* https://www.federalreserve.gov/pubs/feds/2006/200628/200628abs.html
import delimited using "feds200628.csv", rowrange(11) varnames(10) clear
rename date datestr
gen date = date(datestr, "YMD"), before(datestr)
format date %td
drop datestr
keep date sveny01 sveny02 sveny10
destring, replace force
save "feds200628.dta", replace

* Bund yields from the Deutsche Bundesbank
import delimited using BBSIS.D.I.ZST.ZI.EUR.S1311.B.A604.R01XX.R.A.A._Z._Z.A.csv, rowrange(10) colrange(1:2) varnames(nonames) clear
gen date = date(v1, "YMD"), before(v1)
format date %td
drop v1
rename v2 bund1y
save bund1y.dta, replace

import delimited using BBSIS.D.I.ZST.ZI.EUR.S1311.B.A604.R02XX.R.A.A._Z._Z.A.csv, rowrange(10) colrange(1:2) varnames(nonames) clear
gen date = date(v1, "YMD"), before(v1)
format date %td
drop v1
rename v2 bund2y
save bund2y.dta, replace

import delimited using BBSIS.D.I.ZST.ZI.EUR.S1311.B.A604.R10XX.R.A.A._Z._Z.A.csv, rowrange(10) colrange(1:2) varnames(nonames) clear
gen date = date(v1, "YMD"), before(v1)
format date %td
drop v1
rename v2 bund10y
save bund10y.dta, replace


* BIS USD/1EUR, the same as the ECB official USD/1EUR from 1999
import delimited using "sdw_usdeur.csv", rowrange(6) varnames(nonames) clear delimiters(",")
gen date = date(v1,"YMD"), before (v1)
format date %td
sort date
destring v2, replace force
gen usdeur = 100*ln(v2)
gen eurusd = -usdeur
keep date usdeur eurusd
save sdw_usdeur.dta, replace

import delimited using "sdw_stocks.csv", rowrange(6) varnames(nonames) clear delimiters(",")
gen date = date(v1,"YMD"), before (v1)
format date %td
sort date
destring v2-v7, replace force
gen stoxx50 = 100*ln(v2)
gen sp500 = 100*ln(v7)
gen spr_stoxx50sp500 = stoxx50 - sp500
keep date sp500 stoxx50 spr_
save sdw_stocks.dta, replace

import excel using "indices_bloomberg_2.xlsx", sheet("Data") cellrange(A9) clear
rename A date
format date %td
sort date
destring, replace force
gen sp500fin = 100*ln(B)
gen spxxfist = 100*ln(C)
gen sp500exfin = 100*ln(D)
gen spxewfn = 100*ln(E)
gen spxewin = 100*ln(F)
gen spxewcd = 100*ln(G)
gen spr_sp500_finexfin = sp500fin-sp500exfin
drop B-G
keep date *sp500*
save "indices_bloomberg_2.dta", replace

use ../broadexeuro/broadexeuro.dta, clear
gen broadexea_usd = 100*ln(broadexeuro)
gen broad_usd = 100*ln(broad)
keep date *_usd
save broadexeuro.dta, replace

use ../sp500geo/sp500geo.dta, clear
keep date sp500geo_eu0w sp500geo_us0w sp500geo_eu0wus0w
save sp500geo.dta, replace

* Fed funds futures (from Haver)
import excel using haver_fff.xlsx, cellrange(A14) clear
gen date = date(A,"DMY",2050), before(A)
format date %td
drop A
rename B ffn
rename C ff3
rename D ff6
save haver_fff.dta, replace

* merge
use "daily_Daily_Close.dta", clear
erase "daily_Daily_Close.dta"
merge 1:1 date using "daily_Daily.dta", nogenerate
erase "daily_Daily.dta"
merge 1:1 date using "feds200628.dta", nogenerate
erase "feds200628.dta"
merge 1:1 date using "bund1y.dta", nogenerate
erase "bund1y.dta"
merge 1:1 date using "bund2y.dta", nogenerate
erase "bund2y.dta"
merge 1:1 date using "bund10y.dta", nogenerate
erase "bund10y.dta"
merge 1:1 date using "sdw_usdeur.dta", nogenerate
erase "sdw_usdeur.dta"
merge 1:1 date using "sdw_stocks.dta", nogenerate
erase "sdw_stocks.dta"
merge 1:1 date using "indices_bloomberg_2.dta", nogenerate
erase "indices_bloomberg_2.dta"
merge 1:1 date using "broadexeuro.dta", nogenerate
erase "broadexeuro.dta"
merge 1:1 date using "sp500geo.dta", nogenerate
erase "sp500geo.dta"
merge 1:1 date using "haver_fff.dta", nogenerate
erase "haver_fff.dta"

sort date
keep if year(date)>=1990 & year(date)<2020

drop if dow(date)==0 | dow(date)==6
drop if month(date)==1 & day(date)==1
drop if month(date)==12 & day(date)==25

save daily_raw.dta, replace

* transformations
quietly ds date, not
local all_vars `r(varlist)'
foreach var in `all_vars' {
	
	// windows starting at l1
	gen l1`var' = `var'[_n-1]
	replace l1`var' = `var'[_n-2] if l1`var'==.
	replace l1`var' = `var'[_n-3] if l1`var'==.
	
	gen tl1`var' = `var'[_n] - l1`var'
	replace tl1`var' = `var'[_n+1] - l1`var' if tl1`var'==.
	replace tl1`var' = `var'[_n+2] - l1`var' if tl1`var'==.
	
	gen f1l1`var' = `var'[_n+1] - l1`var'
	replace f1l1`var' = `var'[_n+2] - l1`var' if f1l1`var'==.
	replace f1l1`var' = `var'[_n+3] - l1`var' if f1l1`var'==.
	replace f1l1`var' = `var'[_n+4] - l1`var' if f1l1`var'==.
	
	gen f2l1`var' = `var'[_n+2] - l1`var'
	replace f2l1`var' = `var'[_n+3] - l1`var' if f2l1`var'==.
	replace f2l1`var' = `var'[_n+4] - l1`var' if f2l1`var'==.
	replace f2l1`var' = `var'[_n+5] - l1`var' if f2l1`var'==.
	replace f2l1`var' = `var'[_n+6] - l1`var' if f2l1`var'==.
	
	gen f3l1`var' = `var'[_n+3] - l1`var'
	replace f3l1`var' = `var'[_n+4] - l1`var' if f3l1`var'==.
	replace f3l1`var' = `var'[_n+5] - l1`var' if f3l1`var'==.
	
	gen f4l1`var' = `var'[_n+4] - l1`var'
	replace f4l1`var' = `var'[_n+5] - l1`var' if f4l1`var'==.
	replace f4l1`var' = `var'[_n+6] - l1`var' if f4l1`var'==.
	
	gen f5l1`var' = `var'[_n+5] - l1`var'
	replace f5l1`var' = `var'[_n+6] - l1`var' if f5l1`var'==.
	replace f5l1`var' = `var'[_n+7] - l1`var' if f5l1`var'==.

	gen f10l1`var' = `var'[_n+10] - l1`var'
	replace f10l1`var' = `var'[_n+11] - l1`var' if f10l1`var'==.
	replace f10l1`var' = `var'[_n+12] - l1`var' if f10l1`var'==.

	gen f15l1`var' = `var'[_n+15] - l1`var'
	replace f15l1`var' = `var'[_n+16] - l1`var' if f15l1`var'==.
	replace f15l1`var' = `var'[_n+17] - l1`var' if f15l1`var'==.
	
	gen f20l1`var' = `var'[_n+20] - l1`var'
	replace f20l1`var' = `var'[_n+21] - l1`var' if f20l1`var'==.
	replace f20l1`var' = `var'[_n+22] - l1`var' if f20l1`var'==.

	gen f25l1`var' = `var'[_n+25] - l1`var'
	replace f25l1`var' = `var'[_n+26] - l1`var' if f25l1`var'==.
	replace f25l1`var' = `var'[_n+27] - l1`var' if f25l1`var'==.
	
	gen f30l1`var' = `var'[_n+30] - l1`var'
	replace f30l1`var' = `var'[_n+31] - l1`var' if f30l1`var'==.
	replace f30l1`var' = `var'[_n+32] - l1`var' if f30l1`var'==.

	drop l1`var'
}

quietly ds date, not
foreach var in `r(varlist)' {
	rename `var' `var'_d
}

export delimited using daily.csv, replace
