function result = VAR_withiid(data, prior, gssettings, printout)
% result = VAR_withiid(data, prior, gssettings, printout)
% PURPOSE: inference in a VAR with some i.i.d. variables
% THIS VERSION DOES NOT ALLOW MISSING VALUES IN M
%
% The VAR model with parameters B,Sigma is
%   M = Um
%   Y = X B + Uy
% where X = [ lagged M's and Y's, W ] and each row of U is N(0,Sigma).
%
% INPUTS:
% data - structure with variables
% data.y - T x N data on endogenous variables
% data.Nm - number of i.i.d variables m (ordered first)
% data.w - T x Nw data on exogenous variables (the same number of observations as y)
% data.names - cell array with names of the variables, m first, y second
% prior - structure with prior hyperparameters + n. of lags
% gssettings - settings of the Gibbs sampler
% printout (optional) - controls how much printout, default=1
%
% DESCRIPTION OF prior:
%
% compulsory field:
% prior.lags - number of lags
%
% prior.minnesota - settings of the Minnesota prior
% example of the prior.minnesota struct:
% prior.minnesota.mvector = [1 1 0 1 0 0]; % means of own lags
% prior.minnesota.tightness = 0.2;
% prior.minnesota.decay = 1;
% prior.minnesota.sigma_deg = N+2; % degrees of freedom of p(Sigma)
%   p(Sigma) = IW(S,sigma_deg)
%   need sigma_deg > N-1 for the prior to be proper
%   need sigma_deg > N+1 for the E(Sigma) to exist
%   optional, default: sigma_deg = N+2
%
% RETURNS: result - struct with various posterior results
% result.prior - prior
% result.logdensy - log marginal likelihood
% result.beta - posterior mean of the reduced form VAR parameters, K by N
% result.sigma - posterior mean of the reduced form error variance, N by N
% result.beta_draws - draws of beta from the posterior, K by N by n_draws
% result.sigma_draws - draws of sigma from the posterior, N by N by n_draws
%
% DEPENDS: -
% SUBFUNCTIONS: varlags, multgammaln
%
% Marek Jarocinski 2016-July; 2016-September; 2017-June; 2021-Jan

[T,N] = size(data.y); % T is the length of the whole sample (including initial observations)
[Tw,Nw] = size(data.w); if Tw~=T, error('y and w have different lengths'), else clear Tw, end
Nm = data.Nm;
Ny = N - Nm;
if any(any(isnan(data.y))); error('missing data in y'); end
P = prior.lags;
T = T-P; % now T is the length of the effective sample
n_m = 1:Nm; n_y = Nm+(1:Ny);
K = P*N+Nw; % number of columns in X

if nargin<4, printout = 1; end

if printout
    disp(' ')
    disp(mfilename)
    disp(['lags: ' num2str(prior.lags)])
end

