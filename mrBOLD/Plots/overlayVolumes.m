function h = overlayVolumes(vol1,vol2,backgnd,whichCmaps,varargin);
% h = overlayVolumes(vol1,vol2,[backgnd],[whichCmaps],[options]);
%
% Create an interface for viewing two superimposed volumes
% on top of each other, with an optional background volume.
%
% vol1, vol2, and the background volume must be of the same 
% size (or superimposing makes no sense). 
%
% This was written originally for the following uses, but
% may end up being more general:
%   * Given two functional MRI volumes (say, a volume from the
%     beginning and end of a session), see if they overlap well
%     or moved;
%   * Given two parameter maps for fMRI data, see regions of
%     overlap, while varying the thresholds (the background
%     image in this case might be a high-resolution anatomical
%     image of the same region).
%
% whichCmaps: specify the default color maps for the 2 overlays.
% can be a cell w/ two strings, or a vector with 2 index #s. 
% The available color maps, and their corresponding index #s, are:
%   1) Gray, 2) Red, 3) Green, 4) Blue,
%   5) Red+Green, 6) Red+Blue, 7) Green+Blue,
%   8) Autumn, 9) Winter, 10) Jet, 11) Hot, 12) Cool, 
%   13) Red Binary, 14) Green Binary, 15) Blue Binary
%
% The defaults are Green+Blue for the 1st overlay, Red for 
% the 2nd (so areas of agreement are gray).
%
% Other options:
%   'map1Name:',[name]: specify the label for the first map.
%   'map2Name:',[name]: specify the label for the second map.
%
% 06/15/04 ras: started writing it.
% 08/13/04 ras: added toggle switches, switch b/w vols option,
% and binary color maps.
% 01/21/05 ras: added ability to input cmaps as input params
if nargin==0
    help overlayVolumes;
    return
end

% parse the input args
for i = 1:length(varargin)
    switch lower(varargin{i})
        case 'map1name', map1Name = varargin{i+1};
        case 'map2name', map2Name = varargin{i+1};
    end
end

if nargin==1
    if ishandle(vol1)
        % this is the sign to refresh an existing
        % UI -- vol1 is actually a handle to the 
        % UI figure
        overlayVolRefresh(vol1);
    end
    return
end

if ieNotDefined('backgnd')
    backgnd = [];
end

if ieNotDefined('whichCmaps')
    whichCmaps = [7 2];
end

% color map options
opts = {'Gray' 'Red' 'Green' 'Blue' 'Red+Green' 'Red+Blue' 'Green+Blue' ...
        'Autumn' 'Winter','Jet','Hot','Cool',...
        'Red Binary','Green Binary','Blue Binary'};            

if iscell(whichCmaps)
    % convert to an index vector
    whichCmaps = lower(whichCmaps);
    tmp(1) = cellfind(lower(opts),whichCmaps{1});
    tmp(2) = cellfind(lower(opts),whichCmaps{2});
    if isempty(tmp(1)), tmp(1) = 7; end
    if isempty(tmp(2)), tmp(2) = 2; end
    whichCmaps = tmp;
end

% size check
if size(vol1) ~= size(vol2)
    error('Vol1 and Vol2 must be the same size.');
end

