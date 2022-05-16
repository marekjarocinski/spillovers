% plot irfs to one shock, all variables in a single plot
% assumes defined:
% N,names,namedict,irfs_draws,qtoplot,mycolor,outdir,specid

fh = figure('Units','centimeters','Position',[3 1 12 20]);
for vv = 1:N
    varname = names{vv};
    try
        varname_nice = variabledb{varname,1};
        ylims = variabledb{varname,2:3};
    catch
        varname_nice = strrep(varname,'_','-');
        ylims = nan(1,2);
    end
    toplot = squeeze(quantile(myirf(vv,:,:),qtoplot,3));

    subplot(ceil(N/2), 2, vv)
    hold on
    %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], 0.9*[1 1 1], 'EdgeColor', 'none')
    fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], mycolor{:}, 'EdgeColor', 'none')
    plot(tt,toplot(:,1)','-k','LineWidth',2);
    yline(0)
    xlabel('months')
    title(varname_nice, 'FontWeight', 'normal')
    axis tight
end
