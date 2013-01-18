function [filename,xform] = ctrSave(ctr,filename,xform)
% Save Contrack (ctr) structure to file.
%
%  [filename,xform] = ctrSave(ctr,filename)
%
% Saves the ConTrack parameters (in the ctr structure) to a file in ASCII
% format. This file is read by ConTrack on execution.  This text file is
% normally saved relative to the dt6 directory in the parallel directory
% of fibers, ..\fibers\contrack\XXX.
%
% contrack itself is called from the dt6 file directory (p.dt6Dir)
%
% See also ctrCreate, ctrGet, ctrSet
%

% Check input parameters
if notDefined('ctr'), error(' ConTrack structure required.'); end
if (notDefined('filename'))
    filename = mrvSelectFile('w','txt',[],'ConTrack parameters filename');
    if isempty(filename), disp('User canceled'); return; end
end
if notDefined('xform'), xform = eye(4); end

% Open up the file, checking that the user sent in a good file path
fileDir = fileparts(filename);
if isempty(fileDir), fileDir=pwd; end
  
if ~isdir(fileDir), error('No directory %s',fileDir);
else fid = fopen(filename,'wt');
    if(fid == -1)
        error('Can not write ConTrack parameters file.');
    end
end

% Start the writing
fprintf(fid,'Params: %.0f\n',ctrGet(ctr,'version'));  % Should this be a version parameter
fprintf(fid,'Image Directory: %s/ \n',ctrGet(ctr,'image_directory'));
fprintf(fid,'WM/GM Mask Filename: %s\n',ctrGet(ctr,'fa_filename'));
fprintf(fid,'PDF Filename: %s\n',ctrGet(ctr,'pdf_filename'));
fprintf(fid,'ROI MASK Filename: %s\n',ctrGet(ctr,'mask_filename'));
fprintf(fid,'Desired Samples: %g\n',ctrGet(ctr,'desired_samples'));
fprintf(fid,'Max Pathway Nodes: %g\n',ctrGet(ctr,'max_nodes'));
fprintf(fid,'Min Pathway Nodes: %g\n',ctrGet(ctr,'min_nodes'));
fprintf(fid,'Step Size (mm): %g\n',ctrGet(ctr,'step_size'));
fprintf(fid,'Start Is Seed VOI: %s\n',ctrGet(ctr,'roi',1,'seed_region'));
fprintf(fid,'End Is Seed VOI: %s\n',ctrGet(ctr,'roi',2,'seed_region'));
fprintf(fid,'Save Out Spacing: %g\n',ctrGet(ctr,'save_out_spacing'));
fprintf(fid,'Threshold for WM/GM specification: %g\n',ctrGet(ctr,'fa_absorb'));
fprintf(fid,'Absorption Rate WM: %g\n',ctrGet(ctr,'abs_normal'));
fprintf(fid,'Absorption Rate NotWM: %g\n',ctrGet(ctr,'abs_penalty'));
fprintf(fid,'Local Path Segment Smoothness Standard Deviation: %g\n',ctrGet(ctr,'smooth_std'));
fprintf(fid,'Local Path Segment Angle Cutoff: %g\n',ctrGet(ctr,'angle_cutoff'));

% Can't we use num2str here?  Is it an issue for Tony's read?
fprintf(fid,'ShapeFunc Params (LinMidCl,LinWidthCl,UniformS): [ %s ]\n',getStrFromVec(ctrGet(ctr,'shape_params_vec')));

% Close up
fclose(fid);

return;

%------------------------------------------------
function str = getStrFromVec(vec)
% Shouldn't this just be num2str?
str = [];
for ii = 1:length(vec)
    str = [str num2str(vec(ii)) ', ']; %#ok<AGROW>
end
str = str(1:end-2);
return;
