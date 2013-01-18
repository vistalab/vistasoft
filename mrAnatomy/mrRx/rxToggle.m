function rxToggle(rx, nToggles, pauseForSecs);
% For mrRx: quickly toggle between a prescribed slice image and 
% a reference slice for comparison.
%
% rxToggle(rx, [nToggles=3]);
%
%
% ras, 01/06.
% ras, 05/09: added nToggles as an input parameter.
if ~exist('rx', 'var') | isempty(rx), 
    cfig = findobj('Tag', 'rxControlFig');
    rx = get(cfig, 'UserData');
end

if notDefined('pauseForSecs')
    pauseForSecs = 0.15;
end

if notDefined('nToggles')
	% # of times to alternate b/w interp and ref images
	nToggles = 3; 
end

[interp ref] = rxGetComparisonImages(rx);


if ishandle(rx.ui.compareAxes)
    axes(rx.ui.compareAxes)
else
    figure('Name', 'mrRx: rxToggle');
end 

rng = [min(interp(:)) max(interp(:))];

% get cur axis limits and keep them, in case user has zoomed image
x = get(gca, 'xlim');
y = get(gca, 'ylim');


for n = 1:nToggles
    imshow(ref, rng);
    xlim(x); ylim(y);
    pause(pauseForSecs);
    imshow(interp, rng);
    xlim(x); ylim(y);
    pause(pauseForSecs);
end

return
