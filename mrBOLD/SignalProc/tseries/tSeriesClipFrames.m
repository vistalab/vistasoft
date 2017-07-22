function tSeriesClipFrames(vw,scans,junkFrames,keepFrames)
%
% tSeriesClipFrames(vw,[scans,junkFrames,keepFrames]);
%
% Remove frames from tSeries for the selected data type and scans.
% This is just like the selection of junk frames and keep frames
% in mrInitRet, only you can run it on any data set.
%
% dataType: name or index of data type to use. Default is current
% data type for current inplane vw.
%
% scans: which scans to trim.
% 
% junkFrames: frames from the beginning of the tSeries to skip over.
%
% keepFrames: subsequent frames after the junk frames to keep. 
%
% If any of the last three arguments are omitted, will pop up a dialog.
%
% I wrote this to help me run corAnals on scans which were trimmed
% to an integer number of cycles, but keep an original tSeries with
% pre and post-stim baselines for GLM analyses. It just removes the
% unwanted frames from each tSeries and updates dataTYPES.
%
%
% ras, 09/2005.
if ieNotDefined('vw')  vw = getSelectedInplane; end

dataType = viewGet(vw,'curdt');

mrGlobals;

if ieNotDefined('scans') 
    scans = er_selectScans(vw);
end

if ieNotDefined('junkFrames') || ieNotDefined('keepFrames')   
    dlg(1).fieldName = 'junkFrames';
    dlg(1).style = 'edit';
    dlg(1).string = 'Skip how many frames from the start of each scan?';
    dlg(1).value = '0';
    
    dlg(2).fieldName = 'keepFrames';
    dlg(2).style = 'edit';
    dlg(2).string = 'Keep how many subsequent frames?';
    dlg(2).value = num2str(numFrames(vw, scans(1)));
    
    resp = generalDialog(dlg, 'tSeries Clip Frames');
    
    if isempty(resp), return; end
    
    junkFrames = str2num(resp.junkFrames);
    keepFrames = str2num(resp.keepFrames);
end

keep = [1:keepFrames] + junkFrames;

hwait = mrvWaitbar(0, 'Clipping Frames from tSeries...');

for scan = scans
    tSeriesFull = [];
    dimNum = 0;
    for slice = 1:viewGet(vw, 'NumSlices')
        tSeries = loadtSeries(vw, scan, slice);
        tSeries = tSeries(keep,:);
        dimNum = numel(size(tSeries));
        tSeriesFull = cat(dimNum + 1, tSeriesFull, tSeries); %Combine together
    end
    
    if dimNum == 3
        tSeriesFull = reshape(tSeriesFull,[1,2,4,3]);
    end %if
    
    savetSeries(tSeriesFull, vw, scan);

    dataTYPES(dataType).scanParams(scan).nFrames = length(keep);
    save mrSESSION dataTYPES -append;
    
    mrvWaitbar(find(scans==scan)/length(scans),hwait);
end
close(hwait);


disp('Done clipping tSeries');

return
