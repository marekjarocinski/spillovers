% Estimate local projections for shocks with uniform prior over rotations.
% Make latex tables and plots.
clear all, close all

% determine the shocks to use (uncomment one)
shockspec = 'ecb_mpd_me_njt';
% shockspec = 'fed_gssipa_me_99njt';

% determine the list of right-hand side variables (uncomment one)
varlist = {'sveny01_d','sveny10_d','sp500_d','bofaml_us_hyld_oas_d',...
    'logvix_d','eurusd_d','broadexea_usd_d'};
% varlist = {'bund1y_d','bund10y_d','stoxx50_d','bofaml_ea_hyld_oas_d',...
%     'logvstoxx_d','eurusd_d','broadexea_usd_d'};
% varlist = {'sp500geo_eu0wus0w_d','spr_sp500_finexfin_d','spr_will_smllrgcap_d'};
% varlist = {'sp500geo_eu0w_d','sp500geo_us0w_d'};

%%%%% The remaining lines do not need to be modified. %%%%%
approach = 'hc'; % 'bayesian' or 'hc'
shocktype = 'sgnm2';
ndraws = 2000;
ntry = 100; % maximum number of rotations to try
qtoplot = [0.5 0.16 0.84 0.05 0.95];

%% Load and merge datasets
% shocks
tabs = readtable("../data/shocks/shocks/shocks_"+shockspec+"_d.csv");
tabs.date = datetime(tabs.year,tabs.month,tabs.day);
tabs(tabs.date>datetime(2019,6,30),:) = [];

% daily
tabd = readtable('../data/daily/main/daily.csv');
tabd.date = datetime(tabd.date, 'InputFormat', 'ddMMMyyyy');
% merge
tab = join(tabs, tabd, 'Keys', {'date'});
clear tabs tabd

outdir = shockspec+"_"+approach+"/";
mkdir(outdir);

%% Estimate
tt = [1, 2, 3, 4, 5, 10, 15, 20, 25, 30]';
hstrings = {'f1l1', 'f2l1', 'f3l1', 'f4l1', 'f5l1', 'f10l1', 'f15l1', 'f20l1', 'f25l1', 'f30l1'};
namedict = jsondecode(fileread('nicenames_d.json'));

M = tab{:,4:5}; % iTot and S
[QQ,RR] = qr(M,0);

K = size(M,2) + 1; % n.of. parameters, including constant term

fnames = strings(length(varlist),1);
for vv = 1:length(varlist)
    varname = varlist{vv};

    rowNames = {'b1','s1','b2','s2','blah1','blah2','N.obs.'};
    restab = table('Size', [length(rowNames) 0], 'RowNames', rowNames);
    toplot1 = nan(length(hstrings), length(qtoplot));
    toplot2 = nan(length(hstrings), length(qtoplot));

    % estimate LP for each horizon
    for hh = 1:length(hstrings)
        yname = [hstrings{hh} varname];
        y = tab.(yname);

        % drawing shocks, then drawing coefs|shocks
        coefs_draws = nan(ndraws,K);

        for ii = 1:ndraws

            % 1. draw shocks
            % 1.1 find a rotation
            for jj = 1:ntry
                [PP,temp] = qr(randn(2,2)); % draw PP
                % flip P so the signs of i are positive
                toflip = PP(1,:)*RR(1,1)<0;
                PP(:,toflip) = -PP(:,toflip);
                % check the signs of s
                CCtil = PP'*RR;
                if CCtil(1,2)<0 && CCtil(2,2)>0
                    break
                end
            end
            % 1.2 normalize, so shocks add up to 1
            DD = diag(CCtil(:,1));
            UU = QQ*PP*DD;


            % drop missing observations
            UU = UU(not(isnan(y)),:);
            y = y(not(isnan(y)));
            T = length(y);
            %X = [M ones(T,1)];
            X = [UU ones(T,1)];

            % 2. draw coefs conditional on the drawn shocks
            switch approach
                case 'bayesian'
                    bhat = X\y;
                    shat = sumsqr(y-X*bhat);
                    sig2draw = 1/gamrnd(0.5*(T-K), 2/shat);
                    Qpost = (X'*X)\eye(K)*sig2draw;
                    bdraw = bhat + chol(Qpost,'lower')*randn(K,1);
                case 'hc'
                    mdl = fitlm(X,y,'Intercept',false);
                    [EHWcov,EHWse,coeff] = hac(mdl, 'type', 'HC', 'display', 'off');
                    bdraw = coeff + chol(EHWcov,'lower')*randn(K,1);
            end

            coefs_draws(ii,:) = bdraw';
        end

        toplot1(hh,:) = quantile(coefs_draws(:,1), qtoplot);
        toplot2(hh,:) = quantile(coefs_draws(:,2), qtoplot);

        res_h = [mean(coefs_draws(:,1)), std(coefs_draws(:,1)), mean(coefs_draws(:,2)), std(coefs_draws(:,2)), 0, 0, T];

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
    if 1
        % MP
        toplot = [restab{1,:}; restab{1,:} + restab{2,:}; restab{1,:} - restab{2,:}]';
        toplot = toplot1;
        hold on
        %fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], [0.7 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3)
        fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], [0.5 0.6 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3)
        plot(tt,zeros(size(tt)),'-k');
        plot(tt,toplot(:,1)','-b','LineWidth',2)
        % CBI
        toplot = [restab{3,:}; restab{3,:} + restab{4,:}; restab{3,:} - restab{4,:}]';
        toplot = toplot2;
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


