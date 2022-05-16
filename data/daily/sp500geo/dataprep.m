% ----------------------------------------------------------------------- %
% Import and prepare data
% ----------------------------------------------------------------------- %
clear all, close all

% load data (check whether indexing is correct)
ff = xlsread("20210920_SP500star_MVFF_request.xlsm", 'RDBMergeSheet','A2:SF6002');
pp = xlsread("20210920_SP500star_P_request.xlsm", 'RDBMergeSheet','A2:SF6002');
vSP500 = xlsread("20210920_SP500star_SP500_request.xlsm", 'RDBMergeSheet','B2:B6002');
vDates = readtable("20210920_SP500star_Dates_request.xlsm", 'Sheet', 'RDBMergeSheet');
dummy39 = logical(xlsread('choose_constituents.xlsx', 'O2:O501'));

% create daily dates
dates = datetime(vDates.Name,'Format','yyyy-MM-dd');
clear vDates

% load shares
data_filename = '20210928_SP500star_Sales_request.xlsm';
sheetnames = compose('01-01-%d', [2000 2005 2010 2015 2020]);
mSharesEU = [];
mSharesUS = [];
mSharesEUplus = [];
mSharesUSplus = [];
for i = 1:length(sheetnames)
    opts = detectImportOptions(data_filename, 'Sheet', sheetnames{i});
    tab = readtable(data_filename, opts);
    mSharesEU = [mSharesEU tab.EU_share];
    mSharesUS = [mSharesUS tab.US_share];
    mSharesEUplus = [mSharesEUplus tab.EUplus_share];
    mSharesUSplus = [mSharesUSplus tab.Usplus_share];
end
clear data_filename sheetnames i opts tab

save sp500geo_sourcedata.mat 