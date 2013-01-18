function functionals2mrGray(volumeView, coordMask)
% 
% functionals2mrGray(volumeView, [coordMask])
% 
% AUTHOR:  S. Chial
% DATE:  02.05.99
% PURPOSE:
%   Writes out the functional data currently on display in the
%   volume window into an output file that can be read in by
%   mrGray (and mrUnfold) as an overlay file.
%
% volumeView: structure that contains all the information
% related to the volume functional data and user interface.
%
% sjc, 02/05/99
% rfd, 04/20/99 replaced the call to the now obsolete 
%      "getOverlayClip" with a call to "getMapWindow".
% bw/hab 08/09/99
%      Introduced a subtraction of 1 from outLocs.  mrGray
%      locations run from [0 to n-1] and mrLoadRet run from [1 n].
%      This follows the change in readGrayGraph.  We abstracted
%      the conversion from mrLoadRet into mrGray with a new routine,
%      mrLoadRet2mrGray. 
% rfd 10/15/99
%      Fixed a minor bug that produced bad cmap indices for some
%      clip ranges.  Basically, we just have to clip cmapIdx after we scale it.
% bw  01.16.01
%       Updated for mrLoadRet-2.5
%
% rfd 2002.08.08 added optional coordMask and updated to mrLoadRet-3
% bw  2003.08.28 added persistent recentDir, handled case of cancel on uiputfile

if(~exist('coordMask','var'))
    coordMask = [];
end
persistent recentDir      % Most recently visited directory

% Figure out which scan is being viewed.
%
scanNum = getCurScan(volumeView);

% Find the data that is above the correlation threshold
% and within the phase window.
%
coThreshold = getCothresh(volumeView);
validCoIdx = find(volumeView.co{scanNum} >= coThreshold);

phaseWindow = getPhWindow(volumeView);
validPhIdx = find((volumeView.ph{scanNum} >= phaseWindow(1)) & ...
    (volumeView.ph{scanNum} <= phaseWindow(2)));

validDataIdx = intersect(validCoIdx,validPhIdx);

% Extract the data being displayed and the corresponding locations
%
cmd = ['validData = volumeView.' volumeView.ui.displayMode '{scanNum}(validDataIdx);'];
eval(cmd); 
outLocs = volumeView.coords(:,validDataIdx);
if(~isempty(coordMask))
    [outLocs, keepThese] = intersectCols(outLocs, coordMask);
else
    keepThese = [];
end

% Take mrLoadRet-2.0 locations (here outLocs) and convert them to
% mrGray locations.
% 
outLocs = mrLoadRet2mrGray(outLocs);
% 
% This is now done in mrLoadRet2mrGray:
%    outLocs = [outLocs(2,:); outLocs(1,:); outLocs(3,:)];

% Get the colormap for the data, convert it from having
% a range of 0 to 1 to a range of 0 to 255.
%
modeStr=['volumeView.ui.',volumeView.ui.displayMode,'Mode'];
mode = eval(modeStr);
cmap = round(255*mode.cmap);
numGrays = mode.numGrays;
numColors = mode.numColors;
clipMode = mode.clipMode;

% Only keep the part of the colormap that is color
%
cmap = cmap([numGrays+1:numGrays+numColors],:);

% Map the data to a color, clipping the colormap appropriately
%
overlayClip = getMapWindow(volumeView);
if ~isempty(validData)
    if strcmp(clipMode,'auto')
        minVal = min(validData);
        maxVal = max(validData);
        overClipMin = min(overlayClip)*(maxVal-minVal) + minVal;
        overClipMax = max(overlayClip)*(maxVal-minVal) + minVal;
    else
        overClipMin = min(clipMode);
        overClipMax = max(clipMode);
    end
    cmapIdx = round(scale_im(validData,1,numColors,overClipMin,overClipMax));
    % RFD: we need to clip, in case there are values above overClipMax or
    % under overClipMin.
    cmapIdx = round(clip(cmapIdx,1,numColors));
end
if(~isempty(keepThese))
    cmapIdx = cmapIdx(keepThese);
end

% Prompt user for a file name to save the data under
%
% This part of the routine should probably be a call to the new routine:
%
%    writeMrGray([outLocs; cmapIdx(:)'],cmap) 
%
curDir = pwd;
if ~isempty(recentDir)
    if(exist(recentDir,'dir')) chdir(recentDir); end
else
    anatDir = getAnatomyPath([]); 
    if(exist(anatDir,'dir')) chdir(anatDir); end;
end

[f p] = uiputfile('*.*','Save mrGray overlay file...');
if isequal(f,0) | isequal(p,0)
    return;
else
    chdir(curDir);
    filename = fullfile(p,f);
end

if ~isempty(filename)
    recentDir = p;  % Save the most recently visited directory.
    
    fid = fopen(filename,'w');
    
    % Write out the number of colors
    fprintf(fid,'%d\n',numColors);
    
    % Write out the colormap [R,G,B]
    fprintf(fid,'%d %d %d\n', cmap');
    
    % Write out the location and index into the colormap for
    % each data point.
    fprintf(fid,'%d %d %d %d\n', [outLocs; cmapIdx(:)']);
    
    fclose(fid);
    fprintf('Finished saving functional data overlay.\n');
end

return;
