function roi = dtiCreateRoiFromFibers(fg,saveFlag)
% function roi = dtiRoiFromFibers(fg)
%
% This function creates an roi from the fiber group passed in by the user.
% It borrows code from dtiFiberUI. You must first load the fiber group with
% fg = dtiReadFibers('your.mat'), then pass in fg to this fucntion.
%
% HISTORY:
% 04.29.2009 LMP wrote the thing.
%
if notDefined('saveFlag'), saveFlag = 0; end

if(~exist('fg','var') || isempty(fg))
    error 'You must pass in fiber group (fg) struct!';
end

roi = dtiNewRoi([fg.name,'_fiberROI'], fg.colorRgb./255, round(horzcat(fg.fibers{:}))');

if saveFlag == 1
    dtiWriteRoi(roi, roi.name);
    disp([roi.name,' saved to ' pwd]);
end

return