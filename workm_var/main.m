% Estimate VAR irfs
clear all, close all

%%%%% Preamble %%%%%
% determine the list of variables in the VAR
specid = 'us_gdp'; % us_gdp or us_wx or us_kr or ea_gdp or ea_wx or ea_kr

% determine the source of the shocks (uncomment one)
%shocksrc = 'fed';
shocksrc = 'ecb';

% determine the type of the shock (uncomment one)
shockid = 'sgnm2'; % sign restrictions with uniform prior on rotations (default)
%shockid = 'pm'; % poor man / simple shocks
%shockid = 'med'; % median rotation sign restrictions

%%%%% End of the preamble %%%%%

spl = timerange('1999-01-01','2019-06-01','months');

specname = sprintf('%s_%s_%s', specid, shocksrc, shockid);

switch specid
% us
    case 'us_gdp'
        ynames = {'sveny01_a','sveny10_a','sp500_a','bofaml_us_hyld_oas_a','eurusd_a','broadexea_usd_a','us_rgdp','us_gdpdef'};
    case 'us_ff'
        ynames = {'fedfunds','sveny01_a','sp500_a','bofaml_us_hyld_oas_a','eurusd_a','broadexea_usd_a','us_rgdp','us_gdpdef'};
    case 'us_wx'
        ynames = {'us_wuxia','sveny01_a','sp500_a','bofaml_us_hyld_oas_a','eurusd_a','broadexea_usd_a','us_rgdp','us_gdpdef'};
    case 'us_kr'
        ynames = {'us_krippner','sveny01_a','sp500_a','bofaml_us_hyld_oas_a','eurusd_a','broadexea_usd_a','us_rgdp','us_gdpdef'};
% EA
    case 'ea_gdp'
        ynames = {'bund1y_a','bund10y_a','stoxx50_a','bofaml_ea_hyld_oas_a','eurusd_a','broad_eur','ea_rgdp','ea_gdpdef'};
    case 'ea_wx'
        ynames = {'ea_wuxia','bund1y_a','stoxx50_a','bofaml_ea_hyld_oas_a','eurusd_a','broad_eur','ea_rgdp','ea_gdpdef'};
    case 'ea_kr'
        ynames = {'ea_krippner','bund1y_a','stoxx50_a','bofaml_ea_hyld_oas_a','eurusd_a','broad_eur','ea_rgdp','ea_gdpdef'};
end

switch shocksrc
    case 'ecb'
        tabm = readtable('../data/shocks/shocks/shocks_ecb_mpd_me_njt_m.csv');
        switch shockid
            case 'pm'
                mnames = {'MP_pm','CBI_pm'};
            case 'med'
                mnames = {'MP_median','CBI_median'};
            case 'sgnm2'
                mnames = {'pc1eon1_me_njt','stoxx50_me_njt'};
        end
    case 'fed'
        tabm = readtable('../data/shocks/shocks/shocks_fed_gssipa_me_99njt_m.csv');
        switch shockid
            case 'pm'
                mnames = {'MP_pm','CBI_pm'};               
            case 'med'
                mnames = {'MP_median','CBI_median'};
            case 'sgnm2'
                mnames = {'pc1ff1_hf','sp500_hf'};
        end
end
outdir = [shocksrc '/'];
mkdir(outdir)

% load variables
taby = readtable('../data/monthly/data_monthly.csv');
% common sample
keys = {'year','month'};
tab = outerjoin(tabm, taby, 'Keys', keys, 'LeftVariables', [mnames], 'RightVariables', [ynames keys]);
tab = movevars(tab,keys,'Before',1);
tab(isnan(tab.year),:) = [];
tab.date = datetime(tab.year,tab.month,1);
tab = table2timetable(tab);
tab = tab(spl,:);
tab = fillmissing(tab,'constant',0,'DataVariables',mnames); % fill zero shocks
tab = checktable_m(tab); % drop missing observations if any

writetimetable(tab, sprintf('%sdata_%s.csv',outdir, specname))
names = [mnames ynames];
y = tab{:, names};
w = ones(size(tab, 1), 1); % constant term

