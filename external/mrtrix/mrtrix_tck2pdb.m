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
%
%
% Franco Pestilli and Bob Dougherty Stanford University 

if exist(tck_file,'file')
   fg = dtiImportFibersMrtrix(tck_file);
   mtrExportFibers(fg, pdb_file, eye(4));
else
    error('[%s] Aborting. Cannot find .tck file : %s .',mfilename,tck_file);
end

end

