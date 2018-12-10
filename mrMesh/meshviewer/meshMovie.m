function M = meshMovie(V, roiFlag, movieFileName, timeSteps, plotFlag)
%
%   M = meshMovie([gray view], [roiFlag=-1], [movieFileName], [timeSteps=12], [plotFlag=1])
%
%Author: Wandell
%Purpose:
%   Create a movie of the fundamental component of the time series based on
%
%   the coherence and phase measurement. 
%   This is not the real time series,  but just a signal-approximation.
%   At some point,  we should read in the time series and show it frame by
%   frame.  I am not quite sure how to do this.  We don't normally get a
%   time-slice over space.  But I am guessing we could do it.
% 
%	roiFlag: flag indicating whether to illustrate a disc ROI during the
%	movie. If this flag is set to zero, no ROI will be shown. If it is
%	greater than 0, the value is taken to be the radius of the ROI disc
%	around the mesh cursor (those 3-axes things you get when
%	double-clicking on the mesh). If it is set to -1, all ROIs currently
%	defined in the view will be shown. 
%
% Example:  To make a movie with 10 steps, write out an AVI file called scratch, 
% and to return a Matlab movie structure,  M,  within the constraints of the 
% cothresh and ROI parameters,  use: 
%
%     M = meshMovie([], [], 'scratch', 10, 0);
%
% To get the last 3 arguments from a dialog, use:
%	M = meshMovie('dialog');
%		or
%	M = meshMovie(gray, [], 'dialog');
%
% ras 04/2008: modularized this more. Added view as an inputtable argument,
% instead of that VOUME{selectedVOLUME} stuff, added the roiFlag so you
% don't always need an ROI, and had the code only throw up a dialog if you
% didn't already give it the parameters it needs.
% ras 07/2008: added plot flag, updated calling of parameters dialog.
if notDefined('V'),			V = getSelectedGray;		end
if notDefined('roiFlag'),	roiFlag = -1;				end
if notDefined('plotFlag'),	plotFlag = 1;				end
if notDefined('timeSteps'), timeSteps = 12;				end

if isequal(timeSteps, 'dialog') | isequal(movieFileName, 'dialog') | ...
		isequal(V, 'dialog')
	[timeSteps, movieFileName, plotFlag] = readParameters(12, 'Movies/Scratch', 1);
end

% Make sure the cor anal data are loaded
if isempty(viewGet(V, 'co')),  V=loadCorAnal(V); end

msh = viewGet(V, 'currentmesh');

if roiFlag==0
	% hide ROIs
	V.ui.showROIs = 0;
elseif roiFlag > 0
	% mask in ROI
	pos = meshCursor2Volume(V,  msh);
	if isempty(pos) | max(pos(:)) > 255,  
		myWarnDlg('Problem reading cursor position.  Click and try again.');
		return
	end
	
	% Build an ROI of the right size.
	roiName = sprintf('mrm-%.0f-%.0f-%.0f', pos(1), pos(2), pos(3));
	[V discROI] = makeROIdiskGray(V, roiFlag, roiName, [], [], pos, 0);
	V.ROIs = discROI;
	V.ui.showROIs = -1;  % show only this, selected ROI
end

