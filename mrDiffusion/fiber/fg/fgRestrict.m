function [fgNew, v2fnm] = fgRestrict(fg,varargin)
% Starting with a fg apply a restriction to generate a new subset of fg
%
%   fgNew = fgRestrict(fg,varargin)
%
% The general format of the inputs are
%
%     fgNew = fgRestrict(fg,'param',val,'param2',val2 ...)
%
% Thus, varargin should be an even number. The val is a structure
% containing all of the parameters need for the 'param' operation.
%
% fg:  Fiber group
% param, val pairs:
%   'length',       val.length in mm
%   'anisotropy',   val.minAnisotropy
%   'roi coords',    val.roiCoords (Nx3 matrix of image coords or acpc coords)
%   'unique fibers', val.roiCoords (as above)
%
% Examples: (See s_mctArcuateFiberPredictions.m)
%
%    fgNew = fgRestrict(fg,'length',100);   % Only keep fibers longer than 10 mm
%
%    val.roiCoords = roiCoords;
%    val.v2fnm  = voxels2fnpairs;
%    fgRestrict(fg,'roiCoords',val);
%
% See also:  fgExtract, fgGet(fg,'unniquecoords')
%
% (c) Stanford VISTA Team
%

if notDefined('fg'), error('Fiber group required'); end
% mod(X,2) returns false for even numbers, true for odd numbers
if mod(length(varargin),2), error('Require even number of varargin'); end

% Might be computed.
v2fnm = [];

for ii=1:2:(length(varargin)-1)
    
    switch  mrvParamFormat(varargin{ii})
        case 'length'
            % Remove fibers whose length is less than varargin{ii+1} in mm
            l = fgGet(fg,'nodes per fiber');
            lst = find(l < varargin{ii+1});   % sum(lst)
            if ~isempty(lst)
                % Still debugging fgExtract - BW, 12.24.2011
                fgNew = fgExtract(fg,lst,'remove');
            end
        case 'roicoords'
            % params.roiCoords = roiCoords;
            % params.v2fn  = fgGet(fgImg,'v2fn',roiCoords);
            % fgNew = fgRestrict(fgImg,'roiCoords',params);
            %
            % Remove fibers that do not pass through at least one of the
            % roiCoords.
            
            % In this case, it is typical that the fiber coordinates have
            % been transformed to image space and the roiCoords are in
            % image space. So we check for that:
            if isfield(fg, 'coordspace') && ~strcmp(fg.coordspace, 'img')
                error('Fiber group is not in the image coordspace, please xform');
            end
            
            val = varargin{ii+1};
            roiCoords = val.roiCoords;
            % voxels 2 fiber-node matrix is a cell array of matrices, one
            % for each roiCoord.  The first column of the matrix is a fiber
            % passing through the voxel, and the second column is the node
            % of that fiber.
            % It is time-consuming to compute v2fnm (via an
            % fgGet).  So if it is already computed, you should send it in.
            % Otherwise, we compute it here.
            if isfield(val,'v2fn'), v2fn = val.v2fn;
            else v2fn = fgGet(fg,'v2fn',roiCoords);
            end
            
            % Rows are voxels, columns are fibers
            v2fiberMatrix = fgGet(fg,'voxels 2 fiber matrix',roiCoords,v2fn);
            % mrvNewGraphWin; ii = 1; plot(v2fiberMatrix(ii,:));
            % sum(v2fiberMatrix(ii,:))
            
            % Sum down the rows.  If the sum > 0, the fiber is in a voxel
            fiberList = find(sum(v2fiberMatrix,1)==0);   % Columns with zeroes
            % mrvNewGraphWin; plot(sum(v2fiberMatrix,1),'o')
            
            
            if isempty(fiberList)
                % No fibers outside the ROI:
                fgNew = fg;
            else
                % Remove the fibers that sum to zero
                fgNew = fgExtract(fg, fiberList, 'remove');
            end
            
        case 'uniquefibers'
            % val.roiCoords = roiCoords;
            % val.v2fnm  = voxels2fnpairs;
            % fgNew = fgRestrict(fg,'unique fibers',val);
            
            % get the roi coordinates
            val = varargin{ii+1};
            roiCoords = val.roiCoords;
            
            % It is time-consuming to compute v2fnm (via an
            % fgGet).  So if it is already computed, you should send it in.
            % Otherwise, we compute it here.
            if isfield(val,'v2fn'), v2fn = val.v2fn;
            else v2fn = fgGet(fg,'v2fn',roiCoords);
            end
            
            % Rows are voxels, columns are fibers
            v2fiberMatrix = fgGet(fg,'voxels 2 fiber matrix',roiCoords,v2fn);
            
            % find the unique fibers
            [~, fiberList] = unique(v2fiberMatrix','rows');
            
            % remove duplicate fibers - leave in unuqie fibers only
            fgNew = fgExtract(fg,fiberList,'keep');
            
        otherwise
            error('Unknown parameter: %s\n',varargin{ii});
    end
    
end

return

%     case {'uniquefibers'}
%         error('Not yet implemented');
%         % Return the fibers a a certain tolerance
%         %   coords = fgGet(fg,'unique fibers',xform, [tol]);
%
%         if isempty(varargin), error('ACPC to image transform required'); end
%         xForm = varargin{1};
%         if length(varargin) < 2
%
%         else
%            tol =
%         end
%
%         fg = dtiXformFiberCoords(fg,xForm);
%         val = round(horzcat(fg.fibers{:})');
%         val = unique(val,'rows');
%
% keyboard
%        case {'fiberlengths'} - Fibers > some length
%        case {'fiberanisotropy'} - Fibers with average FA > xx
%
return