% minnesota prior
prior.lags = 6;
prior.minnesota.mvector = [zeros(length(mnames),1); ones(length(ynames),1)];
prior.minnesota.tightness = 0.2;
prior.minnesota.decay = 1;
prior.minnesota.exog_std = 1e3;

% estimate the VAR
rng(1)
data.Nm = 2; data.names = names; data.y = y; data.w = ones(size(y,1),1);
gssettings.ndraws = 2000; gssettings.burnin = 2000; gssettings.saveevery = 4;
res = VAR_withiid1(data, prior, gssettings, 1);

% plot options
nsteps = 36;
qtoplot = [0.5 0.16 0.84 0.05 0.95];
N = length(names);

% compute irfs
switch shockid
    case 'sgnm2' % baseline two sign restrictions
        dims = {[1 2]};
        test_restr = @(irfs)...
            irfs(1,1,1) > 0 && irfs(2,1,1) < 0 &&... % mp
            irfs(1,2,1) > 0 && irfs(2,2,1) > 0; % cbi
        b_normalize = true;
        max_try = 1000;
        disp(test_restr)
        irfs_draws = resirfssign(res, nsteps, dims, test_restr, b_normalize, max_try);

    otherwise % choleski
        ndraws = size(res.beta_draws,3);
        irfs_draws = NaN(N,N,nsteps,ndraws);
        for i = 1:ndraws
            betadraw = res.beta_draws(1:end-size(w,2),:,i);
            sigmadraw = res.sigma_draws(:,:,i);
            response = impulsdtrf(reshape(betadraw',N,N,prior.lags), chol(sigmadraw), nsteps);
            irfs_draws(:,:,:,i) = response;
        end
end

%% plot irfs
vardb = readtable("nicenames_m.csv",'ReadRowNames',true);

% only MP
if strcmp([shocksrc specid],'ecbea_gdp') || strcmp([shocksrc specid],'fedus_gdp')
    myirf = squeeze(irfs_draws(:,1,:,:));
    myline = {'-b','LineWidth',2};
    mycolor = {[0.5 0.6 1], 'FaceAlpha', 0.3};
    myvardb = vardb(:,1);
    myvartoplot = 1:N;
    myid = [specname '-mp'];

    plot_irfs_one_plot_per_variable
end


% both MP and CBI
myirf = squeeze(irfs_draws(:,1,:,:));
myirf2 = squeeze(irfs_draws(:,2,:,:));
myline = {'-b','LineWidth',2};
mycolor = {[0.5 0.6 1], 'FaceAlpha', 0.3};
myline2 = {'-r.','LineWidth',1};
mycolor2 = {[1 0.5 0.5], 'FaceAlpha', 0.7};
myvardb = vardb(:,1);
myvartoplot = 1:N;
myid = specname;

plot_irfs_one_plot_per_variable




% all in one plot
shocks = 1:2;
fh = figure('Units','centimeters','Position',[3 1 12 20]);
for vv = 1:N
    for ss = shocks
        subplot(N, length(shocks), (vv-1)*length(shocks)+ss)
        toplot = squeeze(quantile(irfs_draws(vv,ss,:,:),qtoplot,4));
        hold on
        fill([tt' flipud(tt)'], [toplot(:,4)' flipud(toplot(:,5))'], 0.9*[1 1 1], 'EdgeColor', 'none')
        fill([tt' flipud(tt)'], [toplot(:,2)' flipud(toplot(:,3))'], 0.7*[1 1 1], 'EdgeColor', 'none')
        plot(tt,toplot(:,1)','-k','LineWidth',2);
        yline(0)
        axis tight
        title(sprintf('%d->%s',ss,names{vv}), 'Interpreter', 'none', 'FontWeight', 'normal')
        if vv==N, xlabel('months'), end
    end
end
fname_irf = sprintf('%sirfs_%s.pdf', outdir, specname);
exportgraphics(fh, fname_irf)

