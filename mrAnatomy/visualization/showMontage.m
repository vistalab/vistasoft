function [figH,m,cbH] = showMontage(imVol, slices, cmap, crop, numCols, figNum, flip)
% Show a montage of the volume data in imVol
%
% [figH,m,cbH] = showMontage(imVol, [slices=[]], [cmap=gray(256)], [crop=[]], [numCols=[]], figNum=figure, [flip='none'])
%
% Example:
%  t1    = niftiRead('t1.nii.gz');
%  imVol = t1.data; % that is --> : [226x271x226 int16]
%
% flip options are 'none', 'axial'
%
% HISTORY:
% 2007.02.22 RFD wrote it.
%
% Bob (c) VISTASOFT Team
% 

%% Handle the Inputs

% If a file was passed in then we try to read it with niftiRead
if ~isnumeric(imVol) && exist(imVol,'file')
    try
        ni = niftiRead(imVol);
        imVol = ni.data;
    catch
        warning('A file was passed in, but that file does not appear to be a a file we can read.');
        figH = [];
        m    = [];
        cbH  = [];
        return
    end
    
end

if(~exist('slices','var') || isempty(slices))
  slices = [];
end

if(~exist('cmap','var') || isempty(cmap))
  cmap = gray(256);
end

if(exist('crop','var') && ~isempty(crop))
    % newSz = [diff(crop')+1 size(imVol,3)];
    imVol = imVol(crop(1,1):crop(1,2),:,:);
    imVol = imVol(:,crop(2,1):crop(2,2),:);
end

if(~exist('numCols','var')), numCols = []; end

if(~exist('figNum','var'))
    if exist('mrvNewGraphWin','file')
        figH = mrvNewGraphWin;
    else
        figH = figure;
    end
else
    figH = figure(figNum);
end

if(~exist('flip','var') || isempty(flip))
    flip = 'none';
end

if(strcmpi(flip(1),'a'))
    imVol = flip(permute(imVol,[2 1 3 4]),1);
end


%% Make the montage

colormap(cmap);
m = makeMontage(imVol,slices,[],numCols);
imagesc(m);
axis image;
cbH = colorbar;

if(nargout<2),   clear m;    end
if(nargout<1),   clear figH; end

return;
