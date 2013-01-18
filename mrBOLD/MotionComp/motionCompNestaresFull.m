function vw = motionCompNestaresFull(vw, tgtScans, baseScan, baseFrame, smoothing, keepbaseScan)
%
% vw = motionCompNestaresFull(vw, <tgtScans=all>, <baseScan=1>, , <baseFrame=1>, <temporalSmoothing = 1 frame>, <keepbaseScan = 0>);
%
% Call both between and within scan motion compensation, back-to-back, on
% an inplane view. Right now just a simple wrapper. 
%
% Note that these are the older, rigid-body only motion compensation tools
% based around the code originally developed by Nestares and Heeger.
%
%
% ras, 04/2006.
% remus, 03/09 added check for overwriting datatype
% hh, 09/10 -- added new parameter - keepbaseScan. If true,
%              all frames are coregistered to baseFrame of baseScan, to
%              avoid sequential steps of between- and then within-scan
%              motion compensation.

if notDefined('vw'),            vw = getSelectedInplane; end
if notDefined('tgtScans'),      tgtScans = 1:viewGet(vw, 'numScans'); end
if notDefined('baseScan'),      baseScan = 1; end
if notDefined('baseFrame'),     baseFrame = 1; end
if notDefined('smoothing'),     smoothing = 1; end
if notDefined('keepbaseScan'),  keepbaseScan = false; end

if ~isequal(vw.viewType, 'Inplane')
    myErrorDlg('Can only run motion compensation on Inplane data.');
end

% first run between scans motion compensation:
bwScansDataType = dataTypeOverwriteCheck('BwScansMotionComp');

vw = betweenScanMotComp(vw, bwScansDataType, baseScan, tgtScans);
vw = viewSet(vw, 'curdt', bwScansDataType);

% now do within scans motion compensation:
if keepbaseScan == false,
    baseScan = [];
    tgtDT = dataTypeOverwriteCheck('MotionComp');
elseif keepbaseScan == true
    tgtDT = dataTypeOverwriteCheck('MotionCompAllFrames');
end

vw = motionCompSelScan(vw, tgtDT, tgtScans, baseFrame, smoothing, baseScan);

disp('Finished all motion compensation. Final results in MotionComp data type.')

return


