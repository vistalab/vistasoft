function [t nt dcid] = rmReconMakeTrends(params)
% rmMakeTrends - make trends to add to GLM fit
%
% [t nt dcid] = rmMakeTrends(params);
%
% params is a parameters (see rmReconParams).
%
% number of trends is determined by params.analysis.nDCT:
% cos([0:0.5:nDCT]).
%
% 2006/02 SOD: wrote original version (rmMakeTrends).
% 2010/01  MB: wrote rmRecon specific version (just for convenience).

% preparation
tf = [params.stim(:).nFrames]./[params.stim(:).nUniqueRep];
ndct   = [params.stim(:).nDCT].*2+1;
t      = zeros(sum(tf),max(sum(ndct),1));
start1 = [0 cumsum(tf)];
start2 = [0 cumsum(ndct)];

% make them seperatly for every scan
dcid= zeros(1,numel(params.stim));
for n = 1:numel(params.stim),
    % stimulus length 
    tc = linspace(0,2*pi,tf(n))';

    % trends for one scan
    t(start1(n)+1:start1(n+1),start2(n)+1:start2(n+1)) = cos(tc*(0:0.5:params.stim(n).nDCT));
    
    % keep track of dc components
    dcid(n) = start2(n)+1;
end

% number of trends
nt = size(t,2);

return;