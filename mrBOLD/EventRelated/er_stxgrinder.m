function [stat, pSig, ces] = er_stxgrinder(test, hAvg, resVar, Ch, DOF, RM, q)
%Statistics computation routine for event-related analyses
%
% [stat, <pSig>, <ces> ] = er_stxgrinder(test, hAvg, resVar, Ch, DOF, RM, <q>)
%
% Inputs:
%   test:  Statistical 'T' or 'F', determining what type of test to run 
%
%   hAvg: Average hemodynamic responses, contained within the results of
%   er_selxavg (or betas from glm).
%
%   resVar: residual variance estimate, computed as the sum-square
%   of the model's residuals (model.residual in glm) divided
%   by the degrees of freedom
%
%   Ch: sum over scans of X' * inv(C) * X, where X is the 
%   design matrix and C is the "whitening" matrix (identity
%   matrix of size nTimePoints if not whitening). Sometimes
%   called the 'hemodynamic covariance matrix' or 'voxel independent
%   noise' in the structure produced by glm.m.
%
%   DOF: degrees of freedom
%
%   RM: restriction matrix -- see glm_restrictionMatrix
%
%   q: some sort of idealized value which gets subtracted from the rows of
%   hAvg. [See Burock and Dale, HBM, 2000]
%   
% Outputs:
%   stat: Value of the requested statistic (T or F, depending on the
%         test).
%   pSig: p-value associated with the value stat, the associated
%         degrees of fredom of the model, and the selected probability
%         distribution function (T or F).
%   ces:  contrast effect size, as a difference of betas weighted
%         by the restriction matrix.
%
%
% $Id: er_stxgrinder.m,v 1.13 2007/04/03 05:11:56 brian Exp $
% 10/1/03 ras: copied from fmri_stxgrinder, currently unmodified, just a
% local version for mrLoadRet, to remove dependencies on the FS-FAST
% toolbox.

if (nargin < 6)
    error(['USAGE: [stat, pSig, ces] = ' ...
           'er_stxgrinder(test, hAvg, resVar, Ch, DOF, RM , <q>)']);
end

if (size(RM,2) ~= size(hAvg,3))
    fprintf('ERROR: dimension mismatch between the contrast matrix\n');
    fprintf('and the input averages. This may have happened if \n');
    fprintf('you redefined an analysis without redefining the \n');
    fprintf('contrast. Try re-running er_mkcontrast.\n');
    return;
end

%%%% -------  Determine the test Type ------------ %%%%%%
if (strncmp('T',upper(test),1)),     TestId = 0; % t-test
elseif (strncmp('F',upper(test),1)), TestId = 1; % F-test
else  error('test Type %s is unknown',test);
end

%%% -- get the dimensions --- %%%
nRows = size(hAvg,1);
nCols = size(hAvg,2);
nT    = size(hAvg,3);
nV = nRows * nCols;

%% ---- Subtract the Ideal, if needed ----- %%%%%
if ( nargin == 6 )
    h = hAvg;
else
    if (size(q,1) ~= size(hAvg,3))
        error('hAvg and q must have the same number of rows');
    end
    tmp = reshape(repmat(q, [nV 1]), [nRows nCols nT]);
    h = hAvg - tmp;
    clear tmp;
end

% Voxels with exactly 0 variance are probably not real data.
% Set the variance to infinity, so no false positives here.
ind0 = find(resVar==0);
l0 = length(ind0);
% fprintf(1,'  nVoxels with resVar=0: %3d\n',l0);
if (l0 == numel(resVar))
    fprintf(1,'INFO: All voxels are zero\n');
    if (TestId == 0)
        sz = [nRows nCols size(RM, 1)];
    else
        sz = [nRows nCols 1];
    end
    pSig = ones(sz);
    stat = zeros(sz);
    ces =  zeros(sz);
    return;
end
if (l0 ~= 0)
    % ras 01/07: set it infinite instead ... not real data
    resVar(ind0) = inf;
end


%% ----- reshape for easier processing ----- %%%%%
h     = reshape(h, [nV nT])'; %'
resVar = reshape(resVar, [nV 1])'; %'

%% ---- Compute inv of DOF/Desgin covariance mtx --- %%%%
RChRt   = RM * Ch * RM'; %'
RChRt(RChRt==0) = .0000000000001;

% Compute contrast effect size %
ces = RM*h;
nces = size(ces,1);
ces = reshape(ces',[nRows nCols nces]);

%% --- Perform Tests --- 
if (TestId == 0) % t-test
    
    dRChRt = diag(RChRt);
    stat = (RM * h) ./ sqrt(dRChRt * resVar);
    
    % dof>300 --> normal approx 
    pSig = er_ttest(DOF, stat(:), 300); 
    pSig = reshape(pSig, size(stat));
    
else % F-test
    if (strcmp('FM',upper(test))) 
        dRChRt = diag(RChRt);
        stat = (RM * h).^2 ./ (dRChRt * resVar);
        J = 1;
    else
        RvvR = RM' * inv(RChRt) * RM; %'
        [J Nh] =  size(RM); % Rows of RM %
        if (Nh==1)
            stat =  (((h' * RvvR)' .*h) ./ resVar)/J;
        else
            stat =  ((sum((h' * RvvR)' .* h)) ./ resVar)/J;
        end
    end
    
    pSig = er_ftest(J, DOF, reshape1d(stat), 1000); % 1500 = maxdof2
    pSig = reshape(pSig, size(stat));
end

%% Reshape into image dimensions %%
stat = reshape(stat', [nRows nCols size(stat,1)]); %'
pSig = reshape(pSig', [nRows nCols size(pSig,1)]); %'


return;
