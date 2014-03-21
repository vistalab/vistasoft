function [params] = niftiGetParamsFromDescrip(niftiFile)
%
%  [params] = niftiGetParamsFromDescrip(niftiFile)
%
% This function will take a nifti file and parse the descrip field to build
% a structure containing the included values.
%
% ** Note that only nifti files created by NIMS (cni.stanford.edu/nims)
%    will have these values in the descrip field.
%
% ** Note also that this function reads the nifti file, so speed is
%    completely dependent on file size.
%
%
% EXAMPLE USAGE:
%   [params] = niftiGetParamsFromNifti(niftiFile)
%
% OUTPUT:
%
%   params =
%
%     niftiFile: '4534_10_1.nii.gz'
%            tr: 0.0140
%            te: 2
%            ti: 0
%            fa: 20
%            ec: 0
%           acq: [192 256]
%            mt: 0
%            rp: 2
%            rs: 1
%
%
% (C) Stanford University, Vista Lab [2014] - LMP
%


%% Check input
if exist('niftiFile','var') && isstruct(niftiFile)
        ni = niftiFile;
        clear niftiFile;
else
    if  ~exist('niftiFile','var') || ~exist(niftiFile,'file')
        niftiFile=uigetfile('*.nii.gz','Choose nifti file');
        if niftiFile == 0
            return
        end
    end
    % Read in the nifti
    ni = niftiRead(niftiFile);
end

% Check that descrip field exists
if ~isfield(ni,'descrip')
    warning('vista:niftiError','Descrip field does not exist. Returning [].');
    params = [];
    return
end

% Get the values from the descrip field into the workspace
% Check to make sure the format is correct, i.e., there is an assigment of
% some sort.
if strfind(ni.descrip,'=')
    try
        eval([ni.descrip,';']);
    catch err
        fprintf('%s\n',err.message);
        clear err
    end
end

% Get the TR from the 4th dimension of the nifti
try
    tr = ni.pixdim(4);
catch err
	fprintf('Warning: Could not detrmine a TR for %s\n',niftiFile);
    fprintf('\t%s\n',err.message);
    clear err
    tr = nan;
end

% Remove the nifti struct, so we don't save it along with the other stuff.
clear ni

% Set a temporary name to save to
name = tempname;
save(name);

% Load the values into the output struct
params    = load(name);
params.tr = tr*1000;

% Remove the temporary name and file fields
if isfield(params,'name')
    params = rmfield(params,'name');
end
% if isfield(params,'niftiFile')
%     params = rmfield(params,'niftiFile');
% end

return


