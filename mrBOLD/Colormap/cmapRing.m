function [ring, cmap] = cmapRing(view, fovealPhase, visualField, ...
                                diameter, doPlot, background)
%  
%  [ring, cmap] = cmapRing(view, <fovealPhase, visualField, ...
%                                 diameter, doPlot, background>)
%
%AUTHOR:  Wandell
%Purpose:
%    Make an image of the ring map.  
%     fovealPhase says which phase should be in the middle of the image.
%     The visualField is 'r' (right), 'l' (left) or 'b' (both)
%     The diameter is the number of pixels across the image.
%
% Example:
%    fovealPhase = 3;   % colorbar at 2.4 is the middle of the image
%    [ring,mp] = cmapRing(FLAT{1},fovealPhase,'b',256,1);

mp = getColorMap(view,'ph',1);

if notDefined('visualField'), visualField = 'r'; end
if notDefined('diameter'), diameter = 256; end
if notDefined('background'), background = [1 1 1]; end
if notDefined('fovealPhase')
    prompt={'Enter color bar value for the most foveal phase:'};
    def={'3.14'};
    dlgTitle='Create ring map';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);
    if isempty(answer), return;
    else
        fovealPhase = str2num(answer{1});
    end
end

nX = diameter;  nY = diameter;  nMap = size(mp,1);

% Place the map, which spans 2*pi, such that the hPhase is in the middle.
% This will place the hPhase on the horizontal line.
%
phPerStep = nMap/(2*pi);
phShift = fovealPhase;
sz = round(phShift*phPerStep);
cmap = circshift(mp,-sz);

% Create a grid of (X,Y) values
[X Y] = meshgrid(1:nX,1:nY);

% Center the grid around (0,0)
X = X - (nX/2); Y = Y - (nY/2);

ring = sqrt(X.^2 + Y.^2);
l = (ring > (diameter/2));
ring(l) = -1;

% Scale the
ring = (size(cmap,1)/(diameter/2))*ring;


% figure; image(ring); colormap(cmap)

% Add the background color.
bck = size(cmap,1)+1;
cmap(bck,:) = background;
ring(ring<0) = size(cmap,1);



% Switch the image to the right or left visual field.
negX = (X < 0);
switch visualField
    case {'r','right'}
        ring(negX) = bck;
        
    case {'l','left'}
        ring(negX) = bck;
        ring = fliplr(ring);
        
    case {'b','both'}
end

if doPlot
    figNum = figure; image(ring), 
    axis image; colormap(cmap); axis off
    udata.cmap = cmap;
    udata.ring = ring;
    ring(ring==0) = 1;
    udata.imgRgb = reshape(cmap(round(ring),:), [size(ring), 3]);
    set(gca,'userdata',udata);
    disp(['ud=get(gca,''userdata''); imwrite(ud.imgRgb,''ringLegend.png'');']);
end


return;



