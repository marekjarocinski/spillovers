% plots and stats for the shocks
clear all, close all

tab_ecb = readtable('../shocks/shocks_ecb_mpd_me_njt_d.csv');
date = datetime(tab_ecb.year, tab_ecb.month, tab_ecb.day);
mp_pm_ecb = tab_ecb.MP_pm*100;
cbi_pm_ecb = tab_ecb.CBI_pm*100;
mp_median_ecb = tab_ecb.MP_median*100;
cbi_median_ecb = tab_ecb.CBI_median*100;
tab_ecb = table(date, mp_pm_ecb, cbi_pm_ecb, mp_median_ecb, cbi_median_ecb);
tab_ecb(tab_ecb.date>datetime(2019,6,6),:) = [];
disp('ECB shocks pm')
summary_stats(tab_ecb{:,2:3})
disp('ECB shocks median')
summary_stats(tab_ecb{:,4:5})

tab_fed = readtable('../shocks/shocks_fed_gssipa_me_99njt_d.csv');
date = datetime(tab_fed.year, tab_fed.month, tab_fed.day);
mp_pm_fed = tab_fed.MP_pm*100;
cbi_pm_fed = tab_fed.CBI_pm*100;
mp_median_fed = tab_fed.MP_median*100;
cbi_median_fed = tab_fed.CBI_median*100;
tab_fed = table(date, mp_pm_fed, cbi_pm_fed, mp_median_fed, cbi_median_fed);
disp('Fed shocks pm')
summary_stats(tab_fed{:,2:3})
disp('Fed shocks median')
summary_stats(tab_fed{:,4:5})

% check for joint announcements
tab0 = innerjoin(tab_ecb, tab_fed)

% joint dataset
tab = outerjoin(tab_ecb, tab_fed, 'MergeKeys', true);

% plot cumulated surprises
ttab = table2timetable(tab);
ttab = retime(ttab, 'daily');
ttab = fillmissing(ttab, 'constant', 0);
ttab{:,:} = cumsum(ttab{:,:})/100;
fh = figure('Units','centimeters','Position',[10,10,12,6]);
hold on
plot(ttab.date, ttab.mp_median_ecb, '-k')
plot(ttab.date, ttab.mp_median_fed, '-b')
legend('ECB','Fed','Location','Best')
ylabel('cumulated shocks (percent)')
exportgraphics(fh, 'cumulated_mp_median.pdf')
fh = figure('Units','centimeters','Position',[10,10,12,6]);
hold on
plot(ttab.date, ttab.cbi_median_ecb, '-k')
plot(ttab.date, ttab.cbi_median_fed, '-b')
legend('ECB','Fed','Location','Best')
ylabel('cumulated shocks (percent)')
exportgraphics(fh, 'cumulated_cbi_median.pdf')


% correlation between the Fed shock and the most recent ECB surprise
tab_lag = tab;
tab_lag{1,2:end} = NaN;
tab_lag{2:end,2:end} = tab{1:end-1,2:end};

X = [tab.mp_median_fed tab.cbi_median_fed tab_lag.mp_median_ecb tab_lag.cbi_median_ecb];
X = X(~isnan(sum(X,2)),:);
[R, P] = corr(X)
X1 = X(X(:,1)>-40,:);
[R1, P1] = corr(X1)

fprintf("correlation between the Fed shock and the most recent ECB shock & %0.2f & (%0.2f) & %0.2f & (%0.2f) & %d \\\\\n",...
    R(3,1), P(3,1), R(4,2), P(4,2), size(X,1));


% correlation between the Fed surprise and the subsequent ECB surprise
tab_lead = tab;
tab_lead{1:end-1,2:end} = tab{2:end,2:end};
tab_lead{end,2:end} = NaN;

X = [tab.mp_median_fed tab.cbi_median_fed tab_lead.mp_median_ecb tab_lead.cbi_median_ecb];
X = X(~isnan(sum(X,2)),:);
[R, P] = corr(X)
X1 = X(X(:,1)>-40,:);
[R1, P1] = corr(X1)

fprintf("correlation between the Fed surprise and the subsequent ECB shock & %0.2f & (%0.2f) & %0.2f & (%0.2f) & %d \\\\\n",...
    R(3,1), P(3,1), R(4,2), P(4,2), size(X,1));
