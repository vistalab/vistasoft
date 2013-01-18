function [C, status] = parfileCondition(parfiles, nFrames);
%
% [C, status] = parfileCondition(parfiles, <nFrames=set by parfiles>);
%
% Estimate the condition number of an experimental paradigm
% specified by parfiles. This condition number determines
% whether or not time courses can be successfully deconvolved
% for data with this paradigm.
% 
% parfiles: cell of parfile paths.
% 
% nFrames: optional argument specifying # of frames to take from
% each parfile. If omitted, just takes max # of frames set by the
% parfiles.
%
% C: condition number, equal to sum(X' * X), where X is the
% design matrix constructed from the parfiles.
%
% status: 1 if time courses can be deconvolved, 0 if not. 
% Basically, status just tests whether C is less than 10 million.
%
%
%
% ras 02/2006. 
status = 0;

params = er_defaultParams;
params.glmHRF = 0;

% create Toeplitz matrix for deconvolution from the parfiles
S = delta_function_from_parfile(parfiles);
X = glm_deconvolution_matrix(S, -4:17);

% This part I've empirically determined from er_selxavg, but
% hope to understand soon:
% iteratively sum the matrix X' * W * X 
% (where W is a whitening matrix which we basically always
% set to the identitiy matrix, so I'm only concerned with that
% case).
nFrames = size(X, 1);
nPred = size(X, 2);
nRuns = size(X, 3);
XtX = zeros(nPred, nPred);
for i = 1:nRuns
    XtX = XtX + [X(:,:,i)' * X(:,:,i)];
end

C = cond(XtX);
status = (C < 10^7);

if status==0
    disp('Paradigm is ill-conditioned.')
end

return