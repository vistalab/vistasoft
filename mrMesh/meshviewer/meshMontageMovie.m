function M = meshMontageMovie(V, whichMeshes, movieFileName, timeSteps, plotFlag, stimImages)
%
%   M = meshMontageMovie([gray view], [whichMeshes], [movieFileName], [timeSteps=12], [plotFlag=1], [stimImages])
%
%Author: Wandell
%Purpose:
%   Create a movie consisting of a montage of mesh images, each showing
%	the fundamental component of the time series based on the coherence 
%	and phase measurement ('corAnal').
%
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
if notDefined('plotFlag'),	plotFlag = 1;				end
if notDefined('timeSteps'), timeSteps = 12;				end
if notDefined('movieFileName'), movieFileName = '';		end
if notDefined('stimImages'),	stimImages = [];		end

% check that meshes are loaded
if ~checkfields(V, 'mesh')
	error('View must have a mesh loaded.')
end

if isequal(timeSteps, 'dialog') | isequal(movieFileName, 'dialog') | ...
		isequal(V, 'dialog') | notDefined('whichMeshes')
	whichMeshes = 1;
	[whichMeshes, timeSteps, movieFileName, plotFlag] = ...
		readParameters(V, whichMeshes, timeSteps, movieFileName, plotFlag);
end

% Make sure the cor anal data are loaded
if isempty(viewGet(V, 'co')),  V=loadCorAnal(V); end

msh = viewGet(V, 'currentmesh');

%% params 
roiFlag = -1;

if roiFlag==0
	% hide ROIs
	V.ui.showROIs = 0;
end

% Set up the co or amp values for the movie.  We replace the colors within
% the dataMask with the new colors generated here.
curScan = viewGet(V, 'currentscan');
realCO = viewGet(V, 'scanco', curScan);
ph = viewGet(V, 'scanph', curScan);

t = ([0:(timeSteps-1)]/timeSteps) * 2 * pi;
nFrame = length(t);

clear M;
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

%% loop across frames
for ii=1:nFrame
	if verbose		% udpate mrvWaitbar
		str = sprintf('Creating frame %.0f of %.0f', ii, nFrame);
		fname{ii} = sprintf('Movie%0.4d.tiff', ii);
		mrvWaitbar(ii/nFrame, wbar, str);
	end
    
	% compute the projected coherence relative to this time point
    data = realCO.*(1 + sin(t(ii) - ph))/2;
    V = viewSet(V, 'scancoherence', data, curScan);
    
	%% loop across meshes
	for n = 1:length(whichMeshes)
		% select the current mesh
		V.meshNum3d = whichMeshes(n);
		
		% update the mesh view with the colors for this time step
		meshColorOverlay(V, 1);

		meshImg{n} = mrmGet(V.mesh{whichMeshes(n)}, 'screenshot') / 255;
	end
	
	% add a stimulus image if it's provided
	if ~isempty(stimImages)
		meshImg{length(whichMeshes)+1} = stimImages(:,:,:,ii);
	end
	
	% grab the montage image (across meshes) for this frame
    M(:,:,:,ii) = imageMontage(meshImg, 1, 3);
end

if verbose, mrvWaitbar(1, wbar); close(wbar); end

%% show the movie in a separate figure
if plotFlag==1
	mov = mplay(M, 4);
	mov.loop
	mov.play
end

if ~isempty(movieFileName)
	% allow the movie path to specify directories that don't yet exist
	% (like 'Movies/')
	ensureDirExists( fileparts(fullpath(movieFileName)) );
	
	try
		if(isunix)
			aviSave(M, movieFileName, 'FPS', 3, 'compression',  'none');
		else
			aviSave(M, movieFileName, 'FPS', 3, 'QUALITY', 100, ...
						'compression',  'Indeo5'); 
		end
		fprintf('Saved movie as avi file: %s\n', [pwd, filesep, movieFileName]);
	catch
		disp('Couldn''t save AVI file: last error: ')
		disp(lasterr);
	end
end

return;

%------------------------------------
function [whichMeshes, timeSteps, movieFileName, plotFlag] = ...
	readParameters(V, whichMeshes, timeSteps, movieFileName, plotFlag);
%
% read parameters for meshMontageMovie
%
for n = 1:length(V.mesh)
	meshList{n} = V.mesh{n}.name;
end
dlg(1).fieldName = 'whichMeshes';
dlg(1).style = 'listbox';
dlg(1).list = meshList;
dlg(1).string = 'Use which meshes for movie?';
dlg(1).value = whichMeshes;

dlg(2).fieldName = 'timeSteps';
dlg(2).style = 'number';
dlg(2).string = 'Number of time frames for movie?';
dlg(2).value = num2str(timeSteps);

dlg(3).fieldName = 'movieFileName';
dlg(3).style = 'filenamew';
dlg(3).string = 'Name of AVI movie file? (Empty for no movie file)';
dlg(3).value = movieFileName;

dlg(4).fieldName = 'plotFlag';
dlg(4).style = 'checkbox';
dlg(4).string = 'Show movie in a MATLAB figure?';
dlg(4).value = plotFlag;

[resp ok] = generalDialog(dlg, 'Mesh movie options');

if ~ok
	error(sprintf('%s aborted.', mfilename));
end

timeSteps = resp.timeSteps;
movieFileName = resp.movieFileName;
plotFlag = resp.plotFlag;
[meshNames whichMeshes] = intersectCols(meshList, resp.whichMeshes);

return;

