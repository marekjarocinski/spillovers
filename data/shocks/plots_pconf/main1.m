% Plot the contributions of press conferences to individual variables
clear all, close all

% Load the updated Gurkaynak, Sack and Swanson (2005) dataset, 
% courtesy of Refet Gurkaynak.
tab = readtable('../data/GSSrawdata.xlsx');
tab.Properties.VariableNames{1} = 'date';

% select the sample
isample = tab.date > datetime('01-Jan-1999');
isample(tab.date == datetime('17-Sep-2001')) = 0; % joint Fed ECB, before mkts opened, dropped in Swanson (2020)
isample(tab.date == datetime('11-Mar-2008')) = 0; % joint Fed ECB
isample(tab.date == datetime('08-Oct-2008')) = 0; % joint Fed ECB
tab = tab(isample,:);
fprintf('Data from %s to %s, T=%d\n', tab{1,'date'},tab{end,'date'},size(tab,1))


% Load fed_ipa_pc
tab_pc = readtable('../data_ipa/fed_ipa_pc_abgmrstyle.csv');
tab_pc.date = datetime(tab_pc.date,'InputFormat','ddMMMyyyy');
tab_pc.release_type = [];
for i = 2:size(tab_pc,2)
    tab_pc.Properties.VariableNames{i} = [tab_pc.Properties.VariableNames{i} '_pc'];
end


% merge
tab = outerjoin(tab, tab_pc, 'Keys', 'date', 'Type', 'left', 'MergeKeys', true);

tab.d_pconf = ~isnan(tab.spx_pc);

% variables to plot
varnames_pr = {'MP1','FF4','ED2','ED3','ED4','SP500'}';
varnames_pc = {'mpc1_pc','ffc4_pc','edcm2_pc','edcm3_pc','edcm4_pc','spx_pc'}';
disp(table(varnames_pr, varnames_pc))

for i = 1:length(varnames_pr)
    var_pr = tab.(varnames_pr{i});
    var_pc = tab.(varnames_pc{i});
        
    % bar plot
    hh = figure('Units','centimeters','Position',[2 2 20 10]);
    bar(tab.date, [var_pr var_pc], 15, 'stacked','EdgeColor','none');
    grid on
    legend({'Press Release','Press Conference'},'Location','best')
    title(varnames_pr{i})
    
    fname = sprintf('contrib_pr_pc_%s.pdf', varnames_pr{i});
    exportgraphics(hh, fname)
    
    % stats on pc days
    var_pr_pc = var_pr(tab.d_pconf);
    var_pc_pc = var_pc(tab.d_pconf);
    
    [s, nobs] = sumsqr(var_pc_pc);
    vshare = (s/(s+sumsqr(var_pr_pc)));
    
    [rho, pval] = corr(var_pr_pc, var_pc_pc, 'Rows', 'pairwise');
    fprintf('%s, %s: vshare=%0.2f corr=%0.2f pval=%0.2f nobs=%d\n', ...
        varnames_pr{i}, varnames_pc{i}, vshare, rho, pval, nobs);

    fprintf('%s & %0.2f & %0.2f & %0.2f \\\\\n', ...
        varnames_pr{i}, vshare, rho, pval);
end


