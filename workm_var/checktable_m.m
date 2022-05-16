function tabout = checktable_m(tab)
% PURPOSE: Check monthly data table for missing data
% INPUTS:
% tabin - data table, T x N

[T, N] = size(tab);

% check for breaks in the timeline
dd = tab.year*12+tab.month;
if any(diff(dd)-1), error('break in the timeline!'), end

ibegend = nan(N,3);
for n = 1:N
       ifirst = find(~isnan(tab{:,n}),1,'first');
       ilast = find(~isnan(tab{:,n}),1,'last');
       if isempty(ifirst), ifirst = 1; end
       if isempty(ilast), ilast = T; end
       nmid = sum(isnan(tab{ifirst:ilast,n}));
       ibegend(n,:) = [ifirst ilast nmid];
       fprintf('%-20s %d-%02d - %d-%02d  #internal NaNs: %d\n', ...
           tab.Properties.VariableNames{n}, tab{ifirst,1:2}, tab{ilast,1:2}, nmid)
end

ifirst = max(ibegend(:,1));
ilast = min(ibegend(:,2));
if ifirst>1 || ilast<T
    disp(' ')
    fprintf('Truncating sample from: %d-%02d - %d-%02d\n', tab{1,1:2}, tab{end,1:2})
    fprintf('         to new sample: %d-%02d - %d-%02d\n', tab{ifirst,1:2}, tab{ilast,1:2})
else
    disp(' ')
    disp('No need to truncate the sample')
end
tabout = tab(ifirst:ilast,:);
fprintf('Number of observations: %d, number of variables: %d\n', size(tabout))
end