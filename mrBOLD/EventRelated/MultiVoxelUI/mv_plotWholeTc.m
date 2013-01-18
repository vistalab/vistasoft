function mv = mv_plotWholeTc(mv, imgFlag, nVox, firstVoxel);
%
%  mv = mv_plotWholeTc(mv, [imgFlag=0], [nVox=10]);
%
% Plot the whole time course for each
% voxel (for MultiVoxel UI).
%
% imgFlag: determines the visualization:
%		imgFlag==1: use imagesc and show a single color-coded image
%				    of the time series signal across all voxels;
%		imgFlag==0: plot each trace separately using subplots. 
%					In this case, up to nVox voxels are shown 
%					in a column, with buttons to page through
%					voxels, and 
%
% [Default is 0, individual time series as subplots]
%
% For the imgFlag==0 condition, the optional nVox argument
% determines the maximum number of separate voxel subplots to
% show
%
% ras, 04/05.
if notDefined('mv'),    mv = get(gcf,'UserData');   end
if notDefined('imgFlag'),		imgFlag = 1;        end


%% delete existing axes
other = findobj('Type', 'axes', 'Parent', gcf);
delete(other);

axes('Position', [.15 .15 .7 .7]);

tr = mv.params.framePeriod;

if imgFlag==1
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Show Image of all voxels %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
    % plot the data in units of secs V voxels
    t = tr .* (1:size(mv.tSeries, 1));
    v = 1:size(mv.tSeries, 2);

    imagesc(v, t, mv.tSeries);
    colormap(mv.params.cmap);
    colorbar vert
    xlabel('[Voxel]', 'FontSize', mv.params.fontsz,...
           'FontName', mv.params.font);
    ytxt = sprintf('Scan Time [sec]', tr);
    ylabel(ytxt,'FontSize', mv.params.fontsz,...
           'FontName', mv.params.font);

    title('BOLD signal [% modulation]','FontName',mv.params.font,...
            'FontSize',mv.params.fontsz);
		
else
	%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Individual subplots GUI %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if notDefined('nVox'),			nVox = 10;			end
	if notDefined('firstVoxel'),	firstVoxel = 1;		end
	
	font = mv.params.font;
	fontsz = mv.params.fontsz;
	
	%% Create the main plots
	% figure out which voxels to plot
	totalVoxels = size(mv.coords, 2); 
	if nVox >= totalVoxels 
		nVox = totalVoxels;  % can only show this many
		makePageButtons = 0;  % no buttons to page through voxels below
	else
		makePageButtons = 1;
	end
	
	% figure out height of each subplot
	height = .8 / nVox;
	
	% get time samples for time series
	nFrames = size(mv.tSeries, 1);
	t = [0:nFrames-1] .* mv.params.framePeriod;
	
	% plot each time series
	for n = 1:nVox
		h(n) = subplot('Position', [.1 (1-n*height*.95) .5 height]);
		
		voxel = firstVoxel + n - 1;
		
		plot(t, mv.tSeries(:,voxel), 'Color', 'k', 'LineWidth', 1.5);
		
		if n==nVox
			xlabel('Time, s', 'FontName', font, 'FontSize', fontsz);
			ylabel('% Signal', 'FontName', font, 'FontSize', fontsz);
		else
			axis off
		end
	end
	
	%% set each axis to be consistent, report on each voxel location
	AX = normAxes(h);
	for n = 1:nVoxels
		subplot(h(n));
		voxel = firstVoxel + n - 1;		
		txt = sprintf('Voxel %i, Coords %s', voxel, ...
					  num2str(mv.coords(:,voxel)));
		text(t(2), AX(4), txt, 'FontName', font, 'FontSize', 9);
	end
	
	%% Create the GUI elements
	% scrollbar 
	if nFrames > 300
		cb = ['tmp = get(gcbo, ''UserData''); ' ...
			  'axis(tmp, [val val+300 ' num2str(AX(3:4)) ']); ' ...
			  'clear tmp '];
		mv.ui.tSeriesScroll = uicontrol('Style', 'slider', ...
			'Units', 'norm', 'Position', [.15 .1 .5 height], ...
			'Min', 0, 'Max', nFrames-300, ...
			'UserData', h, 'Callback', cb);
		
		mv.ui.tSeriesUnzoon = uicontrol('Style', 'pushbutton', ...
			'Units', 'norm', 'Position', [.1 .1 .05 height], ...
			'String', 'UnZoom', 'UserData', h, ...
			'Callback', 'axis(get(gcbo, ''UserData''), ''auto'')');			
	end
	
	% Voxel paging
	
end

return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function mv_plotWholeTc_voxPlot(mv, nVox);
%%%%% update the single-voxel subplot display.

return