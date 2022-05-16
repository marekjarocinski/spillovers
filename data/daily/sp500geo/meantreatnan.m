function s = meantreatnan(x, defval)
s = mean(x, 2, 'omitnan');
s(isnan(s)) = defval;
end