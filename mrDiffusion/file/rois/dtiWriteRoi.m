function dtiWriteRoi(roi, fileName, versionNum, coordinateSpace, xform)
%
% dtiWriteRoi(roi, fileName, [versionNum=1], [coordinateSpace='acpc'], xform)
% 
% Simply writes the ROI to disk in the specified file. The code is
% trivial, but it's nice to have everything that writes to disk go
% through one function, just in case we change the file format.
% 
% HISTORY:
% 2005.01.27 RFD: wrote it.

if(~exist('versionNum','var') | isempty(versionNum))
  versionNum = 1;
end
if(~exist('coordinateSpace','var') | isempty(coordinateSpace))
  coordinateSpace = 'acpc';
end
if(exist('xform','var') & ~isempty(xform) & (isstruct(xform) | ~all(all(xform==eye(4)))))
    roi.coords = mrAnatXformCoords(xform, roi.coords);
end
save(fileName,'roi','versionNum','coordinateSpace');
return;
