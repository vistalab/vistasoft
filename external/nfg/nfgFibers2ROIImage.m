function [vol] = nfgFibers2ROIImage(fg,volExFile,roiFile)
%Converts fiber endpoints into ROI image
%
%   [vol] = nfgFibers2ROIImage(fg,volExFile,roiFile)
%   
%   Will also write out the image to roiFIle if provided.
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

if ieNotDefined('roiFile'); roiFile=[]; end

fiberLen = cellfun('size',fg.fibers,2);
fc = horzcat(fg.fibers{:});
eID = cumsum(fiberLen);
sID = [1 1+eID(1:end-1)];
coords1 = fc(:,sID);
coords2 = fc(:,eID);
vol = mtrImageFromCoords(coords1, coords2, volExFile, roiFile);

return;