* broad and euro (back to 2006): https://www.federalreserve.gov/datadownload/Build.aspx?rel=H10
import delimited using "FRB_H10.csv", rowrange(7) varnames(6) clear
gen date = date(timeperiod, "YMD"), before(timeperiod)
format date %td
drop timeperiod
destring, replace force
rename jrxwtfb_nb broad
rename rxius_nbeu usdeur
save "FRB_H10.dta", replace

* the weights (back to 2006): https://www.federalreserve.gov/releases/h10/weights/default.htm
import delimited using weights2006.csv, rowrange(2) varnames(1) clear
keep year euroarea
rename euroarea weighteuro
save weights2006.dta, replace

* data back to 1973: https://www.federalreserve.gov/econres/notes/ifdp-notes/IFDP_Note_Data_Appendix.xlsx
import excel using IFDP_Note_Data_Appendix.xlsx, sheet("Index Weights") firstrow case(lower) clear
keep year euroarea
rename euroarea weighteuro_h
keep if year>1998 & year<2006
save weighteuro_h.dta, replace

* data back to 1973: https://www.federalreserve.gov/econres/notes/ifdp-notes/IFDP_Note_Data_Appendix.xlsx
import excel using IFDP_Note_Data_Appendix.xlsx, sheet("Nominal Dollar Indexes Daily") firstrow case(lower) clear
rename period date
rename nominalbroaddaily broad_h
keep date broad_h
destring, replace force
keep if year(date)>1998 // & year(date)<2006
save broad_h.dta, replace


* merge
use "FRB_H10.dta", clear
merge 1:1 date using "broad_h.dta", nogenerate
sort date
replace broad = broad_h if date<td(02jan2006)
drop broad_h
gen year = year(date)
merge m:1 year using "weights2006.dta", nogenerate
merge m:1 year using "weighteuro_h.dta", nogenerate
replace weighteuro = weighteuro_h if weighteuro==.
keep date broad usdeur weighteuro

* cleanup
erase "FRB_H10.dta"
erase "broad_h.dta"
erase "weights2006.dta"
erase "weighteuro_h.dta"

replace usdeur = usdeur[_n-1] if usdeur==.
replace broad = broad[_n-1] if broad==.
drop in 1

* subtract the euro using the formula from
* https://www.federalreserve.gov/econres/notes/feds-notes/revisions-to-the-federal-reserve-dollar-indexes-20190115.htm
replace weighteuro = weighteuro/100
gen eurusd = 1/usdeur
gen contrib = weighteuro*(ln(eurusd)-ln(eurusd[_n-1]))
gen dlnbroad = ln(broad) - ln(broad[_n-1])
gen dlnbroadexeuro = 1/(1-weighteuro)*(dlnbroad - contrib)
gen lnbroadexeuro = sum(dlnbroadexeuro) + ln(broad[1])
gen broadexeuro = exp(lnbroadexeuro)

keep date broad broadexeuro

save broadexeuro.dta, replace
