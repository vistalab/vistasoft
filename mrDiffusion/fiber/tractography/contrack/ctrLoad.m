function ctr = ctrLoad(filename,xform)
% Load Contrack (ctr) structure to file.
%
%  ctr = ctrLoad(filename)
%
% Loads the Contrack structure to a file from ASCII format.
% I think there is a problem in how the xform is specified here.  By
% default, it seems to me that the transform is only for AC-PC space. 
%
% Probably we should be more careful or helpful or something.


if (notDefined('filename'))
    filename = mrvSelectFile('r','txt',[],'Save Contrack parameters');
    if isempty(filename), disp('User canceled'); return; end
end
if notDefined('xform'), xform = eye(4); disp('Identity xform'); end

% Open  the file, checking that the user sent in a good file path
fileDir = fileparts(filename);
if ~isdir(fileDir), error('No directory %s',fileDir);
else fid = fopen(filename,'rt');
    if(fid == -1)
        error('Can not read ConTrack parameters file.');
    end
end

% What we will return.
ctr = ctrCreate;

ctr = ctrSet(ctr, 'tensors_filename', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'fa_filename', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'pdf_filename', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'mask_filename', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'Xmask_filename', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'require_way', getStringFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'desired_samples', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'max_nodes', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'min_nodes', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'step_size', getScalarFromLine(getLine(fid)));
coords = getBoxCoordsFromFile(fid,xform);
ctr = ctrSet(ctr,'roi', coords, 1, 'coords');
ctr = ctrSet(ctr,'roi', getStringFromLine(getLine(fid)), 1, 'seed_region');

%ctr = ctrSet(ctr,'roi', getStringFromLine(getLine(fid)), 1, 'valid_cortex');
coords = getBoxCoordsFromFile(fid,xform);
ctr = ctrSet(ctr,'roi', coords, 2, 'coords');
ctr = ctrSet(ctr,'roi', getStringFromLine(getLine(fid)), 2, 'seed_region');
%ctr = ctrSet(ctr,'roi', getStringFromLine(getLine(fid)), 2, 'valid_cortex');
ctr = ctrSet(ctr, 'save_out_spacing', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'fa_absorb', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'abs_normal', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'abs_penalty', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'smooth_std', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'angle_cutoff', getScalarFromLine(getLine(fid)));
ctr = ctrSet(ctr, 'shape_params_vec', getVectorFromLine(getLine(fid)));

fclose(fid);

return;

%--------------------
function line = getLine(fid)
line = fgetl(fid); if ~ischar(line),   error('Bad file.'),   end
return;

%--------------------
function string = getStringFromLine(line)
[foo string filepart] = strread(line,'%s %s %s','delimiter', ':');
%Reconstruct filename if necessary
if( ~isempty(filepart) ), string = strcat(string{:}, ':', filepart{:});
else                      string = string{:};
end
return;

%--------------------
function scalar  = getScalarFromLine(line)
[foo str_scalar] = strread(line,'%s %s','delimiter', ':');
scalar           = strread(str_scalar{:},'%f');
return;

%--------------------
function vector = get3VectorFromLine(line)
[foo str_vector] = strread(line,'%s %s','delimiter', ':');
vector = strread(str_vector{:},'%f','delimiter',',');
return;

%--------------------
function vector = getVectorFromLine(line)
[foo str_vector] = strread(line,'%s %s','delimiter', ':');
str_vector = strread(str_vector{:},'%*c %s','delimiter',']');
vector = strread(str_vector{:},'%f','delimiter',',');
return;

%--------------------
function coords = getBoxCoordsFromFile(fid,xform)
center = get3VectorFromLine(getLine(fid));
center = center(:)';
length = get3VectorFromLine(getLine(fid));
length = length(:)';
% Just put the corners of the box into coords
% XXX HACKY
% Assuming that we are going to add to the length to convert from points to
% voxels
coords = [center - (length-2)/2; center + (length-2)/2];
% Transform coords into the given space
coords = mrAnatXformCoords(xform, coords);
return;
