% Compute the first principal component of interest rate surprises
% Save this principal component and a stock price in a .csv
clear all, close all

% Load the Altavilla et al. (2019) Monetary Policy Database downloadable from
% https://www.ecb.europa.eu/pub/pdf/annex/Dataset_EA-MPD.xlsx
% use the Monetary Event Window
data_filename = '../../data/Dataset_EA-MPD.xlsx';
opts = detectImportOptions(data_filename, 'Sheet', 'Monetary Event Window');
%opts = detectImportOptions(data_filename, 'Sheet', 'Press Release Window');
for i = 2:length(opts.VariableTypes)
     opts.VariableTypes{i} = 'double';
end
tab = readtable(data_filename, opts);

% select the sample
isample = true(size(tab,1),1);
% drop joint Fed and ECB announcements
isample(tab.date == datetime('13-Sep-2001')) = 0; % joint announcement of USD swap
isample(tab.date == datetime('17-Sep-2001')) = 0; % joint cut at 17:30
isample(tab.date == datetime('08-Oct-2008')) = 0; % joint cut

tab = tab(isample,:);

% compute the principal component
xnames = {'OIS_1M','OIS_3M','OIS_6M','OIS_1Y'};
X = tab{:, xnames};
[coeff,score,latent,tsquared,explained,mu] = pca(normalize(X,'scale','std'), 'Centered', false);
% rescale the 1st principal component
pc1 = score(:,1)/std(score(:,1))*std(tab{:,'OIS_1Y'})/100;

% export to csv
year = year(tab.date);
month = month(tab.date);
day = day(tab.date);
pc1eon1_me_njt = round(pc1, 8);
stoxx50_me_njt = round(tab.STOXX50, 8);

tab_out = table(year, month, day, pc1eon1_me_njt, stoxx50_me_njt);
writetable(tab_out, 'surprises_ecb_mpd_me_njt_d.csv');
%writetable(tab_out, 'surprises_ecb_mpd_pr_njt_d.csv');