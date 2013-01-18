function h = dtiImportFibers(h, filename, xform)
%
% handles = dtiImportFibers(handles, filename)
%
% Imports non-mrDiffusion fiber/path file formats. Currently supports: 
% 
% 1. MetroTrac (*.pdb) format
% 2. Camino Raw (*.Bfloat) format
%
% 
% HISTORY:
% 2006.08.17 RFD: wrote it.
%

fg = mtrImportFibers(filename, xform);
if ~isempty(fg)
    h = dtiAddFG(fg, h);
end
return;



