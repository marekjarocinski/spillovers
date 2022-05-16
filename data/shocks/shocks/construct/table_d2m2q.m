function [table_m, table_q] = table_d2m2q(table_d)
% PURPOSE: Aggregate data at daily frequency into monthly and quarterly by adding up.
% INPUTS:
% table_d - table with daily data where the first three columns are
%           year, month, day
% OUTPUTS:
% table_m - table with monthly data where the first two columns are
%           year, month and the remaining columns contain the variables
%           from table_d for this month added up, or 0 if no day from this
%           month is present in table_d
% table_q - table with quarterly data where the first two columns are
%           year, quarter
%

ymd = table_d{:,1:3};
data_d = table_d{:,4:end};
varnames = table_d.Properties.VariableNames(4:end);
nvar = size(data_d, 2);
years = ymd(1,1):ymd(end,1);

% Aggregate to monthly
% List of all years and months without holes
ym = [repelem(years, 12)', repmat(1:12, 1, length(years))'];
ym(ym(:,1)==years(1) & ym(:,2)<ymd(1,2), :) = [];
ym(ym(:,1)==years(end) & ym(:,2)>ymd(end,2), :) = [];
Tm = size(ym,1);
% Aggregate daily to monthly
data_m = zeros(Tm, nvar);
for m = 1:Tm
    tsel = ymd(:,1)==ym(m,1) & ymd(:,2)==ym(m,2);
    data_m(m,:) = sum(data_d(tsel,:), 1);
end
table_m = array2table([ym data_m], 'VariableNames', [{'year','month'} varnames]);

% Aggregate to quarterly
m2q = @(m) ceil(m/3);
% List of all years and quarters
yq = [repelem(years, 4)', repmat(1:4, 1, length(years))'];
yq(yq(:,1)==years(1) & yq(:,2)<m2q(ym(1,2)), :) = [];
yq(yq(:,1)==years(end) & yq(:,2)>m2q(ym(end,2)), :) = [];
Tq = size(yq,1);
% Aggregate monthly to quarterly
data_q = zeros(Tq, nvar);
for q = 1:Tq
    tsel = ym(:,1)==yq(q,1) & m2q(ym(:,2))==yq(q,2);
    data_q(q,:) = sum(data_m(tsel,:), 1);
end
table_q = array2table([yq data_q], 'VariableNames', [{'year','quarter'} varnames]);

end