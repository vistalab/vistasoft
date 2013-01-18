function [fg, OK] = dtiModifyFiberGroup(fg)
% Window popup to allow user to set properties of a fiber group in the UI
%
%  [fg, OK] = dtiModifyFiberGroup(fg)
%
% Fiber group name, thickness, visibility, and color can be changed.
%
% HISTORY:
%   2003.10.29 RFD (bob@white.stanford.edu) wrote it.
%
% (c) Stanford VISTA Team

if(~exist('fg','var') || isempty(fg)), fg = dtiNewFiberGroup; end

ans = inputdlg({'name:','thickness:','visible:','color:'},...
    'Fiber Group Info',1,...
    {fg.name, num2str(fg.thickness), num2str(fg.visible), num2str(fg.colorRgb)});

if(~isempty(ans))
    fg.name = ans{1};
    fg.thickness = str2num(ans{2});
    fg.visible = str2num(ans{3});
    fg.colorRgb = str2num(ans{4});
    OK = true;
else
    OK = false;
end

return;