function [m, hdl] = niftiMontage(imVol, varargin)
% Show a montage of the volume data in imVol
%
%  [montage, hdl] = niftiMontage(imVol, varargin)
%
% imVol:  Nifti data
% Parameters
%    imVol     - Either a 3D volume or a nifti file name
%    slices    - Which slices to display
%    cmap      - Display color map
%    crop      - How to crop the imvol
%           imVol = imVol(crop(1,1):crop(1,2),:,:);
%           imVol = imVol(:,crop(2,1):crop(2,2),:);
%    numCols   - Number of columns in the montage
%    hdl       - Handle to figure window
%    flip      - 'none', 'axial'
%
% Example:
%  t1    = niftiRead('t1.nii.gz');
%  imVol = t1.data;       % that is --> : [226x271x226 int16]
%  niftiMontage(imVol);
%
% flip options are 
%
% (BW) Vistasoft Team, 2016 

%% Handle the Inputs
p = inputParser;
p.KeepUnmatched=true;
vFunc = @(x)(isnumeric(imVol) || exist(imVol,'file'));
p.addRequired('imVol',vFunc);

p.addParameter('slices',[],@isnumeric);
p.addParameter('cmap',gray(256),@ismatrix);
p.addParameter('crop',[],@isnumeric);
p.addParameter('numCols',[],@isnumeric);
p.addParameter('hdl',[],@isgraphics);
p.addParameter('flip','none',@ischar);   % None or axial

p.parse(imVol,varargin{:});
slices  = p.Results.slices;
crop    = p.Results.crop;
cmap    = p.Results.cmap;
numCols = p.Results.numCols;
hdl     = p.Results.hdl;
flip    = p.Results.flip;

% If a file was passed.  Read it.
if ischar(imVol)
    ni = niftiRead(imVol);
    imVol = ni.data;
end

if ~isempty(crop)
    imVol = imVol(crop(1,1):crop(1,2),:,:);
    imVol = imVol(:,crop(2,1):crop(2,2),:);
end

if isempty(hdl),     hdl = mrvNewGraphWin;
else                 hdl = figure(hdl);
end

if(strcmpi(flip(1),'a'))
    imVol = flip(permute(imVol,[2 1 3 4]),1);
end


%% Make the montage
colormap(cmap);
m = makeMontage(imVol,slices,[],numCols);
imagesc(m);
axis image; colorbar;

% Attach the montage to the figure
uData.m = m;
set(gca,'userdata',uData);

end
