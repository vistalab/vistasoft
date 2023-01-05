function fg = mtrPdb2to3(fgName)
% Convert PDB 2 format to P3
%
%   fg = mtrPdb2to3([fgName])
%
% The fibers in the PDB2 file, fgName, are written to a new file in the
% PDB3 format.  The output file has the same name with V3 appended to it.
%
% Examples
%  fg = mtrPdb2to3;
%
% Stanford VISTA Team, 2011

if notDefined('fgName')
    fgName = mrvSelectFile('r','pdb','Select PDB 2 file');
end

[p,n,e] = fileparts(fgName);
fgNameV3 = fullfile(p,[sprintf('%s-V3',n),e]);
if ~exist(fgNameV3,'file')
    fg = mtrImportFibers(fgName); 
    mtrExportFibers(fg, fgNameV3);
    fprintf('Saved PDB 3 file %s\n',fgNameV3)
else
    fprintf('Aborting. PDB V3 file already exists.');
end

return