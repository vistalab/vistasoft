function [ppt, op] = pptOpen(pptFile);
% For Windows machines only: Create an Active X Server object used
% for talking with PowerPoint, writing to the specified powerpoint
% presentation. Creates it if needed, otherwise opens and gets ready
% to append to it.
%
% Usage:
%  [ppt, op] = pptOpen(pptFile);
%
% pptFile: path to the powerpoint file to open.
% ppt: ActiveX Server for PowerPoint.
% op: the operation for the specific ppt file.
%
% ras, 10/2005.
if ~ispc
    warning('Sorry, pptOpen is Windows-only right now.');
    return
end

% Start an ActiveX session with PowerPoint:
ppt = actxserver('PowerPoint.Application');
ppt.Visible = 1;

if ~exist(pptFile,'file');
  % Create new presentation:
  op = invoke(ppt.Presentations,'Add');
else
  % Open existing presentation:
  op = invoke(ppt.Presentations,'Open',pptFile);
end

return