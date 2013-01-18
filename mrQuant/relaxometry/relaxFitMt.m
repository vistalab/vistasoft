function [f,k,s0,gof] = relaxFitMt(data,delta,r1,s0,tr,flipAngle,fitMethod,useParfor)
%
% [f,k,gof] = relaxFitMt(data,delta,t1,s0,tr,flipAngle,[fitMethod='f'],[useParfor=false])
% 
% Computes a nonlinear fit of the bound-pool (f) map.
%
% fitMethod = 'f' for fminsearch, 'l' for lsqnonlin.
%
% tr should be in seconds, flipAngle in radians. r1 is 1/t1.
%
% Returns:
%
% SEE ALSO:
% 
% relaxFitT1.m to fit the t1 and pd maps used by this function.
%
% HISTORY:
% 2008.02.26 RFD: wrote it.
% 2009.12.04 RFD: changed starting values to be a closer to the typical
% white matter values. I also tightened the range of allowable values for k
% to reflect the published values for brain tissue. Both of these changes
% have the effect of reducing crazy f-values, mostly in the csf. They do
% not seem to affect resulting f-values in the white matter, except in
% regions of high noise where the fits are unstable.

if(~exist('fitMethod','var')||isempty(fitMethod))
    fitMethod = 'f';
end
if(~exist('useParfor','var')||isempty(useParfor))
    useParfor = false;
end

% RFD: empirically, [1 .08] is the median for brain tissue. But, we mostly
% care about white matter, so we'll use the typical values for white matter
x0 = [3 .10];
%x0 = [2.4, .10]'; %this is our initial guess, bese [3.4, .15]'

% lb = [.1 .03]; % [k f]
% ub = [5 .28];
% 2009.12.04 RFD: tighten the reigns on k
lb = [0.9 .03]; % [k f]
ub = [4.5 .28];

t_m = 8e-3; %bese 8e-3
t_s = 5e-3; %bese 5e-3
t_r = 19e-3; %bese 19e-3
T2_B = 11e-6;
% The following (omega_1rms) is derived from the MT RF pulse shape. We
% hard-code a value here, but we should check it's validity.
% The angular freq of the MT pulse- the equivalent flip angle of the MT
% pulse (expressed in radians/sec).
%w1rms = 2400;
w1rms = 2400; % 382Hz * 2pi = 2400

for ii = 1:length(delta)
    W_B(ii) = pi*(w1rms^2)*lorentzian(delta(ii), T2_B);
end;

if(fitMethod=='l')
   options = optimset('LargeScale','on','LevenbergMarquardt','on', 'Display', 'off', 'MaxIter', 50);
else
   options = optimset('LargeScale','off','LevenbergMarquardt','on', 'Display', 'off', 'MaxIter', 50);
end

sz = size(data);
if(sz(1)~=numel(delta))
   error('size(data,1) must = numel(delta)!');
end

f = zeros(1,sz(2)); 
k = zeros(1,sz(2));
gof = zeros(1,sz(2));

% What we compute here is actually W_F./R1_F. R1_F is computed in
% the fit function, but we precompute the rest out here to save a
% few cpu cycles in the loop below.
W_F = (w1rms./(2*pi*delta)).^2/.055;
warning('off','all');
if(useParfor)
    parfor(ii=1:sz(2))
        % Some voxels produce a "Input to EIG must not contain NaN
        % or Inf" error in lsqnonl in. Tweaking the bounds or
        % starting estimate can fix it sometimes, but they are
        % probably junk voxels anyway, so we'll catch and skip them.
        try
            if(fitMethod=='l')
                [x, resnorm, residual, exitflag, output] = lsqnonlin(@(x) relaxMtFitFunc(x, data(:,ii), W_B, W_F, T2_B, r1(ii), s0(ii), t_m, t_s, t_r), x0, lb, ub, options); %bese j-12;
            else
                [x, resnorm, exitflag] = fminsearch(@(x) relaxMtFitFuncLs(x, data(:,ii), W_B, W_F, T2_B, r1(ii), s0(ii), t_m, t_s, t_r), x0, options);
            end
            %disp([ii x])
            if(exitflag>0)
                k(ii) = x(1);
                f(ii) = x(2);
                gof(ii) = resnorm;
            else
                gof(ii) = NaN;
            end
        catch
            % Leave the fit values at zero.
        end
    end
else
    for(ii=1:sz(2))
        try
            if(fitMethod=='l')
                [x, resnorm, residual, exitflag, output] = lsqnonlin(@(x) relaxMtFitFunc(x, data(:,ii), W_B, W_F, T2_B, r1(ii), s0(ii), t_m, t_s, t_r), x0, lb, ub, options); %bese j-12;
            else
                [x, resnorm, exitflag] = fminsearch(@(x) relaxMtFitFuncLs(x, data(:,ii), W_B, W_F, T2_B, r1(ii), s0(ii), t_m, t_s, t_r), x0, options);
            end
            if(exitflag>0)
                k(ii) = x(1);
                f(ii) = x(2);
                gof(ii) = resnorm;
            else
                gof(ii) = NaN;
            end
        catch
           % Leave the fit values at zero.
        end
    end
end
warning on;

return;