if ~isempty(backgnd) & (size(backgnd) ~= size(vol1))
    error('Background image must be the same size as the volumes.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From here to return, am setting up the figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get defaults
if ieNotDefined('map1Name')
    map1Name = inputname(1);
end
if ieNotDefined('map2Name')
    map2Name = inputname(2);
end

% open fig
figtxt = sprintf('Overlay Volumes %s and %s',map1Name,map2Name);
h = figure('Units','Normalized',...
           'Position',[.3 .3 .5 .5],...
           'Color','w',...
           'Name',figtxt);

% main axes, frames for 2 overlays
hax = axes('Position',[.05 .1 .6 .8],'XTick',[],'YTick',[]);

hf1 = uicontrol('Style','Frame','Units','Normalized',...
                'Position',[.7 .45 .25 .3]);

hf2 = uicontrol('Style','Frame','Units','Normalized',...
                'Position',[.7 .1 .25 .3]);

% controls for navigating slices (only visible if >1 slice)        
if (size(vol1,3)>1) vis = 'on'; else vis = 'off';   end
hs1 = uicontrol('Style','slider','Value',1,...
                'Min',1,'Max',size(vol1,3),...
                'Visible',vis,'Units','Normalized',...
                'SliderStep',[1/size(vol1,3) 3/size(vol1,3)],...
                'Callback','overlayVolumes(gcf);',...
                'Position',[.7 .83 .25 .04]);
he1 = uicontrol('Style','edit','String','1',...
                'Visible',vis,'Units','Normalized',...
                'Callback','overlayVolumes(gcbo);',...
                'Position',[.83 .88 .10 .04]);
ht1 = uicontrol('Style','text','String','Slice:',...
                'FontSize',14,...
                'Visible',vis,'Units','Normalized',...
                'Position',[.72 .88 .10 .04]);                        
         
% controls for 1st overlay        
hc1 = uicontrol('Style','checkbox','Value',1,...
                'Callback','overlayVolumes(gcf);',...
                'String','Toggle',...
                'Units','Normalized',...
                'Position',[.72 .48 .21 .04]);            
hs2 = uicontrol('Style','slider','Value',min(vol1(:)),...
                'Min',min(vol1(:)),'Max',max(vol1(:)),...
                'Callback','overlayVolumes(gcf);',...
                'Units','Normalized',...
                'Position',[.72 .6 .21 .04]);
he2 = uicontrol('Style','edit','String',num2str(min(vol1(:))),...
                'Callback','overlayVolumes(gcbo);',...
                'Units','Normalized',...
                'Position',[.83 .65 .10 .04]);
ht2 = uicontrol('Style','text','String','Thresh:',...
                'Units','Normalized',...
                'Position',[.72 .65 .10 .04]);

            
% controls for 2nd overlay        
hc2 = uicontrol('Style','checkbox','Value',1,...
                'Callback','overlayVolumes(gcf);',...
                'String','Toggle',...
                'Units','Normalized',...
                'Position',[.72 .13 .21 .04]);            
hs3 = uicontrol('Style','slider','Value',min(vol2(:)),...
                'Min',min(vol2(:)),'Max',max(vol2(:)),...
                'Callback','overlayVolumes(gcf);',...
                'Units','Normalized',...
                'Position',[.72 .25 .21 .04]);            
he3 = uicontrol('Style','edit','String',num2str(min(vol1(:))),...
                'Callback','overlayVolumes(gcbo);',...
                'Units','Normalized',...
                'Position',[.83 .3 .10 .04]);
ht3 = uicontrol('Style','text','String','Thresh:',...
                'Units','Normalized',...
                'Position',[.72 .3 .10 .04]);
    
% popups for clormaps            
hp1 = uicontrol('Style','popup','String',opts,...
                'Callback','overlayVolumes(gcf);',...
                'Value',whichCmaps(1),'Units','Normalized',...
                'Position',[.72 .53 .21 .04]);
hp2 = uicontrol('Style','popup','String',opts,...
                'Callback','overlayVolumes(gcf);',...
                'Value',whichCmaps(2),'Units','Normalized',...
                'Position',[.72 .18 .21 .04]);
            
ht4 = uicontrol('Style','Text','String',map1Name,...
          'FontSize',12,'HorizontalAlignment','left',...
          'Units','Normalized','Position',[.7 .75 .2 .04]);
ht5 = uicontrol('Style','Text','String',map2Name,...
          'FontSize',12,'HorizontalAlignment','left',...
          'Units','Normalized','Position',[.7 .4 .2 .04]);
      
%%%%%%%%%%%%%      
% Add Menus %
%%%%%%%%%%%%%
hm1 = uimenu('Label','OverlayVolume Options',...
             'ForegroundColor',[1 0 1]);
cbstr = ['data = get(gcf,''UserData'');' ...         
         'val1 = get(data.handles.toggle(1),''Value'');' ...
         'set(data.handles.toggle(1),''Value'',~val1);' ...
         'set(data.handles.toggle(2),''Value'',val1);' ...
         'overlayVolumes(gcf);'];
 
 hm2 = uimenu(hm1,'Label','Switch between volumes',...
              'Accelerator','T',...
              'Callback',cbstr);

cbstr = ['data = get(gcf,''UserData'');' ...         
         'val1 = get(data.handles.toggle(1),''Value'');' ...
         'set(data.handles.toggle(1),''Value'',~val1);' ...
         'overlayVolumes(gcf);'];
 hm3 = uimenu(hm1,'Label','Toggle first overlay',...
              'Accelerator','1',...
              'Callback',cbstr);
          
cbstr = ['data = get(gcf,''UserData'');' ...         
         'val1 = get(data.handles.toggle(2),''Value'');' ...
         'set(data.handles.toggle(2),''Value'',~val1);' ...
         'overlayVolumes(gcf);'];
 hm4 = uimenu(hm1,'Label','Toggle second overlay',...
              'Accelerator','2',...
              'Callback',cbstr);
          
cbstr = ['data = get(gcf,''UserData'');' ...         
         'set(data.handles.popup(1),''Value'',1);' ...
         'set(data.handles.popup(2),''Value'',1);' ...
         'overlayVolumes(gcf);'];
 hm5 = uimenu(hm1,'Label','Set both to gray cmap',...
              'Accelerator','5',...
              'Callback',cbstr);
          
cbstr = ['data = get(gcf,''UserData'');' ...         
         'set(data.handles.popup(1),''Value'',' num2str(whichCmaps(1)) ');' ...
         'set(data.handles.popup(2),''Value'',' num2str(whichCmaps(2)) ');' ...
         'overlayVolumes(gcf);'];
 hm6 = uimenu(hm1,'Label','Set to default cmaps',...
              'Accelerator','6',...
              'Callback',cbstr);
          
cbstr = ['data = get(gcf,''UserData'');' ...         
         'set(data.handles.popup(1),''Value'',13);' ...
         'set(data.handles.popup(2),''Value'',14);' ...
         'overlayVolumes(gcf);'];
 hm7 = uimenu(hm1,'Label','Set to binary cmaps',...
              'Accelerator','7',...
              'Callback',cbstr);      
% setup data struct
data.vol1 = vol1;
data.vol2 = vol2;
data.backgnd = backgnd;
data.whichCmaps =  whichCmaps;
data.handles.fig = h;
data.handles.axes = hax;
data.handles.frames = [hf1 hf2];
data.handles.sliders = [hs1 hs2 hs3];
data.handles.edits = [he1 he2 he3];
data.handles.text = [ht1 ht2 ht3];
data.handles.popup = [hp1 hp2];
data.handles.toggle = [hc1 hc2];
data.handles.menu = [hm1 hm2];

% stash the data in the fig's userData
set(h,'UserData',data);

% refresh the view
overlayVolRefresh(h);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function overlayVolRefresh(h);
% refreshes the overlayVol fig specified by the handle h.
    
data = get(gcf,'UserData');
    
% I'm being a bit too sneaky here -- to allow using both a slider
% and edit field to update the current slice/thresh, I allow either
% the figure's handle, or the uicontrol's handle to be passed in.
% If it's an edit field callback, h will be a gcbo; otherwise,
% h will be gcf. (The reason I do this is to allow everything to 
% be contained in a single, simple m-file; maybe GUIDE will help in
% the future...?)
test = get(h,'Type');
if isequal(test,'uicontrol')    % edit callback
    % set the slider to the edit value
    whichEdit = find(data.handles.edits==h);
    slider = data.handles.sliders(whichEdit);
    newVal = str2num(get(h,'String'));
    set(slider,'Value',newVal);
end

slice = get(data.handles.sliders(1),'Value');
slice = round(slice);
set(data.handles.sliders(1),'Value',slice);

% ensure edit fields are set to the slider values
for i = 1:3
    val = get(data.handles.sliders(i),'Value');
    set(data.handles.edits(i),'String',sprintf('%2.2f',val));
end

% get the toggle options for each image
toggle1 = get(data.handles.toggle(1),'Value');
toggle2 = get(data.handles.toggle(2),'Value');
   
% initialize background image
if ~isempty(data.backgnd)
    bg = repmat(data.backgnd(:,:,slice),[1 1 3]);
else
    bg = zeros(size(data.vol1,1),size(data.vol1,2),3);
end

% parse the channel options
col1 = get(data.handles.popup(1),'Value');
col2 = get(data.handles.popup(2),'Value');
cmap1 = cmapLookup(col1);
cmap2 = cmapLookup(col2);

% apply thresholds to each volume
vol1 = data.vol1; 
vol2 = data.vol2;
thresh1 = get(data.handles.sliders(2),'Value');
thresh2 = get(data.handles.sliders(3),'Value');
vol1(vol1 < thresh1) = NaN;
vol2(vol2 < thresh2) = NaN;

im1 = vol1(:,:,slice);
im2 = vol2(:,:,slice);
ind1 = find(~isnan(im1));
ind2 = find(~isnan(im2));
im1(ind1) = round(normalize(im1(ind1),1,256));
im2(ind2) = round(normalize(im2(ind2),1,256));

% map each volume in the appropriate channel
img = NaN*ones(size(im1));
img = repmat(img,[1 1 3]);
for ch = 1:3
    tmp = img(:,:,ch);

    mask1 = find(~isnan(im1));
    mask2 = find(~isnan(im2));

    if toggle1==1 & toggle2==1 % show both
        tmp(union(mask1,mask2)) = 0;
        tmp(mask1) = tmp(mask1) + cmap1(im1(mask1),ch); % ./ 2;
        tmp(mask2) = tmp(mask2) + cmap2(im2(mask2),ch); % ./ 2;
    elseif toggle1==1 & toggle2==0 % show only im1
        tmp(mask1) = cmap1(im1(mask1),ch);
    elseif toggle1==0 & toggle2==1 % show only im2
        tmp(mask2) = cmap2(im2(mask2),ch);
    end        
        

    tmp(tmp > 1) = 1;
    
    img(:,:,ch) = tmp;
end

% add in background image
mask = isnan(img);
img(mask) = normalize(bg(mask),0,1);

% img = normalize(bg,0,1);
% tmp = img(:,:,1);
% tmp(ind1) = im1(ind1);
% img(:,:,1) = tmp;
% tmp = img(:,:,2);
% tmp(ind2) = im2(ind2);
% img(:,:,2) = tmp;

% display the image
imshow(img);

return
% /-----------------------------------------------------/ %




% /-----------------------------------------------------/ %
function cmap = cmapLookup(selection);
% A lookup for a color map from the cmap selection.
cmap = zeros(256,3);
switch selection
    case 1, cmap = gray(256);
    case 2, cmap(:,1) = linspace(0,1,256)'; % red
    case 3, cmap(:,2) = linspace(0,1,256)'; % green
    case 4, cmap(:,3) = linspace(0,1,256)'; % blue
    case 5,                                  % yellow
        cmap(:,1) = linspace(0,1,256)';
        cmap(:,2) = linspace(0,1,256)'; 
    case 6,                                  % purple
        cmap(:,1) = linspace(0,1,256)';
        cmap(:,3) = linspace(0,1,256)'; 
    case 7,                                  % cyan
        cmap(:,2) = linspace(0,1,256)';
        cmap(:,3) = linspace(0,1,256)'; 
    case 8, cmap = autumn(256); % autumn
    case 9, cmap = winter(256); % winter
    case 10, cmap = jet(256);   % jet
    case 11, cmap = hot(256);   % hot
    case 12, cmap = cool(256);  % cool
    case 13, cmap(:,1) = 256;    % red binary
    case 14, cmap(:,2) = 256;   % green binary
    case 15, cmap(:,3) = 256;   % blue binary
end
return
