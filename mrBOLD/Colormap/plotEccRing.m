function [h, img] = plotEccRing(view,direction,maxEccentricity,bgColor, showColorbar);
%
% [h, img] = plotEccRing(view,direction,maxEccentricity,bgColor, shoColorbar);
%
% Plot a ring denoting eccentricities represented by a phase
% map for a mrVista 1.0 view. 
%
% view: 
%   the view. Defaults to current inplane.
% direction: 
%   'in' or 'out', depending on whether the ring was
% contracting or expanding. 
%   [Default is 'out']
% maxEccentricity: 
%   max angle, in degrees, subtended by the outer edge
%   of the largest ring. Will assume the eccentricity maps linearly
%   from 0 to this value. If not specified, won't specify angle values,
%   otherwise will mark the eccentricities on a colorbar.
% bgColor: 
%   background color of figure. Default [1 1 1], white.
% shoColorbar:  
%   if true, also include a color bar with units; otherwise just the circle
%
% ras, 09/2005.

if ieNotDefined('view'), view = getSelectedInplane; end

if ieNotDefined('direction') | ieNotDefined('bgColor')
    % dialog
    dlg(1).fieldName = 'direction';
    dlg(1).style = 'popup';
    dlg(1).string = 'Ring Direction?';
    dlg(1).list = {'in' 'out'};
    dlg(1).value = 2;
    
    dlg(2).fieldName = 'maxEccentricity';
    dlg(2).style = 'edit';
    dlg(2).string = 'Max Stimulus Eccentricity (deg)?';
    dlg(2).value = '28.5';
    
    dlg(3).fieldName = 'bgColor';
    dlg(3).style = 'edit';
    dlg(3).string = 'Figure Background Color?';
    dlg(3).value = '[1 1 1]';

    dlg(4).fieldName = 'showColorbar';
    dlg(4).style = 'checkbox';
    dlg(4).string = 'Show colorbar legend?';
    dlg(4).value = 1;
    
    resp = generalDialog(dlg,'Plot Eccentricity Rings');
    direction = resp.direction;
    maxEccentricity = str2num(resp.maxEccentricity);
    bgColor = str2num(resp.bgColor);
    showColorbar = resp.showColorbar;
end

if notDefined('showColorbar'), showColorbar = true; end

numGrays = view.ui.phMode.numGrays;
cmap = [view.ui.phMode.cmap(numGrays+1:end,:); bgColor];
if strncmp(lower(direction),'out',2)==1
    cmap(1:end-1,:) = flipud(cmap(1:end-1,:));
end
[img mp] = ringMap(cmap, 256, 1, 2);

figure('Color',bgColor,'Units','Normalized','Position',[.6 .8 .2 .15]); 
if showColorbar, 
    subplot('Position',[.05 .05 .75 .9]); 
    image(img); colormap(mp); axis off; axis equal;
else
    image(img); colormap(mp); axis off; axis equal;
    return;
end


if exist('maxEccentricity','var')
    hold on
    ecc = linspace(0,maxEccentricity,6);
    htmp = subplot('Position',[.9 .2 .06 .6]);
    N = size(mp,1)-1;
    image([1:N]'); 
    eccTicks = linspace(1,N,6);
    set(htmp,'XTick',[],'YTick',eccTicks,'YTickLabel',ecc);
    ylabel('Eccentricity, degrees','FontSize',12,'FontWeight','bold');
end

return
