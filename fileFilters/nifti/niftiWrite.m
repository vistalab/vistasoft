function niftiWrite(ni,fName)
%  Writes a nifti structure to disk. 
%
%   niftiWrite(ni,[fName])
%
% Uses the NIFTI-1 implementation in Matlab from Shen. 
% 
% INPUTS
%   ni - a nifti structure 
%   fName - output file name  (defaults to ni.fname if empty). 
% 
% FILE FORMATS:
%   Defaults to compressed '.nii.gz' format. If fName is set to
%   [something]'.nii' then compression is not performmed as it is presumed
%   that the user does not want the file to be compressed.
% 
% EXAMPLE:
%   ni = niftiRead('niftiFile.nii.gz');
%   fName = 'myFile.nii.gz'
%   niftiWrite(ni,fName);
% 
% See also:  niftiCreate, feWriteValues2nifti
% 
% (C) Stanford VISTA, 2012-2015
% 

%% Set defaults
compress = true;
fname_supplied = false;


%% Check inputs
if nargin==0
    help(mfilename)
    return
end

if notDefined('fName')
    fName = '';
else
    fname_supplied = true;
end


%% Check file extension

% If no name was supplied check the nifti structure for the name
if isempty(fName)
    if isfield(ni,'fname') && ~isempty(ni.fname)
        fName = ni.fname;
    else
        error('A filename is required to save a NIFTI-1 structure to file.');
    end
end
    
% Handle the file extension (must be '.nii' for save_nii)
[p, f, e] = fileparts(fName);
switch e
    case '.gz'
        fName = fullfile(p,f);
    case '.nii'
        % If a filename was passed in and it was something'.nii' then we
        % assume the user does not want the file compressed.
        if fname_supplied; compress = false; end
    otherwise
        fName = fullfile(p,[f '.nii']);
end


%% Deal with old VISTASOFT nifti structures.
if isfield(ni,'data')
  % This is likely to be a old VISTASOFT nifti-1 structure, see
  % niftiVista2ni.m
  ni = niftiVista2ni(ni);
end


%% Save the file to disk using Shen's code.
save_nii(ni,fName);


%% GZip the file
if compress
    gzip(fName);
     
    % Delete the unzipped file created by save_nii.m:
    delete(fName);
end

return
