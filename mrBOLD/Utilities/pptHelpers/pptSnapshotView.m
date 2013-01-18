function h = pptSnapshotView(pptFile, view, verbose);
% Export a snapshot of a mrVista 1 View Window into a powerpoint file.
% Windows only. 
%
% USAGE:
%	figHandle = pptSnapshotView([pptFile], [view], [verbose=2]);
%
% INPUTS:
%	pptFile: path of the PowerPoint file to which the image should
%			 be exported. If this file doesn't exist, it is created;
%			 if it exists, a new slide is appended to it.
%			 [if omitted, can select with a dialog].
%	view:	 mrVista 1 view. Default: use 'getCurView' function.
%	verbose: flag to indicate the level of descriptive detail 
%			 to include in the exported image. These levels are
%			 implemented:
%			 0: export only the main images in the window.
%			 1: Add colorbar, annotation text describing the session, 
%				data type, scans.
%			 2: Add further annotation describing the thresholding, data
%				map, etc. [default]
%
% OUTPUTS:
%	h: figure handle to the figure created for export purposes.
%
% Requires the VISTASOFT toolbox.
%
% ras, 07/2007.
if ~ispc
	%% exit quietly (don't want to break scripts)
	warning('Sorry, pptSnapshotView is only supported for Windows right now.');
	return
end

if notDefined('pptFile')
	msg = 'Select a PowerPoint File to which to export the view image...';
	pptFile = mrvSelectFile('w', 'ppt', '', msg);
end

if notDefined('view'),		view = getCurView;		end
if notDefined('verbose'),	verbose = 2;			end

switch view.viewType
	case 'Inplane'
		h = pptSnapshotInplane(pptFile, view, verbose);
		
	case {'Volume' 'Gray' 'generalGray'}
		error('Sorry, not yet implemented');
		
	case 'Flat'
		error('Sorry, not yet implemented');
end

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function h = pptSnapshotInplane(pptFile, view, verbose);
% Specialized subfunction for inplane views.
if checkfields(view, 'ui', 'image')
	img = view.ui.image;
	displayMode = view.ui.displayMode;
else
	% hidden views
	if ~checkfields(view, 'ui', 'displayMode')
		fprintf('[%s]: No display mode specified.  Defaulting to map...', mfilename);
		displayMode = 'map';
	end
		
	if ~checkfields(view, 'ui', [displayMode 'mode'])
		% use defaults 
		mode.displayMode = displayMode;
	else
		mode = view.ui.(displayMode);
	end
	img = inplaneMontage(view, [], mode);
end

%% put up the figure, main image
h = figure('Color', 'w', 'Units', 'Norm', 'Position', [.1 .1 .6 .6]);
imagesc(img);  axis image;  axis off;
colormap( viewGet(view, 'cmap') );

%% add annotation if needed
if verbose >= 1
	txt = annotation(view);
	if verbose >= 2
		% threshold info
		txt2 = sprintf('Cothresh %0.2f, Phase Window [%s], Map Window [%s]', ...
					  viewGet(view, 'Cothresh'), ...
					  num2str(viewGet(view, 'PhWin')), ...
					  num2str(viewGet(view, 'MapWin')));

		% which slices
		slices = viewGet(view, 'MontageSlices');
		txt3 = ['Slices: ' num2str(slices)];
				  
		txt = sprintf('%s \n%s \n%s', txt, txt2, txt3);
	end
	title(txt, 'FontSize', 12);
end

%% add colorbar, ROI legends if needed
if verbose >= 1
	addCbarLegend(view, h);
	addROILegend(view, h);
end

%% Paste into ppt
[ppt op] = pptOpen(pptFile);

if verbose==0
	% paste without a title
	pptPaste(op, h, 'meta');
else
	% add a title
	ttl = sprintf('Inplane, Session %s %s %i ', ...
				   viewGet(view, 'SessionCode'), ...
				   viewGet(view, 'DataTypeName'), ...
				   viewGet(view, 'CurScan'));
	pptPaste(op, h, 'meta', ttl);
end

pptClose(op, ppt, pptFile);

return
		