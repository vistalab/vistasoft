function [grads, maxB,delta,Delta] = dtiGradsBuildCharmed(maxG, Delta, delta, interact)
%
% [grads, maxB] = dSimGetCharmedGrads([maxG = 50.0], [Delta=optimal value to minimize TE], [delta=Delta])
%
% For example, to save a gradient scheme for 3T2 at the Lucas center:
% [grads, maxB] = dtiGradsBuildCharmed(50);
% dlmwrite(sprintf('dwepi.%03d.grads',size(grads,2)), grads',' ');
%
% HISTORY:
% 2009.05.13 RFD & AM wrote it.
%

g = 42576.0; % gyromagnetic ratio for H in kHz/T = (cycles/millisecond)/T
nSlices = 60;

if(~exist('maxG','var') || isempty(maxG))
    maxG = 50.0; % Max gradient in mT/m
end
if(~exist('interact','var') || isempty(maxG))
    interact = 1; % Max gradient in mT/m
end

bvals = [0 714 1428 2285 3214 4286 5357 6429 7500 8571 10000]./1000;
nDirs = [1   6    7   11   13   15   17   19   21   29    31];
nReps = [16  2    2    2    2    2    2    2    2    2     2];

maxB = max(bvals);

% Sort to ensure that we have the lowest bvalue first, and then all
% remaining bvlaues in descending order. This will make the interleaving
% (below) work better at keeping high bvalue scans separated from other
% high b-value scans.
[junk,si] = sort(bvals,'descend');
si = si([end,1:end-1]);
bvals = bvals(si);
nDirs = nDirs(si);
nReps = nReps(si);

if(~exist('delta','var'))
    % DW gradient duration, in msec
    delta = []; % We'll set it below
end

if(~exist('Delta','var') || isempty(Delta))
    if(~isempty(delta))
        Delta = maxB/((2*pi*g).^2 * (maxG*1e-9).^2 * delta.^2) + delta/3;
    else
        % Find the optimal Delta for the max b-value (i.e. where Delta=delta).
        % This ugly equation is simply the solution for this equation:
        %   Delta = max(bvals)/((2*pi*g).^2 * (maxG*1e-9).^2 * delta.^2) + delta/3;
        % when we set delta=Delta and solve for Delta again.
        Delta = 2*46874999999999994^(1/3)*maxB^(1/3)/(pi^(2/3)*(g^2)^(1/3)*(maxG^2)^(1/3));
    end
end

if(isempty(delta))
    % DW gradient duration, in msec
    delta = Delta;
end

% On our GE Signa, there is ~81msec of overhead for RF, imaging grads,
% read-out, etc.
overhead = 81;
sliceTime = Delta+delta+overhead;
TR = sliceTime/1000*nSlices;
nVols = sum(nReps.*nDirs);
totalTime = TR*nVols/60;
if interact==1
fprintf('Estimated TR for %d slices = %0.2f. Total scan time for %d volumes is %0.1f minutes.\n\n',nSlices,TR,nVols,totalTime);
end;

% Now compute the Gradient amplitudes for all the b-values
G = sqrt(bvals./((2*pi*g).^2 * delta.^2 * (Delta-delta/3))) * 1e9;

ptsDir = fullfile(fileparts(which('mrDiffusion')),'preprocess','caminoPts');

n = numel(bvals);
if interact==1
figure; axis; grid on; axis equal; hold on; c = 'rgbycmk';
end;
grads = repmat(NaN,3,nVols);
availInds = [1:nVols];
for(ii=1:n)
    if(nDirs(ii)>=3)
        pts = dlmread(fullfile(ptsDir,sprintf('Elec%03d.txt',nDirs(ii))));
        pts = reshape(pts(2:end),[3 nDirs(ii)]);
    elseif(nDirs(ii)==2 || nDirs(ii)<1 || nDirs(ii)>150)
        error('No supported');
    else
        % nDirs must == 1
        pts = [1;0;0];
    end
    curGrads = G(ii)./maxG .* pts;
    curGrads = repmat(curGrads,[1 nReps(ii)]);
    % flip half the directions
    if(bvals(ii)>0)
        flipThese = rand(1,size(curGrads,2))>=0.5;
        curGrads(:,flipThese) = -curGrads(:,flipThese);
    end
    inds = floor([1:numel(availInds)/size(curGrads,2):numel(availInds)]);
    grads(:,availInds(inds)) = curGrads;
    availInds = setdiff(availInds,availInds(inds));
    if interact==1
    plot3(curGrads(1,:),curGrads(2,:),curGrads(3,:),[c(mod(ii-1,numel(c))+1) '.']);
    end;
end

%sqrt(sum(allGrads.^2))'
return;
