% plot irfs, one variable per plot
% assumes defined:
% myirf(*2),myvartoplot,names,myvardb,qtoplot,mycolor(*2),myline(*2),outdir,myid

tt = (0:(size(myirf,2)-1))';

for vv = myvartoplot
    varname = names{vv};

    try
        varname_nice = myvardb{varname,1};
        if size(myvardb,2)>1
            ylims = myvardb{varname,2:3};
        else
            ylims = nan(1,2);
        end
    catch
        varname_nice = strrep(varname,'_','-');
        ylims = nan(1,2);
    end

    toplot = squeeze(quantile(myirf(vv,:,:),qtoplot,3));

    fh = figure('Units','centimeters','Position',[10 10 7 4]);
    hold on
    %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], [0.7 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3)
    fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], mycolor{:}, 'EdgeColor', 'none')
    plot(tt,toplot(:,1)',myline{:})

    if exist('myirf2') && not(isempty(myirf2))
        toplot2 = squeeze(quantile(myirf2(vv,:,:),qtoplot,3));

        %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.7)
        fill([tt' flipud(tt)'], [toplot2(:,2)' flipud(toplot2(:,3))'], mycolor2{:}, 'EdgeColor', 'none')
        plot(tt,toplot2(:,1)',myline2{:})
    end
 
    yline(0)
    xlabel('months')
    title(varname_nice, 'FontWeight', 'normal')
    axis tight
    if all(~isnan(ylims)), ylim(ylims), end
    fname = sprintf('%s%s-%s.pdf', outdir, myid, varname);
    exportgraphics(fh, fname)
end