if roiFlag > 0
	% Create a view with the ROI defined.  It will sit in the window for a
	% moment.
	[V, roiMask, junk, roiAnatColors] = meshColorOverlay(V, 0);
	if sum(roiMask) == 0,  error('Bad roiMask'); end
	msh = mrmSet(msh, 'colors', roiAnatColors');
end



% Set up the co or amp values for the movie.  We replace the colors within
% the dataMask with the new colors generated here.
curScan = viewGet(V, 'currentscan');
realCO = viewGet(V, 'scanco', curScan);
ph = viewGet(V, 'scanph', curScan);

t = ([0:(timeSteps-1)]/timeSteps) * 2 * pi;
nFrame = length(t);

mrmSet(msh, 'hidecursor');

verbose = prefsVerboseCheck;
if verbose
	str = sprintf('Creating %.0f frame movie', nFrame);
	wbar = mrvWaitbar(0, str);
end

% change the view to display the coherence field, since we're actually
% displaying phase-projected coherence for each time point:
% I specificially make this change without calling setDisplayMode, because
% that accessor function will try to do concurrent GUI things like setting
% a colorbar and loading/clearing data fields. We don't want to do this,
% because we're treating the view V as a local variable; changes we make to
% V are not intended to propagate back to the GUI. So, if the user was e.g.
% looking at a coherence map before this, we don't want him/her to suddenly
% see the phase-projected data from the movie.
V.ui.displayMode = 'co';  

for ii=1:nFrame
	if verbose		% udpate mrvWaitbar
		str = sprintf('Creating frame %.0f of %.0f', ii, nFrame);
		fname{ii} = sprintf('Movie%0.4d.tiff', ii);
		mrvWaitbar(ii/nFrame, wbar, str);
	end
    
	% compute the projected coherence relative to this time point
    data = realCO.*(1 + sin(t(ii) - ph))/2;
    V = viewSet(V, 'scancoherence', data, curScan);
    
	% update the mesh view with the colors for this time step
	if roiFlag > 0
	    [V, roiMask, foo, newColors] = meshColorOverlay(V, 0);
	    msh = mrmSet(msh, 'colors', newColors');
		
	    roiAnatColors(1:3, logical(roiMask)) = newColors(1:3, logical(roiMask));
		msh = mrmSet(msh, 'colors', roiAnatColors');
	else
	    meshColorOverlay(V, 1);
	end
    
    M(:,:,:,ii) = mrmGet(msh, 'screenshot') / 255;
end

if verbose, mrvWaitbar(1, wbar); close(wbar); end

%% show the movie in a separate figure
if plotFlag==1
	% show in MPLAY utility
	mov = mplay(M, 3);
	mov.loop;
	mov.play;
elseif plotFlag==2
	% show in figure (old way)
	for ii = 1:size(M, 4)
		mov(ii) = im2frame(M(:,:,:,ii));
	end
	h = figure('Color', 'w', 'UserData', M); 
	imagesc(img); axis image; axis off;
	movie(mov, 5, 4)
end

if ~isempty(movieFileName)
	% allow the movie path to specify directories that don't yet exist
	% (like 'Movies/')
	ensureDirExists( fileparts(fullpath(movieFileName)) );
	
    fprintf('Saving movie as avi file: %s\n', [pwd, filesep, movieFileName]);
    if(isunix)
        aviSave(M, movieFileName, 3, 'compression',  'none');
    else
        aviSave(M, movieFileName, 3, 'QUALITY', 100, 'compression',  'Indeo5'); 
    end
end

return;

%------------------------------------
function [timeSteps, movieFileName, plotFlag] = readParameters(timeSteps, movieFileName, plotFlag);
%
% read parameters for meshMovie
%
dlg(1).fieldName = 'timeSteps';
dlg(1).style = 'number';
dlg(1).string = 'Number of time frames for movie?';
dlg(1).value = num2str(timeSteps);

dlg(2).fieldName = 'movieFileName';
dlg(2).style = 'filenamew';
dlg(2).string = 'Name of AVI movie file? (Empty for no movie file)';
dlg(2).value = movieFileName;

dlg(3).fieldName = 'plotFlag';
dlg(3).style = 'popup';
dlg(3).list = {'Don''t plot' 'Use MPLAY movie player' 'Movie in figure'};
dlg(3).string = 'Show movie in a MATLAB figure?';
dlg(3).value = plotFlag+1;

[resp ok] = generalDialog(dlg, 'Mesh movie options');

if ~ok
	error(sprintf('%s aborted.', mfilename));
end

timeSteps = resp.timeSteps;
movieFileName = resp.movieFileName;
plotFlag = cellfind(dlg(3).list, resp.plotFlag) - 1;

return;

