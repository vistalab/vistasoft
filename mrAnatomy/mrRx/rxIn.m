function rx = rxIn(rx);
% 
% rx = rxIn(rx);
%
% For mrRx, nudge the prescription 'in' (along the vector pointing from 
% the middle of the last slice toward the middle of the first slice) a
% certain delta according to the value of the nudge slider.
%
% ras, 08/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

%%%%%get params
nudgeVal = get(rx.ui.nudge.sliderHandle,'Value')/6; % make a small nudge

%%%%%compute a vector pointing 'in'
% middle X, Y coords
midX = rx.rxDims(2)/2;
midY = rx.rxDims(1)/2;

% cols of coords are: middle of last slice, middle of first slice
coords(:,1) = [midX; midY; rx.rxDims(3)];
coords(:,2) = [midX; midY; 1];

% convert coords into volume coordinate space
volCoords = rx2vol(rx,coords);

% get vector as diff. b/w these two points
vec = diff(volCoords');

%%%%%modify translation accordingly
[trans rot scale skew] = affineDecompose(rx.xform);
trans = trans + nudgeVal.*vec;
newXform = affineBuild(trans,rot,scale,skew);
rx = rxSetXform(rx,newXform);

return
