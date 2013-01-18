function [data wConMat] = dhkGraySmooth(view,data,iterlambda,wConMat,mask)
% dhkGraySmooth - discrete heat kernel smoothing across Gray nodes.
%
% smoothedData = dhkGraySmooth(view,data,iterlambda,wConMat,mask)
%
% Input:  view - mrVista view struct
%         data - data to be smoothed
%         iterlambda - smoothing parameters [number_or_iterations sigma]
%         wConMat - weighted connection matrix, to save time otherwise will
%                   be computed
%         mask - binary data to include in smoothing (default is all)
%
% 2008/02 SOD: adapted from Moo K. Chung's code
% (http://www.stat.wisc.edu/softwares/hk/hk.html)

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
if ~exist('mask','var'), mask = []; end

% these defaults approximate a FWHM of 3mm at 1mm3 resolution
if ~exist('iterlambda','var') || isempty(iterlambda),
    iter = 9;
    lambda = .5;
else
    iter = iterlambda(1);
    lambda = iterlambda(2);
end;

% sanity check
if iter==0 || lambda==0,
    return;
end;

% compute wConMat unless given
if ~exist('wConMat','var') || isempty(wConMat),
    wConMat=dhkGrayConMat(view.nodes,view.edges,view.coords,lambda,mask);
end

% Get numNeighbors etc
if iter > 1,
    fprintf(1,'[%s]:Smoothing data:...',mfilename);drawnow;tic;
end
% data must be double and contain finite numbers
data = double(data);
data(~isfinite(data))=0;
% Smoothing iterations
for n = 1:size(data,1)
    tmp = data(n,:);
    for ii = 1:iter
        tmp = tmp*wConMat;
    end
    data(n,:) = tmp;
end
if iter > 1,
    fprintf(1,'Done[%.1fmin].\n',toc./60);drawnow;
end
return;
