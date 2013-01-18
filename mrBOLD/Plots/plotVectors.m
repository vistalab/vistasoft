function h = plotVectors(Y, varargin);
% Plot a matrix of amplitude vectors in a series of subplots.
%
% h = plotVectors(Y);
%
% Each column in Y is plotted in a separate subplot.
%
% If you enter additional input arguments, e.g.:
% 
% h = plotVectors(X, Y, Z);
%
% where X, Y, and Z are all the same size, corresponding columns of each
% input will be plotted in the same subplot.
%
% ras, 12/2007.
if length(varargin) >= 1
	% check for additional data vectors
	try
		for n = 1:length(varargin)
			Y(:,:,n+1) = varargin{n};
		end
	catch
		size(Y)
		for n = 1:length(varargin)
			size(varargin{n})
		end
		error('Additional input vectors must be the same size.')
	end
end

% get color order for figure
co = plotVectors_colorOrder(size(Y, 3));

% open the figure
h(1) = figure('Color', 'w', 'Position', [100 100 600 500]);

N = size(Y, 2);
nrows = ceil( sqrt(N) ); 
ncols = ceil( N / nrows );

% want the position of the lower left-hand subplot, 
% which is the only one that will have visible axes
lowerLeft = (nrows-1) * ncols + 1;

for n = 1:N
	h(n+1) = subplot(nrows, ncols, n);
	hold on
	
	for z = 1:size(Y, 3)
		plot(Y(:,n,z), 'LineWidth', 1);
	end
	
	axis tight
	set(gca, 'Box', 'off', 'TickDir', 'out');
	
	if n ~= lowerLeft
		axis off
	end
	
	setLineColors(co);
end

normAxes(h(2:end));

return
% /----------------------------------------------------------/ %



% /----------------------------------------------------------/ %
function co = plotVectors_colorOrder(N);
% create a nice color order for plotAmps (the default one isn't
% so great).

co = [0 0 0; ...
	  1 0 0; ...
	  0 0 1; ...
	  .5 .5 0; ...
	  0 .5 .5; ...
	  .4 .4 .4; ...
	  0 .6 0; ...
	  0 1 1; ...
	  1 0 1];
  
while size(co, 1) < N
	co = [co; co];
end

co = co(1:N,:);

return


