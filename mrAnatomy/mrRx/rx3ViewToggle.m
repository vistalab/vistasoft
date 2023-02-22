function rx = rx3ViewToggle(rx, nToggles, views);
% Toggle between the interpolated and reference slices for the 3 view axes
% in the interpolated 3-view figure.
%
%  rx = rx3ViewToggle(rx, [nToggles=3], [views=1:3]);
%
%
% ras, 05/05/2009.
if ~exist('rx', 'var') | isempty(rx)
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if notDefined('nToggles')
    % # of times to alternate b/w interp and ref images
    nToggles = 3;
end

if notDefined('views')
    % which of the 3 view windows to toggle
    views = 1:3;
end

%% get position from UI controls
for i = 1:3
    loc(i) = str2num( get(rx.ui.interpLoc(i), 'String') );
end


for ori = views
    % get interpolated image
    interp = rxInterpSlice(rx, loc(ori), ori);

    % get reference image
    switch ori
        case 1, ref = squeeze( rx.ref(loc(ori),:,:) );
        case 2, ref = squeeze( rx.ref(:,loc(ori),:) );
        case 3, ref = rx.ref(:,:,loc(ori));
    end

    % adjust contrast, brightness, etc.
    [interp ref] = rxGetComparisonImages(rx, interp, ref);


    if ishandle(rx.ui.interp3ViewAxes(ori))
        axes(rx.ui.interp3ViewAxes(ori))
    else
        figure('Name', ['mrRx: ' mfilename]);
    end

    rng = [min(interp(:)) max(interp(:))];

    % get cur axis limits and keep them, in case user has zoomed image
    x = get(gca, 'xlim');
    y = get(gca, 'ylim');

    for n = 1:nToggles
        imshow(ref, rng);
        xlim(x); ylim(y);
        pause(0.15);
        imshow(interp, rng);
        xlim(x); ylim(y);
        pause(0.15);
    end

    % if n toggles is 0, just switch the view to the reference image
    if nToggles < 1,
        imshow(ref, rng);
        xlim(x); ylim(y);
    end
end

return
