function handles = dtiRestrictToImageValueRange(handles, range, roiNum)
% Comment needed
%
% handles = dtiRestrictToImageValueRange(handles, range, [roiNum])
%
% If range is provided, the use will be prompted. The range should be
% specified in real imag value units.
%
% HISTORY:
%   2003.12.03 RFD (bob@white.stanford.edu) wrote it.
%
% Bob (c) Stanford VISTASOFT Team, 2003

if(~exist('roiNum','var') || isempty(roiNum)), roiNum = handles.curRoi; end

n        = dtiGet(handles,'bg num');
anat     = dtiGet(handles,'bg image',n);
xform    = dtiGet(handles,'bg img2acpc xform',n);
valRange = dtiGet(handles,'bg range',n);
% mmPerVoxel = dtiGet(handles,'bg mmpervox',n);
% imgName       = dtiGet(handles,'bg name',n);
% [anat,mmPerVoxel,xform,imgName,valRange] = dtiGetCurAnat(handles);

if(~exist('range','var') || isempty(range))
    range = [.5*diff(valRange) valRange(2)];
    p = 3-round(min(log10(diff(valRange)),3)); p = num2str(p);
    prompt = {sprintf(['[min max]: keep values >=min and <=max (total range: %0.' p 'f to %0.' p 'f)'],valRange)};
    defAns = {sprintf(['%0.' p 'f  %0.' p 'f'], range)};
    ans = inputdlg(prompt, 'Restrict to image value...', 1, defAns);
    if(isempty(ans)) return;
    else range = str2num(ans{1}); end
end

% Convert real image values to the 0-1 normalized values stored in the
% image array
range = (range-valRange(1))./diff(valRange);
ic = mrAnatXformCoords(inv(xform), handles.rois(roiNum).coords);
sz = size(anat);
ic = round(ic);
keep = ic(:,1)>1 & ic(:,1)<=sz(1) & ic(:,2)>1 & ic(:,2)<=sz(2) & ic(:,3)>1 & ic(:,3)<=sz(3);
ic = ic(keep,:);
handles.rois(roiNum).coords = handles.rois(roiNum).coords(keep,:);
imgIndices = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));
keepCoordInd = anat(imgIndices)>=range(1) & anat(imgIndices)<=range(2);

handles.rois(roiNum).coords = handles.rois(roiNum).coords(keepCoordInd, :);

return
