function wedge = cmapWedge(cmap, startAngle, direction, params)
%  
%  wedge = cmapWedge(cmap or mrVista view, [startAngle], [direction], ...
%                            [visualField], [params])
%
%AUTHOR:  Wandell
%Purpose:
%    Make an image of the wedge map for mapping radial angle. If the
%    params.doPlot flag is set to 1, plot this image in a separate figure.
%
% Inputs:
%    First argument: can be a color map (3xN matrix) or a 
%       mrVista view. In the latter case, will extract the current color
%       map for the phase mode as a cmap.
%    startAngle: angle of stimulus at the start of each scan, in degrees
%                clockwise from 12-o-clock (upper vertical meridian).
%    direction: flag specifying direction of motion of stimulus: 
%               0 for clockwise, 1 for counterclockwise.
%    params: struct with settings about the image. If any fields are
%    omitted from this struct, the defaults are specified in brackets
%    below.
%        params.diameter -- diameter of the image in pixels. [256]
%        params.visualField -- extent of the visual field 
%               mapped by the experiment.
%               'r' for right, 'l' for left', or 'b' for both. ['b']
%        params.background -- background color for the image as an [R G B]
%               triplet [default [1 1 1]]
%        params.doPlot specifies whether or not to plot the image. (If
%           1, plots the image) [1]
%        params.trueColor specifies whether or not to convert the image
%           to truecolor [1]
%
%   If any of the last three arguments are omitted or empty, pops up
%   a dialog to get them all.
%   
% Outputs:
%   wedge: true color image of the wedge.
%
% UPDATED: ras 01/06/06, cleaned up argument specification, enabled code 
% to deal with counterclockwise phase precession, broke off core part in 
% a separate function (wedgeImage) which is not dependent on mrVista views.

% parse the first argument: it can be a mrVista view or a cmap
if isstruct(cmap) % assume it's a view
    cmap = getColorMap(cmap, 'ph', 1);
end

if notDefined('startAngle') | notDefined('direction') | notDefined('params')
    % go ahead and get all relevant parameters in a dialog
    [startAngle, direction, params] = cmapWedgeDialog;
end

% allow for the params struct to have missing fields: plug in default
% values.
if ~isfield(params, 'visualField'), params.visualField = 'b'; end
if ~isfield(params, 'diameter'), params.diameter = 512; end
if ~isfield(params, 'background'), params.background = [1 1 1]; end
if ~isfield(params, 'doPlot'), params.doPlot = 1; end
if ~isfield(params, 'trueColor'), params.trueColor = 1; end
params.visualField = lower(params.visualField(1)); % account for case

% figure out the horizontal phase based on the start angle and 
% visual field covered. The hPhase will be 90 degrees clockwise
% from the vertical meridian (as I like it specified), and map
% to 0 radians in the atan2 formula used to generate the wedge.
% The horizontal phase will specify how much, if any, we need to
% shift the current image to match the experimental design.
if direction==0, dirFlag = 1; else, dirFlag = -1; end
if ismember(params.visualField, {'l' 'r'})
    % only 180 degrees covered by each cycle
    hPhase = (90-startAngle) / dirFlag*0.5;    
else
    % 360 degrees covered by each cycle
    hPhase = (90-startAngle) / dirFlag;
end
phShift = deg2rad(hPhase);

% The above is based on the following simple model: y = mx + b,
% where y = polar angle being mapped,  x = phase within each cycle,
% m = slope = dirFlag*(visAngle covered per cycle/360), and b = startAngle
% I add an empirical 60-degree offset to account for rise time.

% % Place the map, which spans 2*pi, such that the hPhase is in the middle.
% % This will place the hPhase on the horizontal line.
nMap = size(cmap,1);
% phPerStep = nMap/(2*pi);
% sz = round(phShift*phPerStep);
% cmap = circshift(cmap, sz);

% Create a grid of (X,Y) values
nX = params.diameter; nY = params.diameter;
[X Y] = meshgrid(1:nX, 1:nY);

% Center the grid around (0,0)
X = X - (nX/2); Y = Y - (nY/2);

%  Find the angle for each of the X,Y points
wedge = zeros(size(X));
wedge = atan2(Y, X);

% Rotate angles so that the hPhase is at zero
wedge = shiftPhase(wedge, phShift);

% if the phases precess counterclockwise, flip it to be correct.
if direction==1, wedge = flipud(wedge); end

wedge = mrScale(wedge, 1, nMap);

% Add the background color.
bck = size(cmap, 1) + 1;
cmap(bck, :) = params.background;

% Pick out those locations that are outside the radius or angle.
% and set them to the background color.
dist = sqrt(X.^2 + Y.^2);
radius = params.diameter/2;
outRadius = (dist > radius);
wedge(outRadius) = bck;

% If only a hemifield is covered, set the image to the
% right or left visual field.
negX = (X < 0);
switch params.visualField
    case {'r'} % right
        wedge(negX) = bck;
        
    case {'l'} % left
        wedge(negX) = bck;
        wedge = fliplr(wedge);
        
    case {'b'} % both, do nothing
end

% convert image to truecolor
if params.trueColor==1, wedge = ind2rgb(round(wedge), cmap); end

% show the wedge if selected.
if params.doPlot==1, figure('Color', 'w'), imshow(wedge); end

return;
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function [startAngle, direction, params] = cmapWedgeDialog;
% [startAngle, direction, params] = cmapWedgeDialog;
% put up a dialog to get parameters for plotting the wedge image.
% set up dialog fields:
dlg(1).fieldName = 'startAngle';
dlg(1).style = 'edit';
dlg(1).string = ['Angle at start of cycle [in degrees clockwise ' ...
                 'from 12 o clock]?'];
dlg(1).value = '0';

dlg(2).fieldName = 'direction';
dlg(2).style = 'popup';
dlg(2).string = 'Which direction was the stimulus rotating?';
dlg(2).list = {'clockwise' 'counterclockwise'};
dlg(2).value = 1;

dlg(3).fieldName = 'visualField';
dlg(3).style = 'popup';
dlg(3).string = 'Visual Field covered?';
dlg(3).list = {'left' 'right' 'both'};
dlg(3).value = 3;

dlg(4).fieldName = 'diameter';
dlg(4).style = 'edit';
dlg(4).string = 'Diameter of image in pixels?';
dlg(4).value = '256';

dlg(5).fieldName = 'background';
dlg(5).style = 'edit';
dlg(5).string = 'Background color for image?';
dlg(5).value = '[1 1 1]';

dlg(6).fieldName = 'doPlot';
dlg(6).style = 'checkbox';
dlg(6).string = 'Plot wedge image in a figure';
dlg(6).value = 1;

% put up the dialog
params = generalDialog(dlg, 'Make Wedge Image');

% parse the response
startAngle = str2num(params.startAngle);
direction = cellfind(dlg(2).list, params.direction)-1;
params.diameter = str2num(params.diameter);
if isnumeric(str2num(params.background))
    params.background = str2num(params.background);
end

return


