function viewA = warpFromViews(viewA, viewD, sliceNum, ringScanD, wedgeScanD, coThresh)
%
%  viewA = warpFromViews(viewA, [viewD], [sliceNum], [ringScanD], [wedgeScanD], [coThresh])
%
% Author: Dougherty
% Purpose:
%    Warp the atlas in an Atlas view to fit the ring and wedge
%    data in a Data view.
%    We expect the atlas data to be bounded away from the [0,2pi] edges.
%    Then we should transform the ring and wedge data to be in the same
%    range.
% 

global dataTYPES;

% We test whether we are in an atlas view at this point
l = existDataType('Atlases',dataTYPES,0); 
typeNum = dtGetCurNum(viewA);
if ~ismember(l,typeNum), error('You must run warping from an Atlas view.'); end

ringwedge = readRingWedgeScans('Enter ATLAS ring and wedge scans, [2,1]');
ringScanA = ringwedge(1); wedgeScanA = ringwedge(2);

if(~exist('coThresh', 'var') || isempty(coThresh))
    coThresh = 0;
    % -1: the weights are simply the co values and no co thresholding is
    % applied.
    % 0:  apply a correlation threshold before using the data
end
dataViewNumber = atlasGuessDataView(viewA);

if(~exist('viewD','var'))
    prompt = {'data view #:', 'hemisphere:', ...
              'data wedge scan num:', 'data ring scan num:', ...
              'co thresh (0 for none, -1 for co-weights)'};
    default = {num2str(dataViewNumber), num2str( viewGet(viewA, 'Current Slice')), '1', '2', num2str(coThresh)};
    answer = inputdlg(prompt, 'Warp Parameters', 1, default, 'on');
    if ~isempty(answer)
        mrGlobals;
        viewD = FLAT{str2num(answer{1})};
        sliceNum = str2num(answer{2});
        wedgeScanD = str2num(answer{3});
        ringScanD = str2num(answer{4});
        coThresh = str2num(answer{5});
    else
        myErrorDlg('You need to provide some valid parameters!');
    end
end
cmap = viewA.ui.phMode.cmap(viewA.ui.phMode.numGrays+1:end,:);
% These are the retinotopy phase estimates from the data
retPhases = dataTYPES(viewA.curDataType).atlasParams(wedgeScanA).retPhases(sliceNum,:);
% We shift the wedge data to pi/2,3pi/2 using:  shiftPhases(wData,-wedgePhaseShift)
% We shift the ring data to [0,2pi] using:      shiftPhases(rData,-ringPhaseShift);
% To get them back we apply the shiftPhase with opposite sign.
wedgePhaseShift = -retPhases(3) + pi/2;
ringPhaseShift  = -retPhases(1);

% We need to test that ph is loaded for viewA and viewD at this point.
% If it is not, we get an error.

% With this move, we shift the atlas and data into the range from
% pi/2,3pi/2 for the wedge and 0,2pi for the ring.
% ph = atlasUndoPhase(dataTYPES(viewA.curDataType).atlasParams, viewA.ph);
% aWedge = ph{wedgeScanA}(:,:,sliceNum);
% aRing = ph{ringScanA}(:,:,sliceNum);

aPH = viewA.ph;
aWedge = shiftPhase(aPH{wedgeScanA}(:,:,sliceNum),-retPhases(3) + pi/2);
aRing =  shiftPhase(aPH{ringScanA}(:,:,sliceNum), -retPhases(1));

dPH = viewD.ph;
dWedge = shiftPhase(dPH{wedgeScanD}(:,:,sliceNum),-retPhases(3) + pi/2);
dRing =  shiftPhase(dPH{ringScanD}(:,:,sliceNum), -retPhases(1));

areasImg =  squeeze(viewA.co{wedgeScanA}(:,:,sliceNum));

if(coThresh==0)
    co = ones(size(aWedge));
elseif(coThresh<0)
    co = getCurData(viewD, 'co', wedgeScanA);
    co = co(:,:,sliceNum);
else
    co = getCurData(viewD, 'co', wedgeScanA);
    co = co(:,:,sliceNum);
    co = double(co>=coThresh);
end

% At this point the atlas and data representations of phase should be in
% the same range.  For fitting, we want them both in a position away from
% the boundaries, 0 and 2pi. So, we work with the wedge data in the
% [pi/2,3pi/2] range.
[u,v,M,errorTimeSeries] = warpFischer(dWedge, aWedge, dRing, aRing, areasImg, cmap, co);
wedgePh = warpUV(aWedge, u, v);
ringPh = warpUV(aRing, u, v);

% wedgePhaseShift = dataTYPES(viewA.curDataType).atlasParams(wedgeScanA).phaseShift(sliceNum);
% ringPhaseShift  = dataTYPES(viewA.curDataType).atlasParams(ringScanA).phaseShift(sliceNum);
% wedgePhaseScale = dataTYPES(viewA.curDataType).atlasParams(wedgeScanA).phaseScale(sliceNum);
% ringPhaseScale  = dataTYPES(viewA.curDataType).atlasParams(ringScanA).phaseScale(sliceNum);

% With this move, we should be putting the phases of the atlas back
% into the measured data phases.
wedgePh = shiftPhase(wedgePh,-1*wedgePhaseShift);
ringPh = shiftPhase(ringPh,-1*ringPhaseShift);

% By convention, the u deformation field goes in the wedgeScan amp field and the
% v deformation field in the ringScan amp field.
viewA.ph{wedgeScanA}(:,:,sliceNum) = wedgePh;

% It is important to use nearest neighbor interpolation on the mask image,
% which is what we store in the co field.  We don't want any new,
% non-integer values in the mask data. (BW)
viewA.co{wedgeScanA}(:,:,sliceNum) = ...
    warpUV(squeeze(viewA.co{wedgeScanA}(:,:,sliceNum)), u, v, [], [], 'nearest');
viewA.amp{wedgeScanA}(:,:,sliceNum) = u;
viewA.ph{ringScanA}(:,:,sliceNum) = ringPh;
viewA.co{ringScanA}(:,:,sliceNum) = ...
    warpUV(squeeze(viewA.co{ringScanA}(:,:,sliceNum)), u, v, [], [], 'nearest');
viewA.amp{ringScanA}(:,:,sliceNum) = v;

return;

