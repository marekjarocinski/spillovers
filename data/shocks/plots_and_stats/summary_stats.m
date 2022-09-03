function summary_stats(M, name1, name2)
% print out summary statistics in LaTeX

meanval = mean(M);
stdval = std(M);
meanstd = stdval/sqrt(size(M,1));
[R1, P1] = corr(M(2:end,1),M(1:end-1,1));
[R2, P2] = corr(M(2:end,2),M(1:end-1,2));
R = corr(M);
n_opp_sign = sum(M(:,1).*M(:,2)<0);

fprintf("Mean (std. err.) & %0.2f (%0.2f) & & %0.2f (%0.2f) \\\\\n", meanval(1), meanstd(1), meanval(2), meanstd(2))
fprintf("Standard deviation & %0.2f & & %0.2f \\\\\n", stdval(1), stdval(2))
fprintf("Auto-correlation (P-value) & %0.2f (%0.2f) & & %0.2f (%0.2f) \\\\\n",R1, P1, R2, P2)
fprintf("Correlation (%s, %s) & & %0.2f \\\\\n", name1, name2, R(1,2))
fprintf('Frequency of sign(%s) $\\ne$ sign(%s) & & %0.2f \\\\\n', name1, name2, n_opp_sign/size(M,1))
fprintf("N. of observations & & %d \\\\\n\n", size(M,1))

end