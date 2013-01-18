function dwi = dwiSet(dwi, param, val, varargin)
% Get data from the dwi structure
%
%    NOT YET IMPLEMENTED
%
%   dwi = dwiSet(dwi, param, val, varargin)
%
% Set data in a dwi structure (see dwiCreate).
%
% Parameters
%   Data values
%
%
%   Measurement parameters
%    {'bvals'}
%    {'bvecs'}
%
% Examples: 
%   To get diffusion data from a fiber
%
% dwi = ...
%   dwiCreate('raw/DTI__aligned_trilin.nii.gz','raw/DTI__aligned_trilin.bvecs','raw/DTI_aligned_trilin.bvals');
%
% fg = dtiReadFibers('fibers/arcuate.mat');
% coords = fg.fibers{1};
% val = dwiGet(dwi,coords,'diffusion data acpc');
%
% See also:  dwiCreate, dwiGet, dtiGet, dtiSet, dtiCreate
%
% (c) Stanford VISTA Team

if notDefined('dwi'), error('dwi structure required'); end
if notDefined('param'), help('dwiGet'); end
if ~exist('val','var'), val = []; end

param = mrvParamFormat(param);

switch(param)
    
    % Names
    case {'type'}
        dwi.type = val;
    case {'name'}
        dwi.name = val;
        
        % Data fields
    case {'data'}
        % get dwi data from a set of coordinates in ac-pc space
        dwi.nifti.data = uint16(val);
        dwi.nifti.dim = size(val);
    case {'bvals'}
        dwi.bvals = val;
    case {'bvecs'}
        dwi.bvecs = val;
    otherwise
        error('Unknown arguments %s\n',param);
end


return
