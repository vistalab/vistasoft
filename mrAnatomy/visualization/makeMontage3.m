function [m,figNum, numColsRows] = makeMontage3(varargin)
%
% [m,figNum, numColsRows] = makeMontage3(r, g, b, slices,[mmPerPix],[upsampleFactor=0],[sliceLabels],[numAcross],[figNum],[backColor])
% 
% Or, you can put r, g, and b into one XxYxZx3 array.
%
% [mHires,figNum] = makeMontage3(rgb, slices, ...)
%
% Purpose: Calls makeMontage 3 times to build a montage of RGB
% images. You pass in the red (r), green (g) and blue (b) planes
% separately. This routine will also add a scale bar, if you tell
% it the mmPerVoxel for the sliced dimension (the third). It will
% also super-sample the resulting montage if upSapleFactor is >0.
%
%   
% Example:
%
% HISTORY:
% 2002.??.?? RFD wrote it.

if(nargin==1 | ndims(varargin{2})~=3)
  indOff = 2;
  if(size(varargin{1},4)>1)
    r=varargin{1}(:,:,:,1); g=varargin{1}(:,:,:,2); b=varargin{1}(:,:,:,3);
  else
    r=varargin{1}(:,:,:,1); g=r; b=r;
  end
else
  indOff = 4;
  r=varargin{1}; g=varargin{2}; b=varargin{3};
end
if(length(varargin)<indOff | isempty(varargin{indOff}))
  slices = [1:size(r,3)]; 
else
  slices = varargin{indOff};
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  mmPerPix = []; 
else
  mmPerPix = varargin{indOff};
  if(numel(mmPerPix)>1) mmPerPix = mmPerPix(1); end
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  upsampleFactor = 0; 
else
  upsampleFactor = varargin{indOff};
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  sliceLabels = {}; 
else
  sliceLabels = varargin{indOff};
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  numAcross = ceil(sqrt(length(slices)));
else
  numAcross = min(varargin{indOff},length(slices));
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  figNum = figure;
else
  figNum = varargin{indOff};
end
indOff = indOff+1;
if(length(varargin)<indOff | isempty(varargin{indOff}))
  backColor = [0 0 0];
else
  backColor = varargin{indOff};
end
cbarThick = 1;

numDown = ceil(length(slices)/numAcross);
  
% m(:,:,1) = makeMontage(abs(flipdim(permute(r,[3,1,2]),1)),slices,[],numAcross);
% m(:,:,2) = makeMontage(abs(flipdim(permute(g,[3,1,2]),1)),slices,[],numAcross);
% m(:,:,3) = makeMontage(abs(flipdim(permute(b,[3,1,2]),1)),slices,[],numAcross);
m(:,:,1) = makeMontage(r,slices,[],numAcross,backColor(1));
m(:,:,2) = makeMontage(g,slices,[],numAcross,backColor(2));
m(:,:,3) = makeMontage(b,slices,[],numAcross,backColor(3));

m = double(m);
if(upsampleFactor>0)
  m2(:,:,1) = upSample(m(:,:,1), upsampleFactor);
  m2(:,:,2) = upSample(m(:,:,2), upsampleFactor);
  m2(:,:,3) = upSample(m(:,:,3), upsampleFactor);
  m = m2;
end

if(strcmp(class(r),'uint8')),  
  maxVal = 255;
  sbarColor = 255-backColor;
else   
  maxVal = 1.0;
  if(mean(m(:))>maxVal)
    imMax = max(m(:));
    m = m./imMax;
    sbarColor = imMax-backColor;
  else
    sbarColor = 1-backColor;
  end
end

m(m<0) = 0;
m(m>maxVal) = maxVal;
if(~isempty(mmPerPix))
  cmBarLen = round(1/mmPerPix * 10 * 2^upsampleFactor);
  %% ERROR HERE because end-cmBarlen-5 may not be valid -- BW
  for(ii=1:3)
    for(kk=1:cbarThick)
      m(end-kk, end-cmBarLen-5:end-5,ii) = sbarColor(ii);
    end
  end
end

% preserve the input class (eg. uint8, double)
if(isinteger(r)) m = round(m);
elseif(islogical(r)) m = m>0.5; end
eval(['m=' class(r) '(m);']);

numColsRows = [numAcross numDown size(m,2) size(m,1)];
if(figNum>0), 
  figure(figNum);
  if(exist('imshow')==2 && datenum(version('-date'))>=datenum('2008-01-01') && usejava('jvm'))
    iptsetpref('ImshowBorder','tight')
    imshow(m);
  else
    image(m); axis equal; axis off;
    set(gca,'Position',[0,0,1,1]);
  end
  if(~isempty(sliceLabels))
    mrUtilLabelMontage(sliceLabels, numColsRows, figNum, gca);
  end
end
if(nargout==0)
  clear m;
end
return
