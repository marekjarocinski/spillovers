function restable2latex(restab, rowNames, fnameout)

[Nrows, Ncols] = size(restab);

formatSpec = {' & %.2f', ' & (%.2f)', ' & %.2f', ' & (%.2f)', ' & %.2f', ' & %.2f', ' & %d'};
if Nrows == 4
    formatSpec(3:5) = [];
end

tex_rows = rowNames;

for hh = 1:Ncols
    res_h = restab{:, hh}';
    
    thisformatSpec = formatSpec;
    thisformatSpec{1} = [thisformatSpec{1} makestars(res_h(1)/res_h(2))];
    if Nrows == 7
        thisformatSpec{3} = [thisformatSpec{3} makestars(res_h(3)/res_h(4))];
    end
    tex_h = compose(thisformatSpec, res_h);
    
    tex_rows = strcat(tex_rows, tex_h);
end

texlast = repmat({' \\'}, 1, Nrows);
tex_rows = strcat(tex_rows, texlast);


tex_row0 = ['variable & ' strjoin(restab.Properties.VariableNames,' & ') '\\'];

if nargin>2
    fileID = fopen(fnameout,'w');
else
    fileID = 1;
end

fprintf(fileID, '%s\n', tex_row0);
for i = 1:length(tex_rows)
    fprintf(fileID, '%s\n', tex_rows{i});
end
fclose('all');


end


function stars = makestars(z)
% Make a string with the stars based on a z-test
pval = 2*normcdf(abs(z), 'upper');
stars = '';
if pval<0.01
    stars = '***';
elseif pval<0.05
    stars = '**';
elseif pval<0.1
    stars = '*';
else
    stars = '';
end
end