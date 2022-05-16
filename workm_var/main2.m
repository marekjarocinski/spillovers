% Counterfactual impulse responses
clear all, close all

specid = 'us';
ynames = {'us_wuxia','sp500_a','bofaml_us_hyld_oas_a','eurusd_a','broadexea_usd_a','us_rgdp','us_gdpdef'};

ecb = readtable('../data/shocks/shocks/shocks_ecb_mpd_me_njt_m.csv');
fed = readtable('../data/shocks/shocks/shocks_fed_gssipa_me_99njt_m.csv');
keys = ["year","month"];
tabm = innerjoin(ecb, fed, 'Keys', keys);
% spol = 1; % position of the policy shock
% ssrc = 2; % position of the source of the disturbance shock
% vpol = 3; % position of the variable capturing the policy response
mnames = {'MP_median_fed','MP_median_ecb'};
spol = 1; ssrc = 2; vpol = 3;

outdir = 'cfact/';
mkdir(outdir)

% load variables
taby = readtable('../data/monthly/data_monthly.csv');
% common sample
keys = ["year","month"];
tab = innerjoin(tabm, taby, 'Keys', keys, 'LeftVariables', [keys mnames], 'RightVariables', ynames);
tab = checktable_m(tab); % drop missing observations if any

writetable(tab, sprintf('%sdata_us.csv',outdir, specid))
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
tt = (0:(nsteps-1))';
qtoplot = [0.5 0.16 0.84 0.05 0.95];
N = length(names);

% compute irfs
shockid = 'med';
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

%% compute counterfactual irfs shutting down Fed policy response
close all
vardb = readtable("nicenames_m.csv",'ReadRowNames',true);


% plot irf to the policy shock spol
myirf = squeeze(irfs_draws(:,spol,:,:));
myid = [specid '-spol'];
mycolor = {[117,107,177]/255, 'FaceAlpha', 0.3};
myline = {'-k','LineWidth',1.5};
myvardb = vardb;
myvartoplot = 1:N;
plot_irfs_one_shock_all_variables
sgtitle('Fed MP')
plot_irfs_one_plot_per_variable

% compute and plot counterfactual irf to the source shock ssrc
for lam = [0 0.5 1]
    cfact_draws = nan(N,nsteps,ndraws);
    for ii = 1:ndraws
        cfact = squeeze(irfs_draws(:,ssrc,:,ii));
        irf2 = squeeze(irfs_draws(:,spol,:,ii));
        for hh = 1:nsteps
            cfact(:,hh:end) = cfact(:,hh:end) ...
                - lam*cfact(vpol,hh)/irf2(vpol,1)*irf2(:,1:end+1-hh);
        end
        cfact_draws(:,:,ii) = cfact;
    end

    switch lam
        case 0
            cfact_draws0 = cfact_draws;
        case 1
            cfact_draws1 = cfact_draws;
    end

    myirf = cfact_draws;
    myid = sprintf('%s-cfact%g', specid, lam);
    switch lam
        case 0
            mycolor = {[0.5 0.6 1],'FaceAlpha',0.3};
        otherwise
            mycolor = {[0.9290 0.6940 0.1250],'FaceAlpha',0.5};
    end
    
    plot_irfs_one_shock_all_variables
    sgtitle(sprintf('Counterfactual lam=%.2f', lam))
    fname_cfact = sprintf('%scfact_%.2f.pdf', outdir, lam);
    exportgraphics(fh, fname_cfact)

    plot_irfs_one_plot_per_variable
end

% plot both raw source shock and dampened source shock
myirf = cfact_draws0;
myirf2 = cfact_draws1;
myline = {'-b','LineWidth',1.2};
mycolor = {[0.5 0.6 1], 'FaceAlpha', 0.3};
myline2 = {'-m','LineWidth',2};
mycolor2 = {[117,107,177]/255, 'FaceAlpha', 0.3};
myvardb = vardb;
myvartoplot = 1:N;
myid = 'cfact';

plot_irfs_one_plot_per_variable

close all
