function outNii = niftiSelect(nii, varargin)
% Preserve data within a spatial cube and zero everything outside it
%
%    boxNii = niftiSelect(nii, varargin)
%
% Typical uses
%    Select a portion of a volume in a white matter mask
%    Extract certain volumes from a 4D data set (e.g., bvals = 2000)
%
% This function writes and saves a new nifti where specified dimensions of
% the data are overwritten with zeros. Useful for unit testing.
%
%  Parameters
%   'nii'          filename or nii struct
%   'saveFlag'   logical
%   'niiNewName' string
%   'keepLR'     vector
%   'keepPA'     vector
%   'keepIS'     vector
%
% Outputs
%   boxNii: the new nifti file (in the form of readFileNifti)
%
% Inputs
%   nii: the nifti file to be copied, and an output of readFileNifti
%   keepLR: the dimensions to keep in the 1st dimension
%   keepPA: the dimensions to keep in the 2nd dimension
%   keepIS: the dimensions to keep in the 3rd dimension
%   niiNewName: Full path to the new nifti file
%   saveFlag:  Save the nii as niiNewName (default: boxNifti)
%
% Examples
%  Extract a small volume from a T1
%    nii = niftiRead(fullfile(vistaRootPath,'rdt','inplane.nii.gz'));
%    niftiView(nii);
%    clear p;  p.keepLR = 16:64; p.keepPA = 96:159; p.keepIS = 5:15;  p.saveFlag = false;
%    boxNii = niftiSelect(nii,p);
%    niftiView(boxNii);
%
%    p.saveFlag = true; p.niiNewName = 'deleteMe';
%    niftiSelect(nii,p);  boxNii = niftiRead(p.niiNewName); niftiView(boxNii);
%
% RL/BW Vistasoft Team, 2016

%% Parameters
p = inputParser;

% Could be a file name or a nifti struct
vFunc = @(x)((ischar(x) && exist(x,'file')) || (isstruct(x) && isfield(x,'nifti_type')));
p.addRequired('nii',vFunc);
if ischar(nii), nii = niftiRead(nii); end

p.addParameter('saveFlag',true,@islogical);
p.addParameter('niiNewName','boxNifti',@ischar);

sz = size(nii.data);
p.addParameter('keepLR',1:sz(1),@isvector);
p.addParameter('keepPA',1:sz(2),@isvector);
p.addParameter('keepIS',1:sz(3),@isvector);

p.parse(nii,varargin{:});
niiNewName = p.Results.niiNewName;
saveFlag   = p.Results.saveFlag;
keepLR = p.Results.keepLR;
keepPA = p.Results.keepPA;
keepIS = p.Results.keepIS;


%% the original nifti
niiDims = nii.dim;
   
%% the dimension we want to ZERO out
zeroLR = setdiff(1:niiDims(1), keepLR);
zeroPA = setdiff(1:niiDims(2), keepPA);
zeroIS = setdiff(1:niiDims(3), keepIS); 

% volume of the original and the cropped
% vol = prod(niiDims); 
% volCropped = length(keepLR) * length(keepPA) * length(keepIS);
% fracCrop = volCropped/vol;
% display(['The cropped volume is ' num2str(fracCrop) ' of the original. '])

%% the new data field
newData = nii.data; 
newData(zeroLR,:, :) = 0; 
newData(:,zeroPA, :) = 0; 
newData(:,:, zeroIS) = 0; 

%% Make the new nifti struct
outNii = nii; 
outNii.fname = niiNewName;
outNii.data  = newData; 

if saveFlag, niftiWrite(outNii); end

end