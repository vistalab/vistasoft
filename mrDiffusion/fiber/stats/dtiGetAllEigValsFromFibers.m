function [eigVal,negEig, eigVec] = dtiGetAllEigValsFromFibers(dt, fg, interpMethod)
% Return matrix of eigenvalues from all the nodes in a fiber group
%
%   [eigVal,negEig, eigVec] = dtiGetAllEigValsFromFibers(dt, fg,  [interpMethod='trilin'])
%
% dt are the diffusion tensor data read from a dt6 file
% fg is a fiber group.
% 
% This routine interpolates a tensor for each node in each fiber group.
% Interpolation is required because the fiber nodes are not necessarily
% located on the sample grid of the diffusion data.
%
% eigVal: Nx3 matrix of eigenvalues for the N-nodes.  
% negEig: Some of the eigenvalues in the original may be negative.  The
%   negative eigenvalues are set to 0, and the position of these are returned
% eigVec: The eigenvectors.  Remember that when the values are set to 0,
%   the vectors are pretty meaningless.
%
% Example:
%   chdir('..\mrDataExample\mrDiffusionData\mm20040325_new')
%   dt = dtiLoadDt6('dti06\dt6.mat');
%   fg = dtiReadFibers('fibers\LFG_CC.mat');
%   [eigVal, negEig, eigVec] = dtiGetAllEigValsFromFibers(dt, fg);
%   sum(negEig)  % This counts how many of the eigenvalues are < 0
%   
% Edit this function to see an more complex emaple (below the 'return').
%
% Dougherty, Wandell

if notDefined('dt'), error('dt data required'); end
if notDefined('fg'), error('Fiber group required'); end
if(~exist('interpMethod','var') || isempty(interpMethod))
    interpMethod = 'trilin';
end

% Get the tensor from each of the nodes in the fiber group
nodeT = dtiGetValFromFibers(dt.dt6, fg,inv(dt.xformToAcpc),'dt6',interpMethod);

% The nodeT is a cell array containing the tensor values for each of the
% fibers in the fiber group.  We group them into a single set of dt6 here
allNodesT = cat(1,nodeT{:});
[eigVec, eigVal] = dtiEig(allNodesT);

% Some spurious values ... but we should really clean these up some other
% way...more principled.
negEig = (eigVal < 0);
eigVal(negEig) = 0;

% These are some scratch code relevant to the dti statistical tests
% I don't think this code actually runs.
%
%  logEigVal = log(eigVal);
%  logFiberdt6 = dtiEigComp(eigVec,logEigVal);
%  [M, S, N] = dtiLogTensorMean(logFiberdt6);
%  [T, DISTR, df] = dtiLogTensorTest('vec', M, S, N, logDt6_ss);

return;



% To run this on a bunch of subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_y4';
[subList,subCodes,subDirs] = findSubjects(fullfile(bd,'/*'),'dti06');
fiberFile = 'fibers/IPSproject/LIPS_FOI';
for(ii=1:numel(subList))
    dt = dtiLoadDt6(subList{ii});
    fg = dtiReadFibers(fullfile(subDirs{ii},fiberFile));
    % maybe process fg to clean it up?
    [eigVal, negEig, eigVec] = dtiGetAllEigValsFromFibers(dt, fg);
    [fa,md,rd,ad] = dtiComputeFA(eigVal);
    notNan = ~isnan(fa);
    fa = fa(notNan); md = md(notNan); rd = rd(notNan); ad = ad(notNan);
end


