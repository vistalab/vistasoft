function camFA(dtfit_filename, fa_filename, raw_nifti_filename)
%Calculate FA from camino tensor fits
%
%  camFA(dtfit_filename,fa_filename,raw_filename)
%
%

if 0
    %% Old Way with FSL
    
    % Assume fa_filename is given in .nii.gz format
    [pathstr, name] = fileparts(fa_filename);
    [foo1, fa_rootname] = fileparts(name);
    
    fa_img_filename = fullfile(pathstr,[fa_rootname '.img']);
    fa_hdr_filename = fullfile(pathstr,[fa_rootname '.hdr']);
    
    cmd = ['fa < ' dtfit_filename ' > ' fa_img_filename];
    display(cmd);
    system(cmd,'-echo');
    
    cmd = ['analyzeheader -initfromheader ' raw_filename ' -networkbyteorder -datatype double -nimages 1 > ' fa_hdr_filename];
    display(cmd);
    system(cmd,'-echo');
    
    % fslchfiletype can't handle if the output already exists
    if exist(fa_filename,'file')
        delete(fa_filename);
    end
    cmd = ['fslchfiletype NIFTI_GZ ' fa_hdr_filename];
    display(cmd);
    system(cmd,'-echo');
    
    cam_fix_header(fa_filename,raw_filename);

elseif 0
    %% New Way just using Matlab tools
    
    % Assume fa_filename is given in .nii.gz format
    [pathstr, name] = fileparts(fa_nifti_filename);
    [foo1, fa_rootname] = fileparts(name);
    
    fa_bdouble_filename = fullfile(pathstr,[fa_rootname '.Bdouble']);
    
    cmd = ['fa < ' dtfit_bfloat_filename ' > ' fa_bdouble_filename];
    display(cmd);
    system(cmd,'-echo');
    
    raw = niftiRead(raw_nifti_filename);

    camVoxel2Image( fa_bdouble_filename, fa_nifti_filename, 'double', ...
                    raw.qto_xyz, 1, raw.dim(1:3) );
                
    delete(fa_bdouble_filename);
    
else
    
    cmd = ['fa < ' dtfit_filename ' > ' fa_filename];
    display(cmd);
    system(cmd,'-echo');
    
end

return
