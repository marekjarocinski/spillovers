% Estimate local projections for fixed shocks.
% Make latex tables and plots.
clear all, close all

%%%%% Preamble %%%%%
% determine the shocks to use (uncomment one)
shockspec = 'ecb_mpd_me_njt'; % ECB shocks
% shockspec = 'fed_gssipa_me_99njt'; % Fed shocks
% shockspec = 'macro_releases'; % Macro release surprises

% determine the shock type to use (uncomment one)
shocktype = 'median'; Xnames = {'MP_median','CBI_median'};
%shocktype = 'pm'; Xnames = {'MP_pm','CBI_pm'};
%shocktype = 'q25'; Xnames = {'MP_q25','CBI_q25'};
%shocktype = 'q75'; Xnames = {'MP_q75','CBI_q75'};
%shocktype = 'surp'; Xnames = {'pc1eon1_me_njt'};
%shocktype = 'z_ea_unemp'; Xnames = {shocktype};
%shocktype = 'z_ea_bcs_confind'; Xnames = {shocktype};

% determine the list of right-hand side variables (uncomment one)
varlist = {'sveny01_d','bund1y_d'};
% varlist = {'sveny01_d','bund1y_d','sveny10_d','bund10y_d'};
% varlist = {'sveny01_d','sveny10_d','sp500_d','bofaml_us_hyld_oas_d',...
%     'eurusd_d','broadexea_usd_d'};
% varlist = {'bund1y_d','bund10y_d','stoxx50_d','bofaml_ea_hyld_oas_d',...
%     'eurusd_d','broadexea_usd_d'};
% varlist = {'sp500geo_eu0w_d','sp500geo_us0w_d',...
%       'sp500fin_d', 'sp500exfin_d','willsmlcap_d', 'willlrgcap_d'};
% varlist = {'ffn_d','ff3_d','ff6_d'};

%%%%% End of the preamble %%%%%
%% Load and merge datasets
% shocks
switch shockspec
    case {'ecb_mpd_me_njt','fed_gssipa_me_99njt'}
        tabs = readtable("../data/shocks/shocks/shocks_"+shockspec+"_d.csv");
    case 'macro_releases'
        tabs = readtable('../data/shocks/data/z_ea.csv');
        tabs{:,2:end} = tabs{:,2:end}/100;
end
if not(ismember('date', tabs.Properties.VariableNames))
    tabs.date = datetime(tabs.year,tabs.month,tabs.day);
end
tabs(tabs.date>datetime(2019,6,30),:) = [];

% daily
tabd = readtable('../data/daily/main/daily.csv');
tabd.date = datetime(tabd.date, 'InputFormat', 'ddMMMyyyy');

% merge
tab = join(tabs, tabd, 'Keys', {'date'});
clear tabs tabd

% sample
%tab(logical(tab.d_fedtightcycle),:) = [];
%tab(~logical(tab.d_usarecdm),:) = [];
%tab(tab.date>datetime(2008,12,16) & tab.date<datetime(2015,12,15),:) = [];
%tab(tab.date>datetime(2008,12,16),:) = [];

outdir = shockspec+"/";
mkdir(outdir);

%% Estimate
tt = [1, 2, 3, 4, 5, 10, 15, 20, 25, 30]';
hstrings = {'f1l1', 'f2l1', 'f3l1', 'f4l1', 'f5l1', 'f10l1', 'f15l1', 'f20l1', 'f25l1', 'f30l1'};
namedict = jsondecode(fileread('nicenames_d.json'));

fnames = strings(length(varlist),1);
for vv = 1:length(varlist)
    varname = varlist{vv};

    if length(Xnames)==1
        rowNames = {'b1','s1','R-sq','N.obs.'};
        restab = table('Size', [length(rowNames) 0], 'RowNames', rowNames);
    elseif length(Xnames)==2
        rowNames = {'b1','s1','b2','s2','Ftest','R-sq','N.obs.'};
        restab = table('Size', [length(rowNames) 0], 'RowNames', rowNames);
    end

    % estimate LP for each horizon
    for hh = 1:length(hstrings)
        yname = {[hstrings{hh} varname]};

        mdl = fitlm(tab(:,[Xnames yname]));
        if isnan(mdl.Rsquared.Ordinary) % prevent crash when missing data
            coeff = zeros(length(Xnames)+1,1); EHWse = zeros(length(Xnames)+1,1);
        else
            [EHWcov,EHWse,coeff] = hac(mdl, 'type', 'HC', 'display', 'off');
        end

        if length(Xnames)==1
            res_h = [coeff(2), EHWse(2), mdl.Rsquared.Ordinary, mdl.NumObservations];
        elseif length(Xnames)==2
            pvalF = linhyptest(coeff, EHWcov, 0, [0 1 -1], mdl.DFE);
            res_h = [coeff(2), EHWse(2), coeff(3), EHWse(3), pvalF, mdl.Rsquared.Ordinary, mdl.NumObservations];
        end

        restab = addvars(restab, res_h', 'NewVariableNames', yname);
    end

    % latex table
    restable2latex(restab, rowNames);
    restable2latex(restab, rowNames, sprintf('%s%s-%s.tex', outdir, varname, shocktype));

    % plot
    if isfield(namedict, varname)
        varname_nice = getfield(namedict, varname);
    else
        varname_nice = strrep(varname,'_','-');
    end

    fh = figure('Units','centimeters','Position',[10 10 7 4]);
    if length(Xnames)==1
        toplot = [restab{1,:}; restab{1,:} + restab{2,:}; restab{1,:} - restab{2,:}]';
        hold on
        %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], 0.9*[1 1 1], 'EdgeColor', 'none')
        fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], [158,188,218]/255, 'EdgeColor', 'none')
        plot(tt,zeros(size(tt)),'-k');
        plot(tt,toplot(:,1)','-k','LineWidth',2);
    end
    if length(Xnames)==2
        % MP
        toplot = [restab{1,:}; restab{1,:} + restab{2,:}; restab{1,:} - restab{2,:}]';
        hold on
        %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], [0.7 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3)
        fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], [0.5 0.6 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3)
        plot(tt,zeros(size(tt)),'-k');
        plot(tt,toplot(:,1)','-b','LineWidth',2)
        % CBI
        toplot = [restab{3,:}; restab{3,:} + restab{4,:}; restab{3,:} - restab{4,:}]';
        hold on
        %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.7)
        fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], [1 0.5 0.5], 'EdgeColor', 'none', 'FaceAlpha', 0.7)
        plot(tt,zeros(size(tt)),'-k');
        plot(tt,toplot(:,1)','-r.','LineWidth',1)
    end
    xlabel('horizon h (business days)')
    title(varname_nice, 'FontWeight', 'normal')
    axis tight
    fname = sprintf('%s%s-%s.pdf', outdir, varname, shocktype);
    exportgraphics(fh, fname)
    fnames(vv) = fname;
end



%% optional: align y axes for groups of 3 figures
if 0
    fhh = flipud(findobj('Type','figure'));
    sameaxes('y',fhh(1:3))
    sameaxes('y',fhh(4:6))
    sameaxes('y',fhh(7:9))
    sameaxes('y',fhh(10:12))
    for vv = 1:length(varlist)
        fh = fhh(vv);
        fh.Children.Title.Visible = 'off';
        exportgraphics(fh, fnames(vv))
    end
end

