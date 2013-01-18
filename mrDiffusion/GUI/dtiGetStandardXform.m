function xform = dtiGetStandardXform(handles, imgXform)
%
% xform = dtiGetStandardXform(handles, [imgXform])
%
% Author: Dougherty
%
% If imgXform is passed in, the returned xfrom will be 
% standardXform * imgXform.
%
% HISTORY:
% 2003.12.01 RFD (bob@white.stanford.edu) wrote it.
%

% warning('Use dtiGet(handles,''standardXform'',imgXform)');

xform = handles.acpcXform;
if(exist('imgXform','var') & ~isempty(imgXform))
    xform = xform * imgXform;
end

return;

