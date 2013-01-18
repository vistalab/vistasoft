function view = motionCompNestaresWithin1st(view, tgtScans, baseScan, baseFrame, smoothing);
%
% view = motionCompNestaresFull(view, <tgtScans=all>, <baseScan=1>, , <baseFrame=1>, <temporalSmoothing = 1 frame>);
%
% Call both between and within scan motion compensation, back-to-back, on
% an inplane view. Right now just a simple wrapper. 
%
% Note that these are the older, rigid-body only motion compensation tools
% based around the code originally developed by Nestares and Heeger.
%
%
% DY 09/2008 based on motionCompNestaresFull
if notDefined('view'), view = getSelectedInplane; end
if notDefined('tgtScans'), tgtScans = 1:numScans(view); end
if notDefined('baseScan'), baseScan = 1; end
if notDefined('baseFrame'), baseFrame = 1; end
if notDefined('smoothing'), smoothing = 1; end

if ~isequal(view.viewType, 'Inplane')
    myErrorDlg('Can only run motion compensation on Inplane data.');
end

% first do within scans motion compensation:
newDataType = 'MotionComp';
view = motionCompSelScan(view, newDataType, tgtScans, baseFrame, smoothing);

% then run between scans motion compensation:
view = selectDataType(view, newDataType);
newnewDataType=['MotionComp_RefScan' num2str(baseScan)];
view = betweenScanMotComp(view, newnewDataType, baseScan, tgtScans);


disp('Finished all motion compensation. Final results in MotionComp_RefScan# data type.')

return


