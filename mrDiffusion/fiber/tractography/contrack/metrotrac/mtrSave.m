function mtrSave(mtr,filename,xform)
% Save MetroTrac (mtr) structure to file.
%
%  mtrSave(mtr,filename)
%
% Saves the MetroTrac structure to a file in ASCII format.
%
%

if notDefined('mtr'), error('No MetroTrac structure defined.'); end
if (notDefined('filename'))
    filename = pwd;
    [f,p] = uigetfile({'*.txt','MetroTrac Parameters *.txt';'*.*','all files'},'Select MetroTrac Parameters File...',filename);
    if(isnumeric(f)); disp('Cancel.'); return; end
    filename = fullfile(p,f);
    disp(filename);
end
if notDefined('xform'), xform = eye(4); end

% Open up the file
fileDir = fileparts(filename);
if ~isdir(fileDir), error('No directory %s',fileDir);
else fid = fopen(filename,'wt');
    if(fid == -1)
        error('Can not write out ConTrack parameters file.');
    end
end

fprintf(fid,'Tensor Filename: %s\n',mtrGet(mtr,'tensors_filename'));
fprintf(fid,'WM/GM Mask Filename: %s\n',mtrGet(mtr,'fa_filename'));
fprintf(fid,'PDF Filename: %s\n',mtrGet(mtr,'pdf_filename'));
fprintf(fid,'ROI MASK Filename: %s\n',mtrGet(mtr,'mask_filename'));
fprintf(fid,'Exclusion MASK Filename: %s\n',mtrGet(mtr,'Xmask_filename'));
fprintf(fid,'Require Waypoint: %s\n',mtrGet(mtr,'require_way'));
fprintf(fid,'Desired Samples: %g\n',mtrGet(mtr,'desired_samples'));
fprintf(fid,'Max Pathway Nodes: %g\n',mtrGet(mtr,'max_nodes'));
fprintf(fid,'Min Pathway Nodes: %g\n',mtrGet(mtr,'min_nodes'));
fprintf(fid,'Step Size (mm): %g\n',mtrGet(mtr,'step_size'));
[center,length] = mtrConvertRoiToBox(mtrGet(mtr,'roi',1,'coords'),xform);
% HACKY
% Place buffer around box for converting points to voxels.
length = length+2;
fprintf(fid,'Start VOI Pos (ijk): %g, %g, %g\n',center);
fprintf(fid,'Start VOI Size (ijk): %g, %g, %g\n',length);
fprintf(fid,'Start Is Seed VOI: %s\n',mtrGet(mtr,'roi',1,'seed_region'));
%fprintf(fid,'Start Valid Cortex VOI: %s\n',mtrGet(mtr,'roi',1,'valid_cortex'));
[center,length] = mtrConvertRoiToBox(mtrGet(mtr,'roi',2,'coords'),xform);
% Place buffer around box for converting points to voxels.
length = length+2;
fprintf(fid,'End VOI Pos (ijk): %g, %g, %g\n',center);
fprintf(fid,'End VOI Size (ijk): %g, %g, %g\n',length);
fprintf(fid,'End Is Seed VOI: %s\n',mtrGet(mtr,'roi',2,'seed_region'));
%fprintf(fid,'End Valid Cortex VOI: %s\n',mtrGet(mtr,'roi',2,'valid_cortex'));
fprintf(fid,'Save Out Spacing: %g\n',mtrGet(mtr,'save_out_spacing'));
fprintf(fid,'Threshold for WM/GM specification: %g\n',mtrGet(mtr,'fa_absorb'));
fprintf(fid,'Absorption Rate WM: %g\n',mtrGet(mtr,'abs_normal'));
fprintf(fid,'Absorption Rate NotWM: %g\n',mtrGet(mtr,'abs_penalty'));
fprintf(fid,'Local Path Segment Smoothness Standard Deviation: %g\n',mtrGet(mtr,'smooth_std'));
fprintf(fid,'Local Path Segment Angle Cutoff: %g\n',mtrGet(mtr,'angle_cutoff'));
fprintf(fid,'ShapeFunc Params (LinMidCl,LinWidthCl,UniformS): [ %s ]\n',getStrFromVec(mtrGet(mtr,'shape_params_vec')));


fclose(fid);

return;

%------------------------------------------------
function str = getStrFromVec(vec)
str = [];
for ii = 1:length(vec)
    str = [str num2str(vec(ii)) ', ']; %#ok<AGROW>
end
str = str(1:end-2);
return;