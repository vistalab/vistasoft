function h = addAsterisks(Y,E,sel,varargin);
% h = addAsterisks(Y,E,sel,[plot options]);
%
% Creates an errorbar plot, with asterisks over selected
% points. Y is a matrix of column vectors containing the 
% data to be plotted, E is a matrix the same size as Y containing 
% error lengths for each point. (In this respect, it is the same
% as calling ERRORBAR(Y,E).) sel can either be: 
%      1) a matrix the same size as Y and E, with a 1 at each
%         location which will get an asterisk and a 0 otherwise, or
%   
%      2) a vector equal to the # of rows or columns, selecting entire
%         rows or columns for asterisks.
%
% Any fourth or later input arguments are passed on to the ERRORBAR command
% (e.g., formatting arguments -- see HELP PLOT for more details.), except
% for the following:
%
% 'X',[vals]: provide the values to plot on the X-axis as the next arg.
%
% 'leg',{'labels'}: add a legend using the labels in the next argument
% (as a cell-of-strings)

% 03/03 ras
% 01/04 ras: fixed bug in which asterisks were never centered
if ~exist('sel','var')  | isempty(sel)
    sel = zeros(size(Y));
end

% figure out if entire rows/colums are selected for asterisks
if length(sel)==size(Y,1) & isequal(unique(sel),[0 1])
    sel = repmat(sel,size(Y,2),1)';
elseif length(sel)==size(Y,2) & isequal(unique(sel),[0 1])
    sel = repmat(sel,size(Y,1),1);
end

%%%%% defaults 
X = repmat(1:size(Y,1),size(Y,2),1)';
plotOptions = {};

%%%%% parse the option flags 
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case {'leg','legend'}
                leg = varargin{i+1};
            case 'x',
                X = varargin{i+1};
                if size(X,1)==1
                    X = repmat(X,size(Y,2),1)';
                end
            otherwise,
                plotOptions{end+1} = varargin{i};
        end
    end
end

if isempty(plotOptions)
    h = errorbar(X,Y,E);
else
    cmd = ['h = errorbar(X,Y,E'];
    for i = 1:length(plotOptions)
        cmd = [cmd ',''' plotOptions{i} ''''];
    end
    cmd = [cmd ');'];
    eval(cmd);
end
AX = axis;
xSz = AX(2) - AX(1);
ySz = AX(4) - AX(3);

whichPoints = find(sel);

for i = 1:length(whichPoints)
    pt = whichPoints(i);
    xLoc = X(pt);
    yLoc = Y(pt) + E(pt) + 0.05*ySz;
    h2 = text(xLoc,yLoc,'*','FontSize',24,'HorizontalAlignment','center');
    %set(h2,'HorizontalAlignment','center');
    %set(h2,'Fontsize',20);
end


return