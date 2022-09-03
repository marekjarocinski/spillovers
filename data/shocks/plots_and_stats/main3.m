% Table and plots about rotations
clear all, close all

tab_ecb = readtable('../shocks/construct/surprises_ecb_mpd_me_njt_d.csv');
date = datetime(tab_ecb.year, tab_ecb.month, tab_ecb.day);
i_ecb = tab_ecb{:,4}*1;
s_ecb = tab_ecb{:,5}*1;
tab_ecb = table(date, i_ecb, s_ecb);
tab_ecb(tab_ecb.date>datetime(2019,6,6),:) = [];
disp('ECB surprises')
fh = report_rotations(tab_ecb{:,2:3});
exportgraphics(fh, 'ecb-scatter-rotations.pdf')

tab_fed = readtable('../shocks/construct/surprises_fed_gssipa_me_99njt_d.csv');
date = datetime(tab_fed.year, tab_fed.month, tab_fed.day);
i_fed = tab_fed{:,4}*1;
s_fed = tab_fed{:,5}*1;
tab_fed = table(date, i_fed, s_fed);
disp('Fed surprises')
fh = report_rotations(tab_fed{:,2:3});
exportgraphics(fh, 'fed-scatter-rotations.pdf')
