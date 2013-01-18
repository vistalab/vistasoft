function vw = renderCrosshairs(vw, on, method, color)
% 
% vw = renderCrosshairs(vw, <on, method, color>);
%
% Draw crosshairs on a mrVista window (currently only volume / gray
% 3-view, maybe we can generalize). Deletes any existing xhair lines.
%
% on: flag for whether to draw the crosshairs at the current location
% or just delete the old ones. <default: 1, draw them>
%
% method: flag for what method to use when drawing. Current options:
%   1: draw two intersecting lines.
%   2: draw lines with a gap between.
%   <default: check for preferred method, or else 1>
% 
% color: color ([R G B] triplet or single character) to use for the
% xhairs. <default: check for preferred color, or else [1 .5 .5]>
%
% 02/06 by ras. Different drawing methods Not Yet Implemented
if ~exist('on','var') || isempty(on), on = 1; end

if ~exist('method','var') || isempty(method)
    if ispref('VISTA', 'xHairMethod')
        method = getpref('VISTA', 'xHairMethod');
    else
        method = 2;
    end
end

if ~exist('color','var') || isempty(color)        
    if ispref('VISTA','xHairColor')
        color = getpref('VISTA','xHairColor');
    else
        color = [1 0.5 0.5];
    end
end

ui = vw.ui; loc = vw.loc;

%%%%%delete any existing lines
delete(findobj('Tag', 'xHairs', 'Parent', ui.sagAxesHandle));
delete(findobj('Tag', 'xHairs', 'Parent', ui.corAxesHandle));
delete(findobj('Tag', 'xHairs', 'Parent', ui.axiAxesHandle));

if on==1
    %%%%%draw the lines
    switch method
    case 1, % regular xhairs
        if isfield(ui,'flipLR') && ui.flipLR==1
            axes(ui.axiAxesHandle); %#ok<*MAXES>
            l(1) = line(size(vw.anat,3)-[loc(3) loc(3)], [1 size(vw.anat,2)], 'Color', color, 'Tag', 'xHairs');
            l(2) = line([1 size(vw.anat,3)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');
            axes(ui.corAxesHandle);
            l(3) = line(size(vw.anat,3)-[loc(3) loc(3)], [1 size(vw.anat,1)], 'Color', color, 'Tag', 'xHairs');
            l(4) = line([1 size(vw.anat,3)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        else
            axes(ui.axiAxesHandle);
            l(1) = line([loc(3) loc(3)], [1 size(vw.anat,2)], 'Color', color, 'Tag', 'xHairs');
            l(2) = line([1 size(vw.anat,3)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');
            axes(ui.corAxesHandle);
            l(3) = line([loc(3) loc(3)], [1 size(vw.anat,1)], 'Color', color, 'Tag', 'xHairs');
            l(4) = line([1 size(vw.anat,3)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        end

        if isfield(ui,'flipAP') && ui.flipAP==1
            axes(ui.sagAxesHandle);
            l(5) = line(size(vw.anat,2)-[loc(2) loc(2)], [1 size(vw.anat,1)], 'Color', color, 'Tag', 'xHairs');
            l(6) = line([1 size(vw.anat,2)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        else
            axes(ui.sagAxesHandle);
            l(5) = line([loc(2) loc(2)], [1 size(vw.anat,1)], 'Color', color, 'Tag', 'xHairs');
            l(6) = line([1 size(vw.anat,2)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        end
        
    case 2, % xhairs w/ gap
        gapSize = .05; % gap size as proportion of axis bounds
        AX = axis;
        d = [gapSize gapSize] .* [AX(4)-AX(3) AX(2)-AX(1)];
        sz = size(vw.anat);
        
        if isfield(ui,'flipLR') && ui.flipLR==1
            axes(ui.axiAxesHandle);                         % AXIAL XHAIR
            l(1) = line(sz(3)-[loc(3) loc(3)], [1 loc(2)-d(2)], 'Color', color, 'Tag', 'xHairs');
            l(2) = line(sz(3)-[loc(3) loc(3)], [loc(2)+d(2) sz(2)], 'Color', color, 'Tag', 'xHairs');
            l(3) = line([1 sz(3)-loc(3)-d(1)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');
            l(4) = line([sz(3)-loc(3)+d(1) sz(3)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');
            
            axes(ui.corAxesHandle);                         % CORONAL XHAIR
            l(5) = line(sz(3)-[loc(3) loc(3)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs');
            l(6) = line(sz(3)-[loc(3) loc(3)], [loc(1)+d(2) sz(1)], 'Color', color, 'Tag', 'xHairs');
            l(7) = line([1 sz(3)-loc(3)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
            l(8) = line([sz(3)-loc(3)+d(1) sz(3)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        else
            axes(ui.axiAxesHandle);                           % AXIAL XHAR
            l(1) = line([loc(3) loc(3)], [1 loc(2)-d(2)], 'Color', color, 'Tag', 'xHairs');    % 2 X lines
            l(2) = line([loc(3) loc(3)], [loc(2)+d(2) sz(2)], 'Color', color, 'Tag', 'xHairs');            
            l(3) = line([1 loc(3)-d(1)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');    % 2 Y lines
            l(4) = line([loc(3)+d(1) sz(3)], [loc(2) loc(2)], 'Color', color, 'Tag', 'xHairs');
            
            axes(ui.corAxesHandle);                           % CORONAL XHAIR
            l(5) = line([loc(3) loc(3)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs'); % 2 X lines
            l(6) = line([loc(3) loc(3)], [loc(1)+d(2) sz(1)], 'Color', color, 'Tag', 'xHairs');
            l(7) = line([1 loc(3)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs'); % 2 Y lines
            l(8) = line([loc(3)+d(1) sz(3)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        end

        if isfield(ui,'flipAP') && ui.flipAP==1
            axes(ui.sagAxesHandle);                           % SAGITTAL XHAIR
            l(9)  = line(sz(2)-[loc(2) loc(2)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs');
            l(10) = line(sz(2)-[loc(2) loc(2)], [loc(1)+d(2) sz(1)], 'Color', color, 'Tag', 'xHairs');
            l(11) = line([1 sz(2)-loc(2)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
            l(12) = line([sz(2)-loc(2)+d(1) sz(2)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        else
            axes(ui.sagAxesHandle);                           % SAGITTAL XHAIR 
            l(9)  = line([loc(2) loc(2)], [1 loc(1)-d(2)], 'Color', color, 'Tag', 'xHairs');
            l(10) = line([loc(2) loc(2)], [loc(1)+d(2) size(vw.anat,1)], 'Color', color, 'Tag', 'xHairs');
            l(11) = line([1 loc(2)-d(1)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
            l(12) = line([loc(2)+d(1) sz(2)], [loc(1) loc(1)], 'Color', color, 'Tag', 'xHairs');
        end        

    case 3, % + sign

    case 4, % circle

    end
    
%     set(l, 'Color', color, 'Tag', 'xHairs');    
else
    l = [];
end

vw.ui.xHairHandles = l;

return
