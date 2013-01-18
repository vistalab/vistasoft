function h = outline(pixels, prefs);
% Outline pixels / points on an image.
%
% Usage: h = outline(pixels, <prefs>);
%
% pixels is a 2xN numeric vector where the first row is the X location
% of each point, and the second row is the Y location. If values in
% pixels are non-integer, they're rounded off.
%
% prefs is an optional struct in which preference arguments are passed.
% Below are valid field names for prefs, what they control, and their
% default value if omitted.
%   prefs.axesHandle: axes on which to draw points [current axes]
%   prefs.color: color of outline (HELP PLOT for format) [blue]
%   prefs.lineWidth: width of lines in outline [0.5]
%   prefs.method: drawing method for outline, an integer or string:
%                 (1) or 'perimeter':  draw outlines of the perimeter
%                 (2) or 'boxes': draw outlines of each pixel
%                 (3) or 'patches': draw patches around perimeter, w/
%                     default FaceAlpha of 0.5 (semi-transparent)
%                   [default is 1, perimeter outline]
%
% Returns h, a handle to the lines.
%
%
% ras, 08/23/2005.
% ras, 05/06: updated algorithm to be faster.
% ras, 12/106: added filled perimeter option.
h = [];

if ~exist('pixels','var') | isempty(pixels), return; end

%%%%%default params
axesHandle = []; % will replace w/ gca if not assigned below (this avoids
                 % creating unnecessary axes on control figures)
color = 'b';
lineWidth = 0.5;
lineStyle = '-';
method = 'perimeter';
w = 0.5; % offset from center of pixel

%%%%%parse prefs
if exist('prefs','var') & isstruct(prefs)
    for i = fieldnames(prefs)'
        eval(sprintf('%s = prefs.%s; ',i{1},i{1}));
    end
end

if isnumeric(method) | islogical(method)
    switch method
        case 1, method = 'perimeter';
        case 2, method = 'boxes';
        case 3, method = 'patches';
        otherwise, method = 'perimeter';
    end
end

if ischar(color), color = colorLookup(color); end

% if no axes selected, use gca
if isempty(axesHandle), axesHandle = gca; end

%%%%%round pixels and remove redundant pixels
pixels = round(pixels);
pixels = intersectCols(pixels,pixels); % removes redundant

%%%%%make axes active and get ready to draw
if ~ishandle(axesHandle), return; end   % exit gracefully, quietly
axes(axesHandle);
hold on

% get X, Y pixel locations of lines to draw
X = pixels(2,:); % columns = X position
Y = pixels(1,:); % rows = Y position

switch lower(method)
    case 'boxes'        % boxes around each pixel
        % to draw all lines at once, for each pixel we need 5 points:
        % upper right-hand corner, u.l.h.c., l.l.h.c., l.r.h.c, 
        % and finally the first point again. The corners are 0.5 
        % units away from the center of each pixel. So:
        X = repmat(X - .5, [5 1]); % default pos is upper right-hand
        Y = repmat(Y + .5, [5 1]); % corner; modify pixels 2-4 below
        X(2:3,:) = X(2:3,:) + 1;
        Y(3:4,:) = Y(3:4,:) - 1;

        % draw lines
        h = line(X, Y, 'Color', color, 'LineWidth', lineWidth);

    case 'perimeter'    % draw perimeter of region of interest
        % this is even trickier: we do the following steps:
        % (1) build a binary mask the size of the image, with 1s where
        %   the ROI points are;
        % (2) use the DIFF function to find which edges belong
        %  to the perimeter, in the up/down/left/right directions
        % (3) pad out the diff matrices with the edge rows, such
        %  that any ROI points at the edge of the image are 
        %  automatically along the perimeter;
        % (4) separately draw lines for the uppper, lower, left,
        %  and right edges

        % build mask
        himg = findobj('Parent', axesHandle, 'Type', 'image');
        sz = size(get(himg(1), 'CData'));
        sz(1) = max(sz(1), max(Y));
        sz(2) = max(sz(2), max(X));
        mask = logical(zeros(sz(1), sz(2)));
        mask(sub2ind(size(mask),Y,X)) = 1;

        % build edge matrices
        up    = [mask(1,:); diff(mask,1,1)];
        down  = [flipud(diff(flipud(mask),1,1)); mask(end,:)];
        left  = [mask(:,1) fliplr(diff(fliplr(mask),1,2))];
        right = [diff(mask,1,2) mask(:,end)];


        % draw lines -- 4 times
        % (for each edge, we replicate the X and Y positions, to
        % create a start and stop point at the pixel corners)
        [Y X] = find(up==1); X = [X-.5 X+.5]; Y = [Y-.5 Y-.5];
        h1 = line(X', Y', 'Color', color, 'LineWidth', lineWidth);

        [Y X] = find(down==1); X = [X-.5 X+.5]; Y = [Y+.5 Y+.5];
        h2 = line(X', Y', 'Color', color, 'LineWidth', lineWidth);

        [Y X] = find(left==1); X = [X-.5 X-.5]; Y = [Y-.5 Y+.5];
        h3 = line(X', Y', 'Color', color, 'LineWidth', lineWidth);

        [Y X] = find(right==1); X = [X+.5 X+.5]; Y = [Y-.5 Y+.5];
        h4 = line(X', Y', 'Color', color, 'LineWidth', lineWidth);

        h = [h1; h2; h3; h4];

