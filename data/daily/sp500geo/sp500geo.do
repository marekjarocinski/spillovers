import delimited using "SP500geo.csv", varnames(1) clear
gen date = date(dates,"YMD"), before (dates)
format date %td
drop dates
gen sp500geo_true = 100*ln(vsp500)
gen sp500geo_appr = 100*ln(sp500star)

foreach var of varlist eu* noteu* us* {
	gen sp500geo_`var' = 100*ln(`var')
}

keep date sp500geo*

gen sp500geo_eu0wus0w = sp500geo_eu0w - sp500geo_us0w
gen sp500geo_eu010us090 = sp500geo_eu010 - sp500geo_us090
gen sp500geo_eu015us095 = sp500geo_eu015 - sp500geo_us095

gen sp500geo_eu0wnot = sp500geo_eu0w - sp500geo_noteu0w
gen sp500geo_eu0wnot05 = sp500geo_eu0w - sp500geo_noteu005
gen sp500geo_eu015not05 = sp500geo_eu015 - sp500geo_noteu005

gen sp500geo_eupwuspw = sp500geo_eupw - sp500geo_uspw
gen sp500geo_eup10usp90 = sp500geo_eup10 - sp500geo_usp90
gen sp500geo_eup15usp95 = sp500geo_eup15 - sp500geo_usp95

save sp500geo.dta, replace