if ~isfield(gssettings,'saveevery'), gssettings.saveevery = 1; end
if ~isfield(gssettings,'waitbar'), gssettings.waitbar = 1; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% construct the prior from the supplied prior hyperparameters
% Minnesota prior
if isfield(prior,'minnesota') && isfield(prior.minnesota,'tightness')
    % default values if something not supplied
    if ~isfield(prior.minnesota,'exog_std')
        prior.minnesota.exog_std = 1e5;
    end
    if ~isfield(prior.minnesota,'decay')
        prior.minnesota.decay = 1;
    end
    
    if ~isfield(prior.minnesota,'sigma')
        % compute sigma = standard errors from univariate autoregressions
        if ~isfield(prior.minnesota,'sigma_data')
            % sigma is computed from univariate autoregressions on sigma_data
            % default: sigma_data is identical to the actual sample
            prior.minnesota.sigma_data = data.y;
        end
        prior.minnesota.sigma = zeros(1,N);
        if ~isfield(prior.minnesota,'sigma_arlags')
            prior.minnesota.sigma_arlags = ...
                max(0,min(P, size(prior.minnesota.sigma_data,1)-3));
            % when a very short sample is supplied use fewer lags
        end
        for n = 1:N
            yn = prior.minnesota.sigma_data(:,n); yn = yn(~isnan(yn));
            [yn, ylagsn] = varlags(yn,prior.minnesota.sigma_arlags);
            Xn = [ylagsn ones(size(yn))];
            bn = Xn \ yn;
            prior.minnesota.sigma(n) = std(yn - Xn*bn);
        end
    else
        prior.minnesota.sigma = prior.minnesota.sigma(:)'; % ensure sigma is a row vector
    end
    if isfield(prior.minnesota,'sigma_factor')
        prior.minnesota.sigma = prior.minnesota.sigma .* prior.minnesota.sigma_factor;
    end
    
    % prior for the coefficients
    % p(B|Sigma) = N( vecB0, Q0 )
    if ~isinf(prior.minnesota.tightness)
        temp1 = kron(((1:P)').^-prior.minnesota.decay, ones(N,N)); % p^-d
        temp2 = repmat(prior.minnesota.sigma,P*N,1); % sigma_i
        temp3 = repmat(prior.minnesota.sigma'.^-1,P,N); % /sigma_j
        Q0 = prior.minnesota.tightness*temp1.*temp2.*temp3;
        Q0 = [Q0; repmat(prior.minnesota.exog_std,1,N)]; % this assumes there is only constant term in w
        Q0 = Q0.^2;
        Q0(:,1:Nm) = []; % drop the equations for m
        prior.Q = spdiags(Q0(:),0,K*Ny,K*Ny);
        prior.Qinv = spdiags(Q0(:).^-1,0,K*Ny,K*Ny);
        
        prior.B = zeros(K,N);
        if ~isfield(prior.minnesota,'mvector')
            prior.minnesota.mvector = ones(1,N);
        elseif (length(prior.minnesota.mvector) > N)
            warning('Minnesota prior: mvector too long, truncating'); %#ok<WNTAG>
        elseif length(prior.minnesota.mvector)==Ny
            prior.minnesota.mvector = [zeros(Nm,1); prior.minnesota.mvector(:)];
        end
        prior.B(1:N,1:N) = diag(prior.minnesota.mvector(1:N));
        prior.B(:,1:Nm) = []; % drop the equations for m
        prior.QinvB_reshaped = reshape(prior.Qinv*prior.B(:), K, Ny);
    end
    
    % Sims' dummy observations
    if isfield(prior,'simsdummy')
        if ~isfield(prior.simsdummy,'oneunitroot') prior.simsdummy.oneunitroot = 0; end
        if ~isfield(prior.simsdummy,'oneunitrootc') prior.simsdummy.oneunitrootc = 0; end
        if ~isfield(prior.simsdummy,'oneunitrooty') prior.simsdummy.oneunitrooty = 0; end
        if ~isfield(prior.simsdummy,'nocointegration') prior.simsdummy.nocointegration = 0; end
        if prior.simsdummy.oneunitroot || prior.simsdummy.oneunitrootc || prior.simsdummy.oneunitrooty || any(prior.simsdummy.nocointegration)
            ybar = [zeros(1,Nm) mean(data.y(1:P,Nm+1:end),1)]; Xprior = []; Yprior = [];
            if prior.simsdummy.oneunitroot
                Xprior = [Xprior; repmat(ybar,1,P)*prior.simsdummy.oneunitroot, prior.simsdummy.oneunitroot*data.w(P,:)];
                Yprior = [Yprior; ybar*prior.simsdummy.oneunitroot];
            end
            if prior.simsdummy.oneunitrootc
                Xprior = [Xprior; zeros(1,P*N) prior.simsdummy.oneunitrootc*data.w(P,:)];
                Yprior = [Yprior; zeros(1,N)];
            end
            if prior.simsdummy.oneunitrooty
                Xprior = [Xprior; repmat(ybar,1,P)*prior.simsdummy.oneunitrooty 0*data.w(P,:)];
                Yprior = [Yprior; ybar*prior.simsdummy.oneunitrooty];
            end
            if any(prior.simsdummy.nocointegration)
                temp = diag(ybar.*prior.simsdummy.nocointegration);
                if isfield(prior,'minnesota') && isfield(prior.minnesota,'mvector')
                    temp = temp(logical(prior.minnesota.mvector),:);
                end
                Xprior = [Xprior; repmat(temp,1,P) zeros(size(temp,1),size(data.w,2))];
                Yprior = [Yprior; temp];
            end
            % we will only add dummy observation priors to the equations for y,
            % so prepare a 'Sigmayinv' that only corresponds to y
            tempSigmayinv = prior.minnesota.sigma.^-1; tempSigmayinv(1:Nm) = []; tempSigmayinv = diag(tempSigmayinv);
            prior.simsdummy.Qinv = kron(tempSigmayinv,Xprior'*Xprior);
            prior.simsdummy.QinvB_reshaped = Xprior'*Yprior(:,Nm+1:end)*tempSigmayinv;
            prior.Qinv = prior.Qinv + prior.simsdummy.Qinv;
            prior.QinvB_reshaped = prior.QinvB_reshaped + prior.simsdummy.QinvB_reshaped;
        end
    end
    
    % prior for the variance
    % p(Sigma) = IW(Sprior,vprior)
    if ~isfield(prior,'v')
        prior.v = N + 2;
    end    
    prior.S = diag(prior.minnesota.sigma.^2*(prior.v - N - 1));

    if printout
        disp('Minnesota prior');
        disp(['Note: for a proper prior need sigma_deg > ' num2str(N-1)])
        disp(['Note: for E(Sigma) to exist need sigma_deg > ' num2str(N+1)])
        disp(prior.minnesota)
        if isfield(prior,'simsdummy'), disp(prior.simsdummy); end
        disp(prior)
    end
end
% store the prior
result.prior = prior;

% if initial values of m are missing, replace with zeros
temp = data.y(1:P,1:Nm); temp(isnan(temp)) = 0; data.y(1:P,1:Nm) = temp;

% prepare data matrices
[Y,X] = varlags(data.y,P);
X = [X data.w(P+1:end,:)]; % add the exogenous variables
result.Y = Y;
result.X = X;
result.Y0 = data.y(1:P,:);
result.lags = P;

if printout
    disp(['Sample with T = ' num2str(T) ' and N = ' num2str(N) '.'])
    disp(['Y(1,1) = ' num2str(Y(1,1)) '; Y(T,N) = ' num2str(Y(T,N))])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POSTERIOR SIMULATION
if gssettings.ndraws
    
    % starting values
    BB = [zeros(K,Nm) reshape(prior.B(:) + chol(prior.Q)'*randn(K*Ny,1), K, Ny)];
%     temp = randn(prior.v, N);
%     Sigma = chol(prior.S)'/(temp'*temp)*chol(prior.S);
    Sigma = prior.S/(prior.v - N - 1);
    
    result.v = round(T + prior.v);
    
    % simulation length - derived from burnin, ndraws, saveevery
    ndraws = gssettings.ndraws;
    nalldraws = gssettings.burnin + ndraws * gssettings.saveevery;
    
    % allocate space for the posterior draws
    result.beta_draws = nan(K,N,ndraws);
    result.sigma_draws = nan(N,N,ndraws);
    
    % last preparations
    it_save = 0;
    if isfield(gssettings,'waitbar') && gssettings.waitbar, waitbar_handle = waitbar(0,'Gibbs sampler','Name','Gibbs sampler running'); end
    timing_start = now;
    disp(['start: ',datestr(timing_start,0), '; total iterations: ', num2str(nalldraws)])
    
    % Gibbs sampler
    for draw = 1:nalldraws
        
        % draw Sigma
        U = Y - X*BB;
        Spost = U'*U + prior.S;
        Spost_chol = chol(Spost)';
        temp = randn(result.v, N);
        Sigma = Spost_chol/(temp'*temp)*Spost_chol';

        
        % draw B
        Csig = chol(Sigma,'lower');
        SigmaYY1inv = Csig(n_y,n_y)'\(Csig(n_y,n_y)\eye(Ny));
        A = prior.Qinv + kron(SigmaYY1inv, X'*X);
        yst = Y(:,n_y) - Y(:,n_m)/Csig(n_m,n_m)'*Csig(n_y,n_m)';
        a = prior.QinvB_reshaped + X'*yst*SigmaYY1inv;
        C = chol(A);
        B = C \ (C'\a(:) + randn(K*Ny,1)); % use Chan (2015) formula
        BB = [zeros(K,Nm) reshape(B, K, Ny)];
        
        
        % report progress
        if gssettings.waitbar && ~rem(draw,gssettings.saveevery*10)
            waitbar(draw/nalldraws, waitbar_handle, timing_message(draw, nalldraws, timing_start))
        end
        % save current iteration if appropriate
        if draw>gssettings.burnin && ~rem(draw,gssettings.saveevery)
            it_save = it_save + 1;
            result.beta_draws(:,:,it_save) = BB;
            result.sigma_draws(:,:,it_save) = Sigma;
            %result.resid_draws(:,:,it_save) = U;
        end
    end
    if gssettings.waitbar, close(waitbar_handle), end
    disp(timing_message(draw, nalldraws, timing_start))
end
result.fnname = mfilename;
end % of VAR_withiid


% SUBFUNCTIONS
function [ynew,ylags] = varlags(y,P)
[T,N] = size(y);
ynew = y(P+1:end,:);
ylags = zeros(T-P,P*N);
for p = 1:P
    ylags(:,N*(p-1)+1:N*p) = y(P+1-p:T-p,:);
end
end