%         [C htmp] = contour(mask, 1);
%         h = get(htmp, 'Children');
%         set(h, 'EdgeColor', color);


    case 'filled perimeter'
        himg = findobj('Parent', axesHandle, 'Type', 'image');
        sz = size(get(himg(1), 'CData'));
        mask = logical(zeros(sz(1), sz(2)));
        mask(sub2ind(size(mask),Y,X)) = 1;
        
        % This is adapted from Alex Wade's code in mrVista
        % drawROIsPerimeter. Not entirely clear on the logic,
        % but it is basically figuring out the (x, y) points of 
        % a dilated set or perimeter nodes, then plotting them 
        % in a dotted-outline sort of way.
        se = strel('disk', 4, 4);
        mask = imdilate(logical(mask), se);
        mask = imerode(logical(mask), se);
        mask = imfill(mask,'holes');
        mask = mask - min(mask(:));
        mask = bwperim(mask);
        onpoints = find(mask);

        [y x] = ind2sub(sz, onpoints);

        hold on;
        h = plot(x, y, '.','Color',color, 'LineWidth', lineWidth*2);


    case 'patches'      % draw ROI patches
        % build mask
        himg = findobj('Parent', axesHandle, 'Type', 'image');
        sz = size(get(himg(1), 'CData'));
        sz(1) = max(sz(1), max(Y));
        sz(2) = max(sz(2), max(X));
        mask = logical(zeros(sz(1), sz(2)));
        mask(sub2ind(size(mask),Y,X)) = 1;
        
        % make an image of the mask to put on top of the image
        img = ind2rgb(mask, [0 0 0; colorLookup(color)]);
        
        % create the image object, set Alpha to 0.5 default
        hold on
        h = image(img);
        set(h, 'AlphaData', mask*.5);
        
    otherwise, error('Invalid ROI Drawing Method.')
end

%%%%%set color, line width
if ismember(lower(method), {'lines' 'boxes'})
    set(h, 'Color', color, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
end


return




% OLD CODE, POTENTIALLY MORE STABLE 
% 
% if ~exist('pts','var') | isempty(pts), h = []; return; end
% 
% %%%%%default params
% axesHandle = []; % will replace w/ gca if not assigned below (this avoids
%                  % creating unnecessary axes on control figures)
% color = 'b';
% lineWidth = 0.5;
% lineStyle = '-';
% method = 1;
% w = 0.5; % offset from center of pixel
% 
% %%%%%parse prefs
% if exist('prefs','var') & isstruct(prefs)
%     for i = fieldnames(prefs)'
%         eval(sprintf('%s = prefs.%s; ',i{1},i{1}));
%     end
% end
% 
% % if no axes selected, use gca
% if isempty(axesHandle), axesHandle = gca; end
% 
% %%%%%round pts and remove redundant pts
% pts = round(pts);
% pts = intersectCols(pts,pts); % removes redundant
% 
% %%%%%make axes active and get ready to draw
% axes(axesHandle);
% hold on
% 
% x=pts(1,:);
% y=pts(2,:);
% h = [];
% 
% %%%%%draw points
% if method==1
%     % DRAW PERIMETER ONLY
%     for i=1:size(pts,2)
%         xMinus = find(x == x(i)-1);
%         xEquals = find(x == x(i));
%         xPlus = find(x == x(i)+1);
%         if isempty(xMinus)
%             h(end+1) = line([y(i)-w, y(i)+w],[x(i)-w, x(i)-w]);
%         else
%             if ~any(y(i) == y(xMinus))
%                 h(end+1) = line([y(i)-w, y(i)+w],[x(i)-w, x(i)-w]);
%             end
%         end
%         if isempty(xPlus)
%             h(end+1) = line([y(i)-w,y(i)+w],[x(i)+w, x(i)+w]);
%         else
%             if ~any(y(i) == y(xPlus))
%                 h(end+1) = line([y(i)-w,y(i)+w],[x(i)+w, x(i)+w]);
%             end
%         end
%         if ~isempty(xEquals)
%             if ~any(y(i) == y(xEquals)-1)
%                 h(end+1) = line([y(i)+w,y(i)+w],[x(i)-w, x(i)+w]);
%             end
% 
%             if ~any(find(y(i) == y(xEquals)+1))
%                 h(end+1) = line([y(i)-w,y(i)-w],[x(i)-w, x(i)+w]);
%             end
%         end
%     end
% else
%     % DRAW BOXES AROUND EACH PIXEL
%     for i=1:size(pts,2)
%         h(end+1) = line([y(i)-w, y(i)+w, y(i)+w, y(i)-w, y(i)-w],...
%                         [x(i)-w, x(i)-w, x(i)+w, x(i)+w, x(i)-w]);
% 
%     end
% end
% 
% %%%%%set color, line width
% if exist('h', 'var') & ishandle(h)
%     set(h,'Color',color,'LineWidth',lineWidth,'LineStyle',lineStyle);
% end
% 
% return


