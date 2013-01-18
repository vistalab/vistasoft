function endPointsRoi = dtiCreateRoiFromFiberEndPoints(fg,saveFlag)
% function dtiCreateRoiFromFiberEndPoints(fiberGroup,[saveFlag])
%
% Ths fucntion creates an roi from the endpoints of a given fiber
% group passed in by the user. It borrows code from dtiFiberUI.
% You must first load the fiber group with fg = dtiReadFibers('your.mat'),
% then pass in fg to this fucntion.
%
% If saveFlag == 1 the endPointsRoi will be saved to the current directory
% with the name of the fiber group with _endPointsROI added to the name.
%
% Example:
% fg = dtiReadFibers('your.mat');
% newROI = dtiCreateRoiFromFiberEndPoints(fg);
% dtiWriteRoi(newROI,newROI.name);
%
%
% History:
%  2009.03.25 LMP Wrote it.
%

if notDefined('saveFlag'), saveFlag = 0; end

if(~exist('fg','var') || isempty(fg))
    error 'You must pass in fiber group (fg) struct!';
end

nfibers = length(fg.fibers);
fc = zeros(nfibers*2, 3);
for jj=1:nfibers
    fc((jj-1)*2+1,:) = [fg.fibers{jj}(:,1)'];
    fc((jj-1)*2+2,:) = [fg.fibers{jj}(:,end)'];
end
endPointsRoi = dtiNewRoi([fg.name '_endPointsROI'], fg.colorRgb./255, fc);

if saveFlag == 1
    dtiWriteRoi(endPointsRoi,endPointsRoi.name);
    disp([endPointsRoi.name,' saved to ' pwd]);
end
return
    

