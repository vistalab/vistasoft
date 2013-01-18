function [h, hsub] = errorplot(X,Y,E,C,H,varargin);
%
% [h, hsub] = errorplot([X],Y,[E],[C],[H],[options]);
%
% Plot the data Y against points in X,
% adding a thickness specified by the
% error E. This is a counterpoint to
% addAsterisks, which puts error bars
% at each point, and may be more visible 
% when presented in smaller plots or with
% many traces.
%
% Adds asterisks over the time points specified
% in H.
%
% As with other plotting routines, the columns 
% of Y are taken to be different data traces.
%
% X should be a vector, the same length as rows
% in Y, specifying the points on the X axis against
% which to plot each time point. X can also be a
% matrix the same size as Y, if different data traces
% are meant to have different X values. If omitted,
% X is 1:size(Y,1).
%
% E is the size of the error bars and should be the
% same size as Y. If omitted, E is set to be 0.1 
% (small line thickness) for all points.
%
% H should be a vector, the same length as rows in
% Y, of ones and zeros, and should specify time points
% over which to draw asterisks. Defaults to zeroes.
%
% The optional C argument specifies the color
% of each trace. It should be a cell of color 
% specifiers (see HELP PLOT for options) or an N x 3
% matrix of R G B values from 0-1.
%
% If ERRORPLOT(Y,E) is called with two arguments,
% these are assumed to be Y and E, rather than X. 
% Otherwise, leave X empty -- e.g. ERRORPLOT([],Y,E,H)
% to get default X.
%
% Returns h, a pointer to the axes on which 
% the data are drawn, as well as hsub, a set
% of pointers to the patch object representing
% each trace.
%
%
% ras 06/05.
if nargin==2
    % a little shift to make calling
    % this easier -- see help comments above
    E = Y;
    Y = X;
    X = 1:size(Y,1);
end

if notDefined('Y')
    help errorplot
    error('Y needs to be specified.')
end

if notDefined('X'),     X = 1:size(Y,1);	end
if notDefined('E'),    E = repmat(0.1,size(Y));	end
if notDefined('H'),    H = zeros(size(Y));		end
if notDefined('C')
    % blue
    C = repmat([0 0 1], [size(Y,1) 1]);
end

% get current axes
h = gca;

% Make X same size as Y
if ~isequal(size(X),size(Y))
    if size(X,1) ~= size(Y,1) & size(X,2) ~= size(Y,1)
        error('X is an invalid size.')
    end
    
    if size(X,1)==1 | size(X,2)==1
        X = repmat(X(:),[1 size(Y,2)]);
    end
end

% if row vectors are passed in, change to column vectors
if size(Y,1)==1 & size(Y,2) > 1
	Y = Y';
	X = X';
	E = E';
end

% make sure C specifies colors for
% all traces: if not, cycle through
% until it does
if iscell(C)
    while length(C) < size(Y,2)
        C = [C C];
    end
else
    while size(C,1) < size(Y,2)
        C = [C; C];
    end
end

% plot each trace separately
hold on
for i = 1:size(Y,2)
    % make xx, yy vectors which specify vertices
    % of trace/patch: draw lower bounds first,
    % then go backwards and draw upper bounds
    xx = [X(:,i); flipud(X(:,i))]; 
    yy = [Y(:,i)-E(:,i); flipud(Y(:,i)+E(:,i))];
    
    % get color for this trace/patch
    if iscell(C)
        col = C{i};
    else
        col = C(i,:);
    end
    
    % make patch
    hsub(i) = patch(xx, yy, col);
	
	% add transparency
	set(hsub(i), 'FaceAlpha', .5, 'EdgeColor', 'w');
    
    % also make line around mean point
    plot(X(:,i), Y(:,i), 'Color', 'k', 'LineWidth', 2);
%     plot(X(:,i), Y(:,i) - E(:,i), 'Color', col./2, 'LineWidth', 1.5 ,'LineStyle', ':');    
%     plot(X(:,i), Y(:,i) + E(:,i), 'Color', col./2, 'LineWidth', 1.5, 'LineStyle', ':');
end

% add asterisks later

return




