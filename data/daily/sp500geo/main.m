% ======================================================================= %
% This code computes the mimicked SP500* and splits it into subindices
% according to critical value of shares of EU sales c:
% ======================================================================= %
clear all, close all

load sp500geo_sourcedata.mat

tabnames = readtable('choose_constituents.xlsx', 'Range', 'L1:N501');
dummy39 = tabnames.count<40;

% drop the stocks that appear in sp500 only 39 times
if 1
    ff(:,dummy39) = [];
    pp(:,dummy39) = [];
    mSharesEU(dummy39,:) = [];
    mSharesEUplus(dummy39,:) = [];
    mSharesUS(dummy39,:) = [];
    mSharesUSplus(dummy39,:) = [];
    tabnames(dummy39,:) = [];
    clear dummy39
end

% Approximate SP500

% understand and replace missing values
misf = isnan(ff);
misp = isnan(pp);
fprintf('Total obs %d, of which:\n missing FFMV %d, missing Price %d, missing only price %d\n',...
    numel(ff), sum(misf, 'all'), sum(misp, 'all'), sum(misp & ~misf, 'all'));
ff(misf) = 0;
pp(misp) = 0;

sp500star = sum(ff .* pp ./ sum(ff,2), 2, 'omitnan');

fh = figure;
hold on
plot(dates, log(vSP500), '-k', 'LineWidth', 1.5)
plot(dates, log(sp500star*vSP500(1)/sp500star(1)), '-r')
legend('SP500', 'SP500*', 'Location', 'NorthWest')
exportgraphics(fh,'sp500_approx.pdf')

%% Report geo shares of sales

% Plot shares over time
y = [2000, 2005, 2010, 2015, 2020];
fh = figure;
plot(y, mSharesEUplus(1:50,:)');
title('Share of Sales to EMEA');
xlabel('Year');
exportgraphics(fh,'SharesEUplus_ts.pdf')

avgSharesEU = meantreatnan(mSharesEU, 0);
avgSharesUS = meantreatnan(mSharesUS, 0);
avgSharesEUplus = meantreatnan(mSharesEUplus, 0);
avgSharesUSplus = meantreatnan(mSharesUSplus, 0);

% avgSharesEU = mean(mSharesEU, 2, 'omitnan');
% avgSharesUS = mean(mSharesUS, 2, 'omitnan');
% avgSharesEUplus = mean(mSharesEUplus, 2, 'omitnan');
% avgSharesUSplus = mean(mSharesUSplus, 2, 'omitnan');

% Plot the distribution of shares
fh = figure;
subplot(2,2,1)
histogram(avgSharesEU)
xlim([0 1])
title('Average Shares EU')
subplot(2,2,2)
histogram(avgSharesEUplus)
xlim([0 1])
title('Average Shares EU+')
subplot(2,2,3)
histogram(avgSharesUS)
xlim([0 1])
title('Average Shares US')
subplot(2,2,4)
histogram(avgSharesUSplus)
xlim([0 1])
title('Average Shares US+')
exportgraphics(fh, 'shares_histograms.pdf')

tabnames = addvars(tabnames, avgSharesEU, avgSharesEUplus, avgSharesUS, avgSharesUSplus);
writetable(tabnames,'companies.csv')

%% Compute the indices

% EU0 (strict)
disp('Share EU')
hh = avgSharesEU;

fprintf('Number of companies with nonzero weights %d\n', sum(hh > 0))
ff1 = ff .* hh';
eu0w = sum(ff1 .* pp ./ sum(ff1,2), 2);

ff1 = ff .* (1-hh');
noteu0w = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.1;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
eu010 = sum(ff1 .* pp ./ sum(ff1,2), 2);

ff1 = ff .* (hh < c)';
noteu010 = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.15;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
eu015 = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.05;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh < c)';
noteu005 = sum(ff1 .* pp ./ sum(ff1,2), 2);

fh = figure;
hold on
plot(dates, log(sp500star), '-k', 'LineWidth', 1.5)
plot(dates, log(eu0w), '-r')
plot(dates, log(eu010), '-b')
plot(dates, log(eu015), '-', 'color', [0.9290, 0.6940, 0.1250])
plot(dates, log(noteu005), ':r', 'LineWidth', 2)
legend('SP500*', 'eu0w', 'eu010', 'eu015', 'Location', 'NorthWest')
exportgraphics(fh,'sp500_subind_eu0.pdf')

%% EUplus
disp('Share EU plus')
hh = avgSharesEUplus;

fprintf('Number of companies with nonzero weights %d\n', sum(hh > 0))
ff1 = ff .* hh';
eupw = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.1;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
eup10 = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.15;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
eup15 = sum(ff1 .* pp ./ sum(ff1,2), 2);

fh = figure;
hold on
plot(dates, log(sp500star), '-k', 'LineWidth', 1.5)
plot(dates, log(eupw), '-r')
plot(dates, log(eup10), '-b')
plot(dates, log(eup15), '-', 'color', [0.9290, 0.6940, 0.1250])
legend('SP500*', 'eupw', 'eup10', 'eup15', 'Location', 'NorthWest')
exportgraphics(fh,'sp500_subind_eup.pdf')


% US0 (strict)
disp('Share US')
hh = avgSharesUS;

fprintf('Number of companies with nonzero weights %d\n', sum(hh > 0))
ff1 = ff .* hh';
us0w = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.90;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
us090 = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.95;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
us095 = sum(ff1 .* pp ./ sum(ff1,2), 2);

fh = figure;
hold on
plot(dates, log(sp500star), '-k', 'LineWidth', 1.5)
plot(dates, log(us0w), '-r')
plot(dates, log(us090), '-b')
plot(dates, log(us095), '-', 'color', [0.9290, 0.6940, 0.1250])
legend('SP500*', 'us0w', 'us090', 'us095', 'Location', 'NorthWest')
exportgraphics(fh,'sp500_subind_us0.pdf')


% USplus
disp('Share US-plus')
hh = avgSharesUSplus;

fprintf('Number of companies with nonzero weights %d\n', sum(hh > 0))
ff1 = ff .* hh';
uspw = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.90;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
usp90 = sum(ff1 .* pp ./ sum(ff1,2), 2);

c = 0.95;
fprintf('Minimum share %0.2f, number of companies %d\n', c, sum(hh > c))
ff1 = ff .* (hh > c)';
usp95 = sum(ff1 .* pp ./ sum(ff1,2), 2);

fh = figure;
hold on
plot(dates, log(sp500star), '-k', 'LineWidth', 1.5)
plot(dates, log(uspw), '-r')
plot(dates, log(usp90), '-b')
plot(dates, log(usp95), '-', 'color', [0.9290, 0.6940, 0.1250])
legend('SP500*', 'uspw', 'usp90', 'usp95', 'Location', 'NorthWest')
exportgraphics(fh,'sp500_subind_usp.pdf')

%% export the indices
tab = timetable(dates, vSP500, sp500star, eu0w, eu010, eu015, noteu0w, noteu005, noteu010, eupw, eup10, eup15, us0w, us090, us095, uspw, usp90, usp95);
writetimetable(tab, 'sp500geo.csv')