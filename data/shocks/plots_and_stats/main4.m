% plots and stats for the shocks - monthly frequency
clear all, close all

tab_ecb = readtable('../shocks/shocks_ecb_mpd_me_njt_m.csv');
date = datetime(tab_ecb.year, tab_ecb.month, 1);
mp_pm_ecb = tab_ecb.MP_pm*100;
cbi_pm_ecb = tab_ecb.CBI_pm*100;
mp_median_ecb = tab_ecb.MP_median*100;
cbi_median_ecb = tab_ecb.CBI_median*100;
tab_ecb = table(date, mp_pm_ecb, cbi_pm_ecb, mp_median_ecb, cbi_median_ecb);
tab_ecb(tab_ecb.date>datetime(2019,6,6),:) = [];

tab_fed = readtable('../shocks/shocks_fed_gssipa_me_99njt_m.csv');
date = datetime(tab_fed.year, tab_fed.month, 1);
mp_pm_fed = tab_fed.MP_pm*100;
cbi_pm_fed = tab_fed.CBI_pm*100;
mp_median_fed = tab_fed.MP_median*100;
cbi_median_fed = tab_fed.CBI_median*100;
tab_fed = table(date, mp_pm_fed, cbi_pm_fed, mp_median_fed, cbi_median_fed);

% joint dataset
tab = outerjoin(tab_ecb, tab_fed, 'MergeKeys', true);
tab = table2timetable(tab);
tab = fillmissing(tab, 'constant', 0);
vnames = tab.Properties.VariableNames;
array2table(corr(tab{:,:}), 'VariableNames', vnames, 'RowNames', vnames)

[R2, P2] = corr(tab.cbi_median_fed, tab.cbi_median_ecb)