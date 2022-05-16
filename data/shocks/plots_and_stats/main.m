% statistics about surprises
clear all, close all

tab_ecb = readtable('../shocks/construct/surprises_ecb_mpd_me_njt_d.csv');
date = datetime(tab_ecb.year, tab_ecb.month, tab_ecb.day);
i_ecb = tab_ecb{:,4}*100;
s_ecb = tab_ecb{:,5}*100;
tab_ecb = table(date, i_ecb, s_ecb);
tab_ecb(tab_ecb.date>datetime(2019,6,6),:) = [];
disp('ECB surprises')
summary_stats(tab_ecb{:,2:3})

tab_fed = readtable('../shocks/construct/surprises_fed_gssipa_me_99njt_d.csv');
date = datetime(tab_fed.year, tab_fed.month, tab_fed.day);
i_fed = tab_fed{:,4}*100;
s_fed = tab_fed{:,5}*100;
tab_fed = table(date, i_fed, s_fed);
disp('Fed surprises')
summary_stats(tab_fed{:,2:3})

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
plot(ttab.date, ttab.i_ecb, '-k')
plot(ttab.date, ttab.i_fed, '-b')
legend('ECB','Fed','Location','East')
ylabel('cumulated surprises (percent)')
exportgraphics(fh, 'cumulated_surprises_pc1.pdf')
fh = figure('Units','centimeters','Position',[10,10,12,6]);
hold on
plot(ttab.date, ttab.s_ecb, '-k')
plot(ttab.date, ttab.s_fed, '-b')
legend('ECB','Fed','Location','East')
ylabel('cumulated surprises (percent)')
exportgraphics(fh, 'cumulated_surprises_stock.pdf')


% correlation between the Fed surprise and the most recent ECB surprise
tab_lag = tab;
tab_lag{1,2:end} = NaN;
tab_lag{2:end,2:end} = tab{1:end-1,2:end};

X = [tab.i_fed tab.s_fed tab_lag.i_ecb tab_lag.s_ecb];
X = X(~isnan(sum(X,2)),:);
[R, P] = corr(X)
X1 = X(X(:,1)>-40,:);
[R1, P1] = corr(X1)

fprintf("correlation between the Fed surprise and the most recent ECB surprise & %0.2f & (%0.2f) & %0.2f & (%0.2f) & %d \\\\\n",...
    R(3,1), P(3,1), R(4,2), P(4,2), size(X,1));


% correlation between the Fed surprise and the subsequent ECB surprise
tab_lead = tab;
tab_lead{1:end-1,2:end} = tab{2:end,2:end};
tab_lead{end,2:end} = NaN;

X = [tab.i_fed tab.s_fed tab_lead.i_ecb tab_lead.s_ecb];
X = X(~isnan(sum(X,2)),:);
[R, P] = corr(X)
X1 = X(X(:,1)>-40,:);
[R1, P1] = corr(X1)

fprintf("correlation between the Fed surprise and the subsequent ECB surprise & %0.2f & (%0.2f) & %0.2f & (%0.2f) & %d \\\\\n",...
    R(3,1), P(3,1), R(4,2), P(4,2), size(X,1));


%T = outerjoin(tab, tab_lead, 'Keys', {'date'}, 'MergeKeys', true);