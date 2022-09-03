function fh = report_rotations(M)
% Report on the admissible rotations:
% 1. Print out a table, 
% 2. Scatter plot with admissible slopes

x = M(:,1);
y = M(:,2);

% decompositions
[U, C, a, a_range] = signrestr_quantile([x y]);
[U00, C00, a00] = signrestr_quantile([x y], 0);
[U25, C25, a25] = signrestr_quantile([x y], 0.25);
[U75, C75, a75] = signrestr_quantile([x y], 0.75);
[Ucc, Ccc, acc] = signrestr_quantile([x y], 1);

% table
disp('Table about admissible rotations')
disp('qqq  & cMP  & cCBI & varshare')
fprintf('00th & %.1f & %.1f & %.2f \\\\\n', C00(:,2)', cos(a00)^2)
fprintf('25th & %.1f & %.1f & %.2f \\\\\n', C25(:,2)', cos(a25)^2)
fprintf('50th & %.1f & %.1f & %.2f \\\\\n', C(:,2)', cos(a)^2)
fprintf('75th & %.1f & %.1f & %.2f \\\\\n', C75(:,2)', cos(a75)^2)
fprintf('100th & %.1f & %.1f & %.2f \\\\\n', Ccc(:,2)', cos(acc)^2)

% plot
xmin = min([x;-x]); xmax = max([x;-x]); ymin = min(y); ymax = max(y);
pos = [5,3,11,11];
fh = figure('Units','centimeters','Position',pos);
hold on
scatter(x,y,25,'black','o','filled','LineWidth',1)

% ranges for the rotations
xxxx = [xmin 0 xmax xmax 0 xmin];
fill(xxxx, xxxx.*[C00(1,2) 0 Ccc(1,2) C00(1,2) 0 Ccc(1,2)], 'blue', 'FaceAlpha', 0.3)
fill(xxxx, xxxx.*[0 0 0 1e6 0 1e6], 'red', 'FaceAlpha', 0.3)

% add the lines for the sign restriction shocks
line([-C(1,1) C(1,1)],[-C(1,2) C(1,2)],'LineStyle','-','Color','blue','LineWidth',2)
line([-C(2,1) C(2,1)],[-C(2,2) C(2,2)],'LineStyle','-','Color','red','LineWidth',2)
% text(0.75*xmin,C(1,2)/C(1,1)*0.75*xmin,'Monetary Policy shock','HorizontalAlignment','center','VerticalAlignment','bottom','Rotation',-49)
% text(0.75*xmax,C(2,2)/C(2,1)*0.75*xmax,'CB Information shock','HorizontalAlignment','center','VerticalAlignment','bottom','Rotation',49)

% finish up the plot
xline(0)
yline(0)
xlim([xmin,xmax])
ylim([ymin,ymax])
xlabel("Interest rate surprise");
ylabel("Stock price surprise");
