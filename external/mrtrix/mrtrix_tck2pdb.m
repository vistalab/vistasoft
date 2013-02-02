function fg = mrtrix_tck2pdb(tck_file, pdb_file)
%
% function fg = mrtrix_tck2pdb(tck_file, pdb_file)
%
% Convert an mrtrix .tck tracking file to the pdb format. 
% 
%
% Parameters
% ----------
% tck_file: string, full path to the tck file. 
% pdb_file: string, full path to the resulting pdb file. 
% 
% Notes
% -----
% Uses dtiImportFibersMrtrix.

fg = dtiImportFibersMrtrix(tck_file);

mtrExportFibers(fg, pdb_file, eye(4));

