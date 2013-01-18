function h = mv_sparkline(varargin);
%
% h = mv_sparkline(Y);
%   or
% h = mv_sparkline(X, Y);
%   or 
% h = mv_sparkline(X, Y, ysz);
%
% Plot a small representation of a vector of amplitude
% responses in Y against a set of X values. X is 1:length(Y)
% if omitted. Makes a dotted line showing the zero point, and
% labels the min and max values in Y with small text labels.
% Turns off the axis markers. 
%
% If the optional ysz argument is specified as a [min max] vector, will 
% set the axis bounds such that Y is scaled to that range, otherwise,
% will set a tight axis bounds around the data.\
%
% Returns h, a vector of handles to:
%   [data line, zero line, maxMarker, maxText, minMarker, minText]
%
% ras, 01/2007.
if notDefined('label'),		label = 0;		end

switch nargin
    case 0, error('Not enough input args.'); 
    case 1, Y = varargin{1}; X = 1:length(Y); ysz = [min(Y) max(Y)];
    case 2, X = varargin{1}; Y = varargin{2}; ysz = [min(Y) max(Y)];
    otherwise, X = varargin{1}; Y = varargin{2}; ysz = varargin{3};       
end
    
hold on

% plot the data
h(1) = plot(X, Y, 'k');

% zero line
h(2) = line([X(1)-1 X(end)+1], [0 0], 'Color', 'r', 'LineStyle', ':');


if label==1
	% min / max labels
	hi = max(Y); iHi = X( find(Y==hi) );
	lo = min(Y); iLo = X( find(Y==lo) );
	rng = diff(ysz);

	h(3) = plot(iHi, hi, 'Color', [.5 .5 1], 'Marker', '.'); 
	h(4) = text(iHi + .06*rng, hi + .1*rng, sprintf('%3.2f',hi), ...
            'FontSize', 8, 'Color', [.5 .5 .5]);

	h(5) = plot(iLo, lo, 'Color', [1 .5 .5], 'Marker', '.'); 
	h(6) = text(iLo + .06*rng, lo - .1*rng, sprintf('%3.2f',lo), ...
            'FontSize', 8, 'Color', [.5 .5 .5]); 
end

axis([X(1)-1 X(end)+1 ysz])
axis off

return
