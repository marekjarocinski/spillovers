% Plot the contributions of press conferences to the principal component
clear all, close all

tab_pr = readtable('../shocks_median_noncenteredpc/construct/surprises_fed_gss_pr_99njt_d.csv');
tab_pr.date = datetime(tab_pr.year, tab_pr.month, tab_pr.day);
for i = 2:size(tab_pr,2)
    tab_pr.Properties.VariableNames{i} = strrep(tab_pr.Properties.VariableNames{i}, '_hf', '_pr');
end


tab_me = readtable('../shocks_median_noncenteredpc/construct/surprises_fed_gssipa_me_99njt_d.csv');
tab_me.date = datetime(tab_me.year, tab_me.month, tab_me.day);
for i = 2:size(tab_me,2)
    tab_me.Properties.VariableNames{i} = strrep(tab_me.Properties.VariableNames{i}, '_hf', '_me');
end


% merge
tab = join(tab_pr, tab_me, 'Keys', 'date');

tab.pc1ff1_pc = tab.pc1ff1_me - tab.pc1ff1_pr;
tab.sp500_pc = tab.sp500_me - tab.sp500_pr;

% variables to plot
varnames_pr = {'pc1ff1_pr','sp500_pr'}';
varnames_pc = {'pc1ff1_pc','sp500_pc'}';
varnames_nice = {'Total i surprise', 'SP500'};
disp(table(varnames_pr, varnames_pc))

for i = 1:length(varnames_pr)
    var_pr = tab.(varnames_pr{i});
    var_pc = tab.(varnames_pc{i});
        
    % bar plot
    hh = figure('Units','centimeters','Position',[2 2 20 10]);
    bar(tab.date, [var_pr var_pc], 15, 'stacked','EdgeColor','none');
    grid on
    legend({'Press Release','Press Conference'},'Location','best')
    title(varnames_nice{i}, 'Interpreter', 'none')
    
    fname = sprintf('contrib_pr_pc_%s.pdf', varnames_pr{i});
    exportgraphics(hh, fname)
    
    % stats on pc days
    var_pr_pc = var_pr(logical(tab.d_pconf));
    var_pc_pc = var_pc(logical(tab.d_pconf));
    
    [s, nobs] = sumsqr(var_pc_pc);
    vshare = (s/(s+sumsqr(var_pr_pc)));
    
    [rho, pval] = corr(var_pr_pc, var_pc_pc, 'Rows', 'pairwise');
    fprintf('%s, %s: vshare=%0.2f corr=%0.2f pval=%0.2f nobs=%d\n', ...
        varnames_pr{i}, varnames_pc{i}, vshare, rho, pval, nobs);
    
    fprintf('%s & %0.2f & %0.2f & %0.2f \\\\\n', ...
        varnames_pr{i}, vshare, rho, pval);
end


