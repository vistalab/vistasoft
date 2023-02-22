function vw = makeFlatAnatROI(vw,name,select,color)
% vw = makeFlatAnatROI(vw,[name],[select],[color])
%
% Makes an ROI covering the entire flat map. It can be restricted to
% regions where there are data simply by setting the cothresh=0 & 
% phWindow=[0,2pi], and using restrictROI.
%
% vw: the view for the FLAT window
% name: name (string) for the ROI (default = 'new ROI')
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI (default 'b').
%
% 99.03.31 rfd
% 99.04.07 rfd: fixed it up to work as a mrLoadRet 2.0 callback

% needs image size and nSlices
mrGlobals;

if ~strcmp(vw.viewType,'Flat')
    myErrorDlg('makeFlatAnatROI is only for flat views.');
end

% Set name field
slice = viewGet(vw, 'Current Slice');
if ~exist('name','var')
  if slice == 1
     ROI.name = 'flatAnat-L';
  else
     ROI.name = 'flatAnat-R';
  end
else
  ROI.name = name;
end

% Set select and color fields
if ~exist('select','var')
  select = 1;
end
if ~exist('color','var')
  ROI.color = 'b';
else
  ROI.color = colr;
end

ROI.viewType = vw.viewType;

anat = vw.anat(:,:,slice);
[i,j] = ind2sub(size(anat), find(~isnan(anat(:))));

ROI.coords = [i';j';ones(1,length(i))*slice];

[vw,pos] = addROI(vw,ROI,select);

return;
