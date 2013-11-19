function vtk_fname = vtk_fromClass(in_fname, out_fname)

% function vtk_fname = vtk_fromClass(in_fname, [out_fname])
%
% Convert a mrGray .class file into VTK format
% 
%  Parameters
%  ----------
%  in_fname : str
%     Full path to a .class file 
%  out_fname : str (optional)
%     Full path to a vtk output file.
%
%  Returns
%  -------
%  vtk_fname : str
%     Full path to the output file
% 
%  Notes
%  ------
%  The specification of the VTK file format is take from here: 
%  http://wideman-one.com/gw/brain/fs/surfacefileformats.htm
% 
%  Example
%  -------
%  fName = '/biac4/wandell/biac2/wandell2/data/dti/dti_y1_old/at040918/left/20070209/leftWhole.class'
%  vtk_fromClass(fName);

if(~exist('out_fname','var')|isempty(in_fname))
    % Put the output file in the same location with the right extension: 
    vtk_fname = [in_fname(1:end-5), 'vtk']; 
else
    vtk_fname = out_fname
end
    
msh = meshBuildFromClass(in_fname);
vv = msh.vertices; 
tt = msh.triangles; 

fid = fopen(vtk_fname, 'w'); 

fprintf(fid, '# vtk DataFile Version 1.0\n');
fprintf(fid, 'vtk output\nASCII\nDATASET POLYDATA\nPOINTS %d float\n', size(vv, 2));
for vidx = 1:size(vv, 2)
    fprintf(fid, '%f %f %f\n', vv(1, vidx), vv(2, vidx), vv(3, vidx)); 
end
fprintf(fid, 'POLYGONS %d %d\n', size(tt, 2), size(tt, 2)*4); 


for tidx = 1:size(vv, 2)
    fprintf(fid, '%d %d %d %d\n', 3, tt(1, tidx), tt(2, tidx), tt(3, tidx)); 
end

fclose(fid); 






