function fg = dtiXformFibersToMrVista(handles, fgNum, scale)
%
% fg = dtiXformFibersToMrVista(handles, [fiberGroupNum], [scale])
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert the specified
% fiber group (ac-pc coords) to mrVista vAnatomy coords.
%
% HISTORY:
% 2004.05.03 RFD (bob@white.stanford.edu) wrote it.

if(~exist('fgNum','var') | isempty(fgNum))
    fgNum = handles.curFiberGroup;
end
if(~exist('scale','var') | isempty(scale))
    scale = [1 1 1];
end
if(length(scale(:))<3)
    scale = repmat(scale(1),1,3);
end

fg = handles.fiberGroups(fgNum);
xform = diag([scale 1])*inv(handles.xformVAnatToAcpc);
fg = dtiXformFiberCoords(fg, xform);
if(~isempty(fg.seeds))
  fg.seeds = mrAnatXformCoords(xform, fg.seeds);
end
return;
