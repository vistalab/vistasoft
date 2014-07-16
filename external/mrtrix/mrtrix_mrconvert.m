function [status, results] = mrtrix_mrconvert(orig_data_file, mif_filename, bkgrnd, verbose) 
%
% Convert a nifti image to a mrtrix .mif image.
% Example
% mrtrix_mrconvert('t1.nii.gz', 't1.mif') 

if notDefined('bkgrnd'),  bkgrnd  = false;end
if notDefined('verbose'), verbose = true; end

% First, deal with the possibility that the original data is compressed:
if strcmp(  orig_data_file(end-1:end), 'gz')
    % Try uncompressing it with gunzip:
    [status, results] = system(sprintf('gunzip %s', orig_data_file));
    % Need to change the target for conversion:
    convert_file = orig_data_file(1:end-3);
    if status ~= 0 && ~exist(convert_file,'file')
        error('There was some problem extracting the raw data file. \n UNIX Message: %s \n',results);
    end
else
    convert_file = orig_data_file;
end

cmd_str = sprintf('mrconvert %s %s', convert_file, mif_filename); 

[status,results] = mrtrix_cmd(cmd_str, bkgrnd, verbose); 

% Rezip it: 
if orig_data_file(end-1:end) == 'gz'

    [s,r] = system(sprintf('gzip %s', convert_file)); 
end


