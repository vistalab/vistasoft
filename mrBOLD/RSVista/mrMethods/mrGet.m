function val = mrGet(mr,prop,varargin);
%
% val = mrGet(mr,prop,[optional args]);
%
% Get a property of an mr object. 
%
% Properties include:
%   'tSeries', [coords]: get time series data in the format time by
%                        voxels, for the selected coords. If coords
%                        is omitted, uses all coords. Returns tSeries
%                        as double, although they're generally stored
%                        as scaled int16.
%
%   'coords':            coordinates for each point in the mr data.
%      
%   'path':              path to the mr file.
%   
%   'info':              subject info, if it exists.
%
%   'data', [coords]:   get the values of the mr.data field at the 
%                       selected coordinates (3xN for 3-D volumes, or 
%                       4xN matrix for 4-D volumes), interpolating 
%                       according to the interpolation preference (see 
%                       mrPrefs). 
%                        <if coords omitted, take data from all coords>
%
%
% ras, 10/2005.
if nargin<2, help(mfilename); error('Not enough args.'); end

% we should make sure we have a loaded mr struct -- but only
% if the property we get is not the filename (in that case, don't
% load if you don't have to):
if ~ismember(lower(prop), {'path' 'filepath' 'filename'})
	 mr = mrParse(mr); 
else
	if ischar(mr), val = fullpath(mr);
	else,		   val = mr.path;
	end
	
	return
end

val = [];
switch lower(prop)
    case 'tseries', % get tSeries for selected voxels
        if isempty(varargin), coords = mrGet(mr,'coords'); 
        else,                 coords = varargin{1};
        end
        
        ind = sub2ind(mr.dims(1:3), coords(1,:), coords(2,:), coords(3,:));
        mr.data = reshape(mr.data, [prod(mr.dims(1:3)) mr.dims(4)])';
        val = mr.data(:,ind);
        
    case 'data'
        if length(varargin)==0,val = mr.data; return; end
        C = varargin{1}; % coords
        if isempty(C), val = []; return; end
        if size(C, 1) < 2, error('Coords must specify >= 2 dimensions.'); end
            
        % get prefs -- includes specification of how to interpolate
        prefs = mrPrefs;
        
        %% need to grab a 3-D data volume to use the fast interp functions
        %% below -- the 4-D case is particularly complicated
        vol = mr.data; 

        % if fewer dimensions are specified in C than the data have, select
        % the first subvolume
        if ndims(vol) > size(C, 1)
            if size(C, 1)==2, vol = mr.data(:,:,1,1); 
            elseif size(C, 1)==3, vol = mr.data(:,:,:,1);
            end
        end
        
        % here's the complex 4-D case: if the data are 4-D and C has 4
        % rows, we might get the data values 2 ways. (1) If only one
        % subvolume is specified (the 4th row of C has one unique value),
        % we can just grab that subvolume and use the code below.
        % (2) data span many subvolumes: we use interpn, so it'll be slow.
        if ndims(vol) > 3  &  size(C, 1) > 3
            t = unique(C(4,:));  % subvolumes or 'time points'
            if length(t)==1      % great! just grab that one time point
                vol = mr.data(:,:,:,t);
                
            else                 % data span many points: interpN and exit
                val = interpn(mr.data, C(2,:), C(1,:), C(3,:), C(4,:), ...
                                       prefs.interp);
                return
            end
        end
                        
        % for nearest-neighbor interp, it's actually faster to just
        % round the coords and use myCinterp3 (below) than to interp3 it:
        if isequal(lower(prefs.interp), 'nearest')
            C = round(C);
        end
        
        %% get the values -- interpolation takes place here if needed
        if ismember(lower(prefs.interp), {'nearest' 'linear'})
           % can use myCinterp3, much faster
           if isequal(lower(prefs.interp), 'nearest')
               C = round(C);
           end
           sz = size(vol);
           val = myCinterp3(vol, [sz(1) sz(2)], sz(3), C([2 1 3],:)', 0.0);
                         
        else
            % need to use MATLAB's interp3, slower but more general
            val = interp3(vol, C(2,:), C(1,:), C(3,:), prefs.interp);
            
		end
        
	case 'xform',	% transform for a particular space
		if isempty(varargin)
			space = 1;
		else
			space = varargin{1};
		end
		
		if ischar(space), 
			space = cellfind(lower({mr.spaces.name}), lower(space));
		end
		
		val = mr.spaces(space).xform;
        
    case 'coords', % coordinates for each point in the mr data.
        [X Y Z] = meshgrid(1:mr.dims(2), 1:mr.dims(1), 1:mr.dims(3));
        val = [Y(:) X(:) Z(:)]';
        
    case 'path', val = mr.path;
        
    case 'info', % subject info, if it exists.
        if checkfields(mr,'hdr','info'), val=mr.hdr.info; end
        
    otherwise,
        warning('Unkown mr property.')
end

return

        