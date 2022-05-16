% Construct monetary policy and information shocks from central bank surprises.
% Use the median rotation.
clear variables, close all

% Read data
% The data file should contain five columns in this order:
% 1) year, 2) month, 3) day, 4) interest rate surprise, 5) stock price surprise.
% Uncomment one of the filenames below.
data_filename = 'surprises_fed_gssipa_me_99njt_d.csv';
%data_filename = 'surprises_ecb_mpd_me_njt_d.csv';
data_table = readtable(data_filename);
M = data_table{:,4:5};
M_names = data_table.Properties.VariableNames(4:5);

% Construct Poor man's shocks
U_pm = [M(:,1).*(prod(M,2)<0) M(:,1).*(prod(M,2)>=0)];

% Construct shocks by rotation (median rotation)
U_median = signrestr_median(M);
U_q25 = signrestr_median(M, 0.25);
U_q75 = signrestr_median(M, 0.75);
U_q10 = signrestr_median(M, 0.10);
U_q90 = signrestr_median(M, 0.90);

% Save daily shocks
shocks_names = {'MP_pm','CBI_pm', 'MP_median','CBI_median',...
    'MP_q25','CBI_q25', 'MP_q75','CBI_q75', 'MP_q10','CBI_q10', 'MP_q90','CBI_q90'};
shocks_table = array2table(round([U_pm U_median U_q25 U_q75 U_q10 U_q90],8), 'VariableNames', shocks_names);
table_d = [data_table(:,1:5) shocks_table];
filename_d = strrep(['../' data_filename],'surprises','shocks');
writetable(table_d, filename_d);


% Aggregate and save monthly and quarterly shocks
[table_m, table_q] = table_d2m2q(table_d);
filename_m = strrep(filename_d, '_d.','_m.');
writetable(table_m, filename_m);
filename_q = strrep(filename_d, '_d.','_q.');
writetable(table_q, filename_q);
