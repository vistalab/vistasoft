function [data wConMat] = medianGraySmooth(view,data,iter,wConMat,mask)
% dhkGraySmooth - discrete median smoothing across Gray nodes.
%
% smoothedData = medianGraySmooth(view,data,iter,wConMat,mask)
%
% Input:  view - mrVista view struct
%         data - data to be smoothed
%         iter - smoothing parameters [number_or_iterations]
%         wConMat - weighted connection matrix, to save time otherwise will
%                   be computed
%         mask - binary data to include in smoothing (default is all)
%
% 2012/06 SOD: adapted dhkGraySmooth


if ~exist('view','var') || isempty(view),
    error('Need view struct.');
else
    if ~strcmpi(view.viewType,'gray'),
        error('Need gray viewType.');
    end;
end;
if ~exist('data','var') || isempty(data),
    error('Need data');
end;
if ~exist('mask','var'), mask = true(1,size(view.coords,2)); end

% these defaults approximate a FWHM of 3mm at 1mm3 resolution
if ~exist('iter','var') || isempty(iter),
    iter = 1;
else
    iter = iter(1);
end

% sanity check
if iter==0,
    return;
end;

% compute wConMat unless given
if ~exist('wConMat','var') || isempty(wConMat),
    wConMat=dhkGrayConMat(view.nodes,view.edges,view.coords,1,mask);
end

% binary connection matrix
wConMat = wConMat>0;
allNodes = 1:size(wConMat,2);
selectedNodes = allNodes(sum(wConMat)>0 & mask);

% Get numNeighbors etc
fprintf(1,'[%s]:Median smoothing data:...',mfilename);drawnow;tic;
% data single precision for speed reasons
data = single(data);
data(~isfinite(data))=NaN;
% Smoothing iterations
for ii = 1:iter
    for n = 1:size(data,1)
        tmp = data(n,:);
        new = zeros(size(tmp),'single');
        for i2 = selectedNodes
            new(i2) = nanmedian(tmp(wConMat(:,i2)));
        end
    end
    data(n,:) = new;
end
fprintf(1,'Done[%.1fmin].\n',toc./60);drawnow;

return;
