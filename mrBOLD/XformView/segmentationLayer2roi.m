function ROI = segmentationLayer2roi(ni, varargin)
% Convert a layer from a nifti segmentation file (created by itkGray) into
% a mrVista Gray ROI 
%
% ROI = segmentationLayer2roi(ni, varargin)
%
%   INPUTS:
%       ni: a matrix, a nifti struct, or a path to a nifti file
%       Optional Inputs:
%           savepath: a directory in which to save the ROI (if no path, then
%                 don't save; just return the ROI struct)
%           color: a 3-vector or color char (rbgcymkw)
%           comments: string for ROI.comments
%           name: string for ROI.name
%           layer: integer layer number in input matrix to be converted to
%                   ROI (Note that an ITK gray segmentation file can have
%                   any number of layers. We may want to convert only one
%                   of them to an ROI.)
%   OUTPUT:
%       ROI: a mrVista gray-view ROI struct
%
% see nifti2mrVistaAnat.m
%
% Example:
%
%   ni =   '3DAnatomy/t1_class.nii';
%   fname = 'LeftWhiteMatter'
%   col = 'm';
%   ROI = segmentationLayer2roi(ni, 'name', fname, 'color', col, 'layer', 2);
%
% April, 2009: JW

%--------------------------------------------------------------
% variable check
if nargin > 1
    for ii = 1:2:length(varargin)
        switch lower(varargin{ii})
            case {'savepath'}
                savepath = varargin{ii+1};
            case {'color', 'roicolor'}
                ROI.color = varargin{ii+1};
            case 'comments'
                ROI.comments = varargin{ii+1};
            case {'name', 'roiname'}
                ROI.name = varargin{ii+1};
            case {'layer'}
                layer = varargin{ii+1};
            case{'roi'}
                ROI = varargin{ii+1};
            otherwise
                warning('Unknown input arg: %s', varargin{ii}); %#ok<WNTAG>
        end
    end
end
%--------------------------------------------------------------

% We assume that the input data structure comes from an ITK-generated
% nifti, which must be permuted for our standard mrVista format
data = nifti2mrVistaAnat(ni);

% Find the indices in the 3d image that have nonzero values
if exist('layer', 'var')
    % if we know the layer, just get voxels with that value
    ROIinds = find(data == layer);
else
    % otherwise get all the non-zero voxels in the image
    ROIinds = find(data);
end

% Get the XYZ coordinates of these indices
[x y z] = ind2sub(size(data), ROIinds );

% Define a mrVista Gray ROI using these coordinates
ROI.coords   = single([x y z]');
ROI.created  = datestr(now);
ROI.modified = datestr(now);
ROI.viewType = 'Gray';

% Add optional or default ROI fields
if ~isfield(ROI, 'name'),       ROI.name = 'MyROI'; end
if ~isfield(ROI, 'color'),      ROI.color   = 'b'; end
if ~isfield(ROI, 'comments'),   ROI.comments = sprintf('%s: created by anat2roi', ROI.name); end

% If requested, save
if exist('savepath', 'var'), save(fullfile(savepath, ROI.name), 'ROI'); end

% Done
return