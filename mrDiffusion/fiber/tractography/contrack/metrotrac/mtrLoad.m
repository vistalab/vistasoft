function mtr = mtrLoad(filename,xform)
% Load MetroTrac (mtr) structure to file.
%
%  mtr = mtrLoad(filename)
%
% Loads the MetroTrac structure to a file from ASCII format.
%
%

mtr = mtrCreate;

if ieNotDefined('xform'), error('No xform defined.'); end

fid = fopen(filename,'r');
if(fid == -1); error('Can not open MetroTrac options file'); end

mtr = mtrSet(mtr, 'tensors_filename', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'fa_filename', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'pdf_filename', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'mask_filename', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'Xmask_filename', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'require_way', getStringFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'desired_samples', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'max_nodes', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'min_nodes', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'step_size', getScalarFromLine(getLine(fid)));
coords = getBoxCoordsFromFile(fid,xform);
mtr = mtrSet(mtr,'roi', coords, 1, 'coords');
mtr = mtrSet(mtr,'roi', getStringFromLine(getLine(fid)), 1, 'seed_region');
%mtr = mtrSet(mtr,'roi', getStringFromLine(getLine(fid)), 1, 'valid_cortex');
coords = getBoxCoordsFromFile(fid,xform);
mtr = mtrSet(mtr,'roi', coords, 2, 'coords');
mtr = mtrSet(mtr,'roi', getStringFromLine(getLine(fid)), 2, 'seed_region');
%mtr = mtrSet(mtr,'roi', getStringFromLine(getLine(fid)), 2, 'valid_cortex');
mtr = mtrSet(mtr, 'save_out_spacing', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'fa_absorb', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'abs_normal', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'abs_penalty', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'smooth_std', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'angle_cutoff', getScalarFromLine(getLine(fid)));
mtr = mtrSet(mtr, 'shape_params_vec', getVectorFromLine(getLine(fid)));

fclose(fid);

return;

function line = getLine(fid)
line = fgetl(fid); if ~ischar(line),   error('Bad file.'),   end
return;

function string = getStringFromLine(line)
[foo string filepart] = strread(line,'%s %s %s','delimiter', ':');
%Reconstruct filename if necessary
if( ~isempty(filepart) ) 
    string = strcat(string{:}, ':', filepart{:});
else
    string = string{:};
end
return;

function scalar = getScalarFromLine(line)
[foo str_scalar] = strread(line,'%s %s','delimiter', ':');
scalar = strread(str_scalar{:},'%f');
return;

function vector = get3VectorFromLine(line)
[foo str_vector] = strread(line,'%s %s','delimiter', ':');
vector = strread(str_vector{:},'%f','delimiter',',');
return;

function vector = getVectorFromLine(line)
[foo str_vector] = strread(line,'%s %s','delimiter', ':');
str_vector = strread(str_vector{:},'%*c %s','delimiter',']');
vector = strread(str_vector{:},'%f','delimiter',',');
return;

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