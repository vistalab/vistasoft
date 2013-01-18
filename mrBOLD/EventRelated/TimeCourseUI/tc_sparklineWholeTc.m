function tc = tc_sparklineWholeTc(tc);
%
% tc = tc_sparklineWholeTc(tc);
%
% An attempt to visualize a whole time course using
% Edward Tufte's sparkline method. 
%
% ras, 01/2007.
if notDefined('tc'),    tc = get(gcf, 'UserData');      end

%% clear previous objects in figure
delete( findobj('Parent', tc.ui.plot) ); 

%% get time vector t in seconds
nFrames = length(tc.wholeTc);
t = [0:nFrames-1] .* tc.params.framePeriod;

%% plot time course in small axes
axes('Parent', tc.ui.plot, 'Units', 'norm', 'Position', [.1 .6 .65 .3]);    
plot(t, tc.wholeTc, 'k');               
hold on, axis off;
AX = axis;
w = AX(2) - AX(1);  % width
h = AX(4) - AX(3);  % height

%% add time point annotation underneath the time course
% mark only a few salient time points
nPoints = 8;
pts = [t(1) t(mod(t,100)==0) t(end)];
pts = pts( round( linspace(1, length(pts), nPoints) ) );
pts = unique(pts);

for p = pts
    f = find(t==p);
    plot(p, tc.wholeTc(f), 'r.');
    if p==pts(1)
        txt = sprintf('t = %i s', p);
    else
        txt = num2str(p);
    end
    text(p, -0.33*h, txt, 'FontName', 'Helvetica', ...
         'FontSize', 9, 'HorizontalAlignment', 'center');
end

%% add color bars indicating condition underneath the text annotation
cond = er_resample(tc.trials.onsetSecs, tc.trials.cond, t);
for i = 1:length(tc.trials.condColors)
    cmap(i,:) = colorLookup(tc.trials.condColors{i});
end
cmap(1,:) = [1 1 1];
condImg = ind2rgb(repmat(cond(:)'+1, 2, 1), cmap);
image(t, min(tc.wholeTc)-.2*h, condImg);
% axis([AX(1:2) AX(3)-h AX(4)])

% % add a scrollbar
% scrollbar(gca, tc.wholeTc);

return



% The # of samples we show per row depends on the current 
% aspect ratio of the figure. (Although the user can
% resize it, we want it to look nice in the figure as given.)
pos = get(gcf, 'Position');
rFig = pos(3) / pos(4);  % xSize / ySize