function dtiWriteFiberGroup(fg, fileName, versionNum, coordinateSpace, xform)
% Writes the fiber group to filename.
%
% dtiWriteFiberGroup(fg, fileName, versionNum, coordinateSpace, [xform])
% 
% Explanation of xform and coordinate space and versionNum needed here.
%
% HISTORY:
% 2005.01.14 RFD: wrote it.

if(exist('xform','var') && ~isempty(xform) && (isstruct(xform) || ~all(all(xform==eye(4)))))
    fg = dtiXformFiberCoords(fg, xform);
end
if(~exist('coordinateSpace','var') || isempty(coordinateSpace))
  coordinateSpace = 'acpc';
end
if(~exist('versionNum','var') || isempty(versionNum))
  versionNum = 1.0;
end
    
save(fileName,'fg','versionNum','coordinateSpace','-v7.3');

return;
