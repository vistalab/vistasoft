function [cvx_w, ATest, dSigPredict, dSigTest, rows, R2] = t_mrdArcuateXvalidate(dSig,A,rows,ndir)
% 
% function [cvx_w, ATest, dSigTest, rows, R2] = t_mrdArcuateXvalidate(dSig,A,rows,ndir)
%
% Cross-validate fiber predictions.
%
% dSig = the vector of diffusion measurements
% A    = the fiber prediction matrix
% rows = which rows to use
%
% Example:
%    t_mrdArcuateXvalidate(dSig,A,rows,ndir)
%
% See also:  t_mrdTensors, t_mrdViewFibers, dwiLoad, dtiGet/Set,
%            t_mrdFiberPredictions, t_mrdArcuatePRedictions
%
% (c) Stanford VISTA Team

% The user must either pass in the rows to fit and hold out or the number
% of directions so that we can randomly hold out rows
if exist('rows','var') && ~isempty(rows);
    rows = logical(rows);
elseif ~exist('rows','var') || isempty(rows);
    % This is a randomly chosen direction to hold out for each voxel
    outVols = ceil(rand(length(dSig)./ndir,1).*ndir);
    % Now we will make a vector that has a 1 for each row of dsig to fit
    % and a 0 for each row to hold out for cross validation
    rows = [];
    for ii = 1:length(outVols)
        tmp = ones(ndir,1);
        tmp(outVols(ii))=0;
        nextrow = length(rows)+1;
        rows(nextrow:nextrow+ndir-1) = tmp;
    end
   rows = logical(rows); 
end

% This is the data we will hold out for cross validation
tmp        = full(A);   % we're not sure if we have to make it a full before indexing
dSigTest   = dSig(~rows);
ATest      = tmp(~rows,:);

% now run the CVX code to solve the L1-minimization problem:
ATrain    = tmp(rows,:); clear tmp
n         = size(ATrain,2);
dSigTrain = dSig(rows);
fFraction = 0.2; % fraction of the weights over which weights are nromalized

l = 0;                 % Lower and upper bounds on the weights
u = 1;
cvx_solver sedumi;     % sdpt3
cvx_precision('low')  % We can handle low precision during testing.

cvx_begin              % start te cvx environment
   variable cvx_w(n)   % set the variable we are looking to fit in the cvx environment
   minimize(norm(ATrain * cvx_w - dSigTrain,1)) % minimize using L1 norm
   subject to     
     norm(cvx_w(1:n),1) <= fFraction*n;
     cvx_w >= l;
     cvx_w <= u;
cvx_end

% compute the predicted signal
dSigPredict = ATest*cvx_w;

% Amount of deviation in the data explained by the model 
% relative to the total variance in the data.
R2 = 100 * (1-sum((dSigPredict - dSigTest).^2) / sum((dSigTest-mean(dSigTest)).^2));
%R2 = corr(dSigPredict,dSigTest)^2;

