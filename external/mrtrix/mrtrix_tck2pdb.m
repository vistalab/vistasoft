function fg = mrtrix_tck2pdb(tck_file, pdb_file, fiberPointStride)
%
%    fg = mrtrix_tck2pdb(tck_file, pdb_file)
%
% Convert an mrtrix .tck tracking file to the pdb format. 
% 
%
% INPUTS
%   tck_file - string, full path to the tck file. 
%   pdb_file - string, full path to the resulting pdb file. 
% 
% Notes
%  see dtiImportFibersMrtrix.m
%
% Franco Pestilli, Ariel Rokem and Bob Dougherty Stanford University 

if notDefined('fiberPointStride')
   fiberPointStride = eye(4);
else
end

if exist(tck_file,'file')
   fg = dtiImportFibersMrtrix(tck_file, fiberPointStride);
   mtrExportFibers(fg, pdb_file);
else
    error('[%s] Aborting. Cannot find .tck file : %s .',mfilename,tck_file);
end

end

