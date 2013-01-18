function ui = mrViewDisplay(ui,parent);
%
% ui = mrViewDisplay([ui,parent]);
%
% Display the images for mrViewer UI.
%
% ras, 07/05.

% programming notes:
% I went to some pains to make the display not change the focus
% from whatever the current figure / axes were when this was called.
% This allows controls to reside on separate figures, without having
% updates be all flickery. But, it leads to what may be considered
% inelegant programming in some respects. 
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet;            end
if ~exist('parent', 'var') | isempty(parent),  parent = ui.fig;   end

% local variables (to make calling fields easier)
images = ui.display.images;
order = ui.display.order;
slices = ui.display.slices;
oris = ui.display.oris;
space = ui.settings.space;
bounds = ui.settings.bounds;
nrows = size(order,1);
ncols = size(order,2);
eqAspect = ui.settings.eqAspect;
showCursor = ui.settings.showCursor;

% clear out stored axes handles
ui.display.axes = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The ui.display field contains a cell array of images, %
% and a specified image order. Loop across each image,  %
% making axes in the appropriate place, and display     %
% each image, along with any requested annotation.      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spacer = 0.01; % size of spacer b/w images
xsz = 1/ncols; ysz = 1/nrows;
[rows cols] = find(order);
for i = 1:length(rows)
    y = rows(i); x = cols(i);
    img = order(y,x);
    otherDims = setdiff(1:3,oris(img));

    % create the axes
    pos = [(x-1)*xsz, 1-y*ysz, xsz-spacer, ysz-spacer];
    hax = axes('Parent',parent,'Units', 'normalized', 'Position',pos);
    
    % show the image
    xx = bounds(otherDims(2),1):bounds(otherDims(2),2);
    yy = bounds(otherDims(1),1):bounds(otherDims(1),2);
    h = imagesc(xx,yy,images{img}, 'Parent',hax);  
    if eqAspect, axis(hax,'equal'); end
    
    % label dirs / axes, resizing the axes to fit it, if selected
    if ui.settings.labelAxes==1 | ui.settings.labelDirs==1
        pos = pos+[.1 .1 -.2 -.1]; % adjust axes' position
        set(hax,'XColor', 'w', 'YColor', 'w', 'Position',pos);
        
        if ui.settings.labelDirs==1
            labels = ui.spaces(ui.settings.space).dirLabels(otherDims);
            labels = labelMarkup(labels);
        else
            labels = {'' ''};
        end        
        
        if ui.settings.labelAxes==1
            axis(hax,'on');
            labels{1} = [labels{1} ' [' ui.spaces(space).units ']' ];
            labels{2} = [labels{2} ' [' ui.spaces(space).units ']' ];
        else, set(hax,'YTick', [], 'XTick', []);
        end
        
        ylabel(hax,labels{1});
        xlabel(hax,labels{2});
        axis(hax,'tight');        
    else, axis(hax,'off');
    end

    % zoom
    axis(hax,[ui.settings.zoom(otherDims(2), :) ...
        ui.settings.zoom(otherDims(1), :)]);    
    
    % set properties needed for recentering / zooming
    set(h,'ButtonDownFcn',sprintf('mrViewRecenter([], %i);',oris(img)));
    set(hax,'Tag',sprintf('ori=%i',oris(img)));

    % optional annotation
    if ui.settings.labelSlices==1
        AX = axis(hax);
        text(AX(1)+10,AX(3)+10,num2str(slices(img)), ...
            'FontSize',12,'Color', [1 1 .1], 'Parent',hax);
    end
    if showCursor, 
        ui=mrViewRenderCursor(ui,oris(img),slices(img),hax);
    end

    ui.display.axes(img) = hax;
    hold(hax,'on');
end
    
if ~isempty(ui.settings.clim)
    set(ui.display.axes,'CLim',ui.settings.clim); 
end

colormap(hax,ui.settings.cmap);

return
% /--------------------------------------------------------------------/ %





% /--------------------------------------------------------------------/ %
function labels = labelMarkup(labels)
% set x and y labels w/ TeX markup, and correct for
% the fact that the y label will be rotated 90 deg, 
% in specifying directions:

% for y axis, flip 'a <--> b' to be 'b <--> a':
% the ylabel runs from down to up:
dirs = explode('<-->',labels{1});
if length(dirs)>1
    labels{1} = [dirs{2}(4:end) '<-->' dirs{1}];
end
        
for j = 1:2
    if ~isempty(strfind(labels{j}, '<-->')) 
        % replace <--> w/ TeX markup for nice labeling
        ii = strfind(labels{j}, '<-->');
        labels{j} = [labels{j}(1:ii-1) '\leftrightarrow' ...
                     labels{j}(ii+4:end)];
    end
end
return