function im = recomputeImage2(view,clipMode)
%
% im = recomputeImage2(view,clipMode)
%
% Recomputes the image (underlay/anat + overlay) for the
% given view, returning the image. This is different from
% recomputeImage in 3 ways:
%       1) It produces a truecolor image;
%       2) It returns the image rather than the view
%          (I do this because I'm adding the option to
%           work on mosaics of many of these images -- e.g.
%           many inplane slices or flat levels)
%       3) It doesn't take numGrays or numColors as arguments;
%          (since it's true color, they're set to 256 each).
%
%
% djh, sometime in '98
% djh, 2/2001. version 3.0 
% ras, 3/2004. An attempt to make the images true-color (3 image planes
% (R,G,B), each ranging from 0-255, to allow for a full 256-value dynamic
% range for both the anatomies and overlays). Will check that this doesn't
% critically slow down updating the screen (with modern processors, this
% seems unlikely).

% Initialize images
anatIm=[];
overlay=[];

% Get cothresh, phWindow, and mapWindow from sliders
cothresh = getCothresh(view);
phWindow = getPhWindow(view);
mapWindow = getMapWindow(view);

% although we accept numGrays and numColors for back-compatibility, now
% that it's truecolor, we'll set these directly:
% numGrays = 64;
% numColors = 64;

numGrays = 256;
numColors = 256;

% Get anatClip from sliders
anatClip = getAnatClip(view);

% Get anatomy image
anatIm = cropCurAnatSlice(view);

% Get overlay
overlay = [];
if ~strcmp(view.ui.displayMode,'anat')
  overlay = cropCurSlice(view,view.ui.displayMode);
end

% Select pixels that satisfy cothresh, phWindow, and mapWindow
pts = [];
if ~isempty(overlay)
  pts = ones(size(overlay));
  curCo=cropCurSlice(view,'co');
  curPh=cropCurSlice(view,'ph');
  curMap=cropCurSlice(view,'map');
  if ~isempty(curCo) & cothresh>0
    ptsCo = curCo > cothresh;
    pts = pts & ptsCo;
  end
  if ~isempty(curPh)
    if diff(phWindow) > 0
      ptsPh = (curPh>=phWindow(1) & curPh<=phWindow(2));
    else
      ptsPh = (curPh>=phWindow(1) | curPh<=phWindow(2));
    end
    pts = pts & ptsPh;
  end
  if strcmp(view.ui.displayMode, 'amp')
    curAmp = cropCurSlice(view, 'amp');
    mnv = min(curAmp(:));
    mxv = max(curAmp(:));
    curMap = (curAmp - mnv) ./ (mxv - mnv);
  end
  if ~isempty(curMap)
    ptsMap = (curMap>=mapWindow(1) & curMap<=mapWindow(2));
    pts = pts & ptsMap;
  end
end

% Rescale anatIm to [1:numGrays], anatClip determines the range
% of anatomy values that gets mapped to the available grayscales.
% If anatClip=[0,1] then there is no clipping and the entire
% range of anatomy values is scaled to the range of available gray
% scales.
minVal = double(min(anatIm(:)));
maxVal = double(max(anatIm(:)));
anatClipMin = min(anatClip)*(maxVal-minVal) + minVal;
anatClipMax = max(anatClip)*(maxVal-minVal) + minVal;
warning off;
anatIm = (rescale2(double(anatIm),[anatClipMin,anatClipMax],[1,numGrays]));
%keyboard

warning backtrace;

% Rescale overlay to [0 numGrays-1]
if ~isempty(overlay)
   if strcmp(clipMode,'auto')
      if ~isempty(find(pts));
         overClipMin = min(overlay(pts));
         overClipMax = max(overlay(pts));
      else
         overClipMin = min(overlay(:));
         overClipMax = max(overlay(:));
      end
   else
      overClipMin = min(clipMode);
      overClipMax = max(clipMode);
   end
   overlay=rescale2(overlay,[overClipMin overClipMax],[0 numGrays-1]);
end

% get, and threshold, the anatomical cmap:
lightRng = [0.6 0.8];
darkRng = [0.2 0.4];
thresh = 0.6;
anatCmap = gray(256);
anatCmap(anatCmap < thresh) = ...
    normalize(anatCmap(anatCmap < thresh),darkRng(1),darkRng(2));
anatCmap(anatCmap >= thresh) = ...
    normalize(anatCmap(anatCmap >= thresh),lightRng(1),lightRng(2));

% % convert into a truecolor RGB image, combining
% % the overlay with the anatomy, if necessary
% % Combine overlay with anatomy image
% im = normalize(repmat(anatIm,[1 1 3]));
%
 if ~isempty(overlay) & ~all(pts==0)
     % for truecolor, we need to get the color map
     % info directly.
     cmapname = eval(['view.ui.' view.ui.displayMode 'Mode.name']);
     cmapname = cmapname(1:end-4); % last 4 chars are 'Cmap'
     cmap = feval(cmapname,0,256);
     cmap = [anatCmap; cmap];
     im = ind2rgb(overlay,cmap);
     
%     % get a set of R,G,B columns of values for each data point in the
%     % overlay
%     vals = cmap(overlay(pts)+1,:); 
%     
%     % plug in the overlay into each R/G/B plane of the truecolor image:
%     [indx,indy] = ind2sub(size(anatIm),find(pts));
%     indz = [ones(length(indx),1); 2*ones(length(indx),1); 3*ones(length(indx),1)];
%     indx = repmat(indx,3,1);
%     indy = repmat(indy,3,1);
%     final_ind = sub2ind(size(im),indx,indy,indz);
%    im(final_ind) = vals
else
    im = ind2rgb(anatIm,anatCmap);
end

% 2003.01.10 RFD: the following is no longer necessary- the uint8 data
% can't have any NaNs! Also, it caused problems in matlab versions <6.5.
% 2003.01.23 ARW: But without it, Matlab 6.5 fills in the Nans in the flat map as white.
% Do a version check for now and replace NaNs if >=R13
if (version('-release')>=13)
    indices = find(isnan(im));
    im(indices) = 1;
end

% Finally, set the view.ui.image field
%view.ui.image = uint8(double(im)-1);
view.ui.image = im;

if isempty(overlay)
   view.ui.cbarRange = [];
else
   view.ui.cbarRange = [overClipMin overClipMax];  
end

return;

