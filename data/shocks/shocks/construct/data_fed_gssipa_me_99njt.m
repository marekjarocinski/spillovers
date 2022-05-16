% Add press release and press conference surprises
% Compute the first principal component of interest rate surprises
% Save this principal component and stock price in a .csv
clear all, close all

% Load the updated Gurkaynak, Sack and Swanson (2005) dataset, 
% from http://www.bilkent.edu.tr/~refet/GKL_replication.zip
tab1 = readtable('../../data/GSSrawdata.xlsx');

% Load the press conference dataset courtesy of IPA
tab2 = readtable('../../data/fed_ipa_pc_abgmrstyle.csv');
tab2.Date = datetime(tab2.date,'InputFormat','ddMMMyyyy');

% Merge and add the surprises
tab = outerjoin(tab1,tab2,'Keys','Date','MergeKeys',true);
tab.date = [];
tab.Properties.VariableNames{1} = 'date';
tab.d_pconf = not(isnan(tab.spx));
tab.mpc1(isnan(tab.mpc1)) = 0; tab.MP1me = tab.MP1 + tab.mpc1;
tab.ffc4(isnan(tab.ffc4)) = 0; tab.FF4me = tab.FF4 + tab.ffc4;
tab.edcm1(isnan(tab.edcm1)) = 0; tab.ED1me = tab.ED1 + tab.edcm1;
tab.edcm2(isnan(tab.edcm2)) = 0; tab.ED2me = tab.ED2 + tab.edcm2;
tab.edcm3(isnan(tab.edcm3)) = 0; tab.ED3me = tab.ED3 + tab.edcm3;
tab.edcm4(isnan(tab.edcm4)) = 0; tab.ED4me = tab.ED4 + tab.edcm4;
tab.spx(isnan(tab.spx)) = 0; tab.SP500me = tab.SP500 + tab.spx;

% select the sample
isample = tab.date > datetime('01-Jan-1999') & tab.date < datetime('30-Jun-2019');
isample(tab.date == datetime('17-Sep-2001')) = 0; % joint Fed ECB, before mkts opened, dropped in Swanson (2020)
%isample(tab.date == datetime('25-Nov-2008')) = 0; % before mkts opened, not FOMC announcement, dropped in Swanson (2020)
%isample(tab.date == datetime('01-Dec-2008')) = 0; % not FOMC announcement, dropped in Swanson (2020)

isample(tab.date == datetime('11-Mar-2008')) = 0; % joint Fed ECB
isample(tab.date == datetime('08-Oct-2008')) = 0; % joint Fed ECB

tab = tab(isample,:);
fprintf('Data from %s to %s, T=%d\n', tab{1,'date'},tab{end,'date'},size(tab,1))

% compute the principal component
xnames = {'MP1me','FF4me','ED2me','ED3me','ED4me'};
X = tab{:, xnames};
X(isnan(X)) = 0;
[coeff,score,latent,tsquared,explained,mu] = pca(normalize(X,'scale','std'), 'Centered', false);
% rescale the 1st principal component
pc1 = score(:,1)/std(score(:,1))*std(tab{:,'ED4me'});

% export to csv
year = year(tab.date);
month = month(tab.date);
day = day(tab.date);
pc1ff1_hf = round(pc1, 8);
sp500_hf = round(tab.SP500me, 8);
d_pconf = tab.d_pconf;

tab_out = table(year, month, day, pc1ff1_hf, sp500_hf, d_pconf);
writetable(tab_out, 'surprises_fed_gssipa_me_99njt_d.csv');