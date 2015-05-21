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
%   fiberPointStride - fiberPointStride: if <=1, then all fiber points will be returned. If 2,
%   every 2nd point will be returned, etc. The default will try to get you
%   close to a 1mm step size.
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

