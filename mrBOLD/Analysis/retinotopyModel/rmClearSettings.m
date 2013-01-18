function view = rmClearSettings(view);
% rmClearSettings - clear all model and related parameter definitions
%
% view = rmClearSettings(view);
%

% 2006/06 SOD: wrote it.

% simple clearing
view = viewSet(view,'rmfile',[]);
view = viewSet(view,'rmmodel',[]);
view = viewSet(view,'rmparams',[]);

return;

