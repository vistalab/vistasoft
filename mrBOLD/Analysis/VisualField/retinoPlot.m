function h = retinoPlot(pol, ecc, varargin);
% Plot the pRF centers described by polar angle
% pol and eccentricity ecc in the visual field.
%
% h = retinoPlot(pol, ecc, [options]);
%
% pol and ecc can either be vectors of equal length, or a length-2 
% cell array of vectors. In the latter case, retinoPlot will treat the
% two entries as left and right hemisphere data, and plot them in different
% colors.
%
% The code assumes pol is specified in degrees clockwise from 12-o-clock.
% If pol is in radians (CCW from 3-o-clock), you can set the option
% 'units', 'radians', or simply express pol as rad2deg(pi/2 - pol).
%
% ras, 08/2007.
if nargin < 2, error('Not enough input args.'); end

%% parameters for polarPlot
if iscell(ecc),
	maxAmp = max( [ecc{:}] );
else
	maxAmp = max( ecc(:) );
end
params.grid = 'on';
params.line = 'off';
params.gridColor = [0 0 0];
params.fontSize = 14;
params.symbol = 'o';
params.size = 1;
params.color = 'w';
params.fillColor = 'w';
params.maxAmp = maxAmp;
params.ringTicks = [0:4:12];
params.units = 'degrees';
params.sigFigs = 0;

% param for markers: symbol and color
markerSymbol = '.';
markerColor = [.3 .3 .3];
markerSize = 1;

%% parse options
for i = 1:2:length(varargin)
	if isequal(lower(varargin{i}), 'markercolor')
		markerColor = varargin{i+1};
	elseif isequal(lower(varargin{i}), 'markersymbol')
		markerSymbol = varargin{i+1};
	elseif isequal(lower(varargin{i}), 'markersize')
		markerSize = varargin{i+1};
	else
		% use for polar plot
		params.(varargin{i}) = varargin{i+1};
	end
end

%% plot the data
if iscell(pol) 
	% size checks
	if ~iscell(ecc), error('Both parameters must be cell arrays.'); end
	if  length(pol) < 2, error('Need at least 2 entries for pol.'); end
	if  length(ecc) < 2, error('Need at least 2 entries for ecc.'); end
	if length(pol{1}) ~= length(ecc{1}) | length(pol{2}) ~= length(ecc{2})
		error('pol and ecc vectors must be the same length.');
	end
	
	% convert pol to radians, if needed
	if isequal( lower(params.units), 'degrees' )
		pol{1} = deg2rad(90 - pol{1});
		pol{2} = deg2rad(90 - pol{2});
	end
	
	% convert to Cartesian coords
	[x1 y1] = pol2cart(pol{1}, ecc{1});
	[x2 y2] = pol2cart(pol{2}, ecc{2});
	
	% plot
	h = plot(x1, y1, 'k.', x2, y2, 'r.');
	setLineColors({[0 .6 0] 'r'}); % green/red
	set(h, 'MarkerSize', markerSize, 'Marker', markerSymbol);
	
else
	% size check
	if length(pol) ~= length(ecc)
		error('pol and ecc vectors must be the same length.')
	end
	
	% convert pol to radians, if needed
	if isequal( lower(params.units), 'degrees' )
		pol = deg2rad(90 - pol);
	end
	
	% convert to cartesian coords and plot
	[x y] = pol2cart(pol, ecc);
	h = plot(x, y, 'o', 'Color', markerColor, 'MarkerSize', markerSize);
	
	if ~isequal(markerSymbol, '.')
		set(h, 'Marker', markerSymbol);
	end
end

%% plot the grid
hold on
polarPlot([], params);


axis equal; axis image;

return
