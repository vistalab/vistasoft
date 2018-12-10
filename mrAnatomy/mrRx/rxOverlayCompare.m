function h = rxOverlayCompare(rx);
%
% h = rxOverlayCompare(rx);
%
% Use the OverlayVols interface to compare
% the mrRx prescription and reference volume
% for all slices. Returns a handle to 
% the interface opened.
%
%
% ras 03/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

% build the interpolated volume
Prescription = [];
hwait = mrvWaitbar(0,'Building Interpolated Volume...');
for slice = 1:rx.rxDims(3)
    Prescription(:,:,slice) = rxInterpSlice(rx,slice);
    mrvWaitbar(slice/rx.rxDims(3));
end
close(hwait);

% get the reference volume
Reference = rx.ref;

% correct intensity if selected
hcorrect = findobj('Label','Use mrAlign Intensity Correction');
correct = isequal(get(hcorrect(end),'Checked'),'on');
if correct==1
    [Prescription Reference] = rxCorrectIntensity(Prescription,Reference);
end

% overlay
h = overlayVolumes(Prescription,Reference);

return
