function atlasView = atlasAffineTransform(atlasView, dataView)
%
% atlasView = atlasAffineTransform(atlasView, [dataView])
%
% 
% HISTORY:
%   2002.04.24 RFD (bob@white.stanford.edu): wrote it.
global dataTYPES;

slice = viewGet(atlasView, 'Current Slice');
wedgeScanNum = 1;
ringScanNum = 2;
% Iterations for estMotionMulti2- if you want to try a multi-res approach,
% make this a vector, with the number of iterations for each resolution 
% specified. (ie. length(iterations) is the number of resolutions to fit)
iterations = 1;
hemisphere =  viewGet(atlasView, 'Current Slice');
if(hemisphere==1)
    hemiString = 'left';
else
    hemiString = 'right';
end
if(~exist('dataView','var') | isempty(dataView))
    dataView = getDataView(atlasView);
    if(isempty(dataView))
        myErrorDlg('Sorry- there are no Data FLAT windows open.');
    end
end
atlasTypeNum = existDataType('Atlases');
aWedge = atlasView.ph{wedgeScanNum}(:,:,slice);
aRing = atlasView.ph{ringScanNum}(:,:,slice);
dWedge = dataView.ph{wedgeScanNum}(:,:,slice);
dRing = dataView.ph{ringScanNum}(:,:,slice);
% Adjust phases. We put everything into the native atlas phase because that is
% carefully chosen to minimize wrapping issues.
wedgePhaseShift = dataTYPES(atlasTypeNum).atlasParams(wedgeScanNum).phaseShift(hemisphere);
ringPhaseShift = dataTYPES(atlasTypeNum).atlasParams(ringScanNum).phaseShift(hemisphere);
wedgePhaseScale = dataTYPES(atlasTypeNum).atlasParams(wedgeScanNum).phaseScale(hemisphere);
ringPhaseScale = dataTYPES(atlasTypeNum).atlasParams(ringScanNum).phaseScale(hemisphere);
aWedge = mod((aWedge - wedgePhaseShift)/wedgePhaseScale, 2*pi);
dWedge = mod((dWedge - wedgePhaseShift)/wedgePhaseScale, 2*pi);
aRing = mod((aRing - ringPhaseShift)/ringPhaseScale, 2*pi);
dRing = mod((dRing - ringPhaseShift)/ringPhaseScale, 2*pi);
mWedge = estMotionMulti2(dWedge, aWedge, iterations, eye(3), 0, 1);
mRing = estMotionMulti2(dRing, aRing, iterations, eye(3), 0, 1);
m = mWedge*mRing;

%mRing = estMotionMulti2(dRing, warpAffine2(aRing,mWedge), [3, 3, 3], eye(3), 0, 1);
atlasView.ph{wedgeScanNum}(:,:,slice) = mod(warpAffine2(aWedge, m)*wedgePhaseScale + wedgePhaseShift, 2*pi);
atlasView.ph{ringScanNum}(:,:,slice) = mod(warpAffine2(aRing, m)*ringPhaseScale + ringPhaseShift, 2*pi);
atlasView.co{wedgeScanNum}(:,:,slice) = warpAffine2(atlasView.co{wedgeScanNum}(:,:,slice), m);
atlasView.co{ringScanNum}(:,:,slice) = warpAffine2(atlasView.co{ringScanNum}(:,:,slice), m);
refreshView(atlasView);