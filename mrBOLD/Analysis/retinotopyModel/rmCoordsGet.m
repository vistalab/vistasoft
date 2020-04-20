function [val, subCoords] = rmCoordsGet(viewType, model, param, coords)
% rmCoordsGet - wrapper for rmGet to limit values to certain coordinates
%
% val = rmCoordsGet(viewType, model, param, coords)
%

% 2008/02 SOD: split of from rmPredictedTSeries.
% 2008/06 RAS: changed view argument to viewType: this will prevent the
% rmPlotGUI code from having to carry around a large view structure,
% substantially reducing its memory footprint.
% 2009/01 RAS: allows the coords variable for gray views to be a 3xN list
% of coordinates, in addition to a vector of gray node indices.
% 2018/02 RKL: returns the coords as the 2nd output. because they will be a
% subset of the coords that are inputed
if ~exist('viewType','var') || isempty(viewType),   error('Need view type'); end;
if ~exist('model','var')    || isempty(model),      error('Need model');     end;
if ~exist('param','var')    || isempty(param),      error('Need param');     end;
if ~exist('coords','var'),                          error('Need coords');    end;
if isempty(coords), val = []; return; end
% allow the model to be a cell array -- just take the first entry
if iscell(model), model = model{1};  end

% if we input a view instead of a viewType, sort this out
if isstruct(viewType), vw = viewType; viewType = vw.viewType; end

tmp = rmGet(model, param);

switch lower(viewType),
    case 'inplane'
        
        % normally inplane data will be 3D, but if we have only one slice
        % it will be 2d. we need to check.
        if ~exist('vw', 'var') || isempty(vw), vw = getSelectedInplane; end
        dims = length(viewGet(vw, 'anat size'));
        
        % If there is one value per voxel, then we expect a matrix of
        % parameter values with the same dimensionality as our inplane
        % anatomy (usually 3d, unless we have only 1 slice in which case it
        % is 2d). So we get the values of this matrix indexed by the 3D
        % coords. So for coord (x, y, z), we would like
        %   val = tmp(x, y, z);
        % In the case of a 2D anat, we would like 
        %   val = tmp(x,y);
        if length(size(tmp)) <= dims
            val = zeros(size(coords, 2), 1);
            for n = 1:length(val),
                if dims == 3,
                    val(n) = tmp(coords(1,n), coords(2,n), coords(3,n));
                elseif dims == 2
                    val(n) = tmp(coords(1,n), coords(2,n));
                end
            end;
        end
        
        % If there is more than one value per voxel, then we expect a
        % matrix of parameter values that has one more dimension than our inplane anatomy. 
        % In this case we get all the values of this matrix whose first
        % 3 dimensionpars are indexed by the 3D coords. So for coord (x, y, z)
        % we would like 
        %   val = tmp(x, y, z, :); 
        % If our inplane happens to be 2d (because we have only slice),
        % then we would like
        %   val = tmp(x, y, :);
        
        if length(size(tmp)) > dims
            val = zeros(size(coords, 2), size(tmp, dims));
            for n = 1:size(val,1),
                 if dims == 3,
                     val(n, :) = tmp(coords(1,n), coords(2,n), coords(3,n), :);
                 elseif dims == 2
                     val(n, :) = tmp(coords(1,n), coords(2,n), :);
                 end
            end;
        end
                 
    case 'gray'
        % allow 3xN gray coords to be specified, as well as gray node
        % indices:
        if size(coords, 1)==3
            % 3xN coords specification: remap into indices
            vw = getSelectedGray; 
            allCoords = viewGet(vw, 'coords');
            [subCoords coords] = intersectCols(allCoords, coords); %#ok<ASGLU>
        end
        
        if numel(size(tmp)) == 2,
            val = tmp(coords);
        else
            if length(coords)==1
                % the squeeze command will mis-orient fields like beta, by
                % permuting across multiple dimensions. We want it to
                % voxels x predictors.
                val = permute(tmp(1,coords,:), [2 3 1]);
            else
                val = squeeze(tmp(1,coords,:));
            end
        end
        
    otherwise, error('Invalid view type.')
end;

return
