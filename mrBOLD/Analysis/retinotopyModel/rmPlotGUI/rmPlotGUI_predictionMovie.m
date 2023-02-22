function mov = rmPlotGUI_predictionMovie(M, aviFile, fps);
% Animate a movie of the stimulus sweeping across the pRF, and the
% predicted response, for the selected voxel in the rm Plot GUI.
%
%  mov = rmPlotGUI_predictionMovie([M], [aviFile], [fps=6]);
%
% INPUTS:
%	M: rmPlotGUI struct. [default: get from cur fig]
%
%	aviFile: optional .avi file to save the movie. [if not path provided,
%	won't save an .avi file.]
%
%	fps: frames per second for the avi movie (default: 6)
%
% OUTPUTS:
%	mov: movie structure. See GETFRAME.
%
% ras, 05/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end
if notDefined('aviFile'),	aviFile = '';					end
if notDefined('fps'),		fps = 6;						end

%% get the prediction for this voxel
v = get(M.ui.voxel.sliderHandle, 'Value');
coords = M.coords(:,v);
if isequal(M.roi.viewType, 'Gray')  % convert coords into an index
    coords = M.coords(v);
end
[pred RF rfParams variance_explained] = rmPlotGUI_makePrediction(M, coords);

%% create the animation, get the frames
nFrames = size(M.tSeries, 1);

for n = 1:nFrames
	%% plot the time series up to this frame
	axes(M.ui.tsAxes); cla; hold on;

    % We can either plot a static time series and growing prediction...
    % 	hTSeries = plot(M.x, M.tSeries(:,v), 'k--', 'LineWidth', 1.5);
    % 	hFit = plot(M.x(1:n), pred(1:n,1), 'b', 'LineWidth', 2);

    % Or a static prediction and a growing time series (my preference - jw)
    hTSeries = plot(M.x, M.tSeries(:,v), 'k--', 'LineWidth', 1.5);
	hFit = plot(M.x(1:n), pred(1:n,1), 'b', 'LineWidth', 2);

    % Don't plot the residual - too much clutter (jw)
    % 	hResidual = plot(M.x(1:n), M.tSeries(1:n,v)-pred(:,1), 'r:', 'LineWidth', 1);

	allPlotted = [M.tSeries(:,v); pred(:,1); M.tSeries(:,v)-pred(:,1)];
	axis([min(M.x) max(M.x) min(allPlotted) max(allPlotted)]);
	h = axis;
% 	for n=1:numel(M.sepx),
% 		plot([1 1].*M.sepx(n), [h(3) h(4)], 'k:', 'LineWidth', 2);
% 	end;
	xlabel('Time (sec)');
	ylabel('BOLD signal change (%)');

	%% show the stimulus position over the pRF for this frame
	TR = M.params.stim(1).framePeriod;  % TODO: deal w/ diff't TRs in diff't scans	
	t = get(M.ui.time.sliderHandle, 'Value') * TR;
		
	% get the stimulus image for this frame
	[stimImage RFresampled] = getCurStimImage(M, n, RF);	
	
	% overlay and display
	axes(M.ui.rfAxes); cla
% 	RF_img(:,:,1) = RF;
% 	RF_img(:,:,2) = 1-RF;
% 	RF_img(:,:,3) = stimImage;
	RF_img(:,:,1) = stimImage;
	RF_img(:,:,2) = RFresampled;
	RF_img(:,:,3) = RFresampled;

    [x,y] = prfSamplingGrid(M.params);
    x = x(:); y = y(:);
    imagesc(x, -y, RF_img); hold on;
    plot([min(x) max(x)], [0 0], 'k-');
    plot( [0 0], [min(y) max(y)], 'k-');
    
    axis image  xy;
    ylabel('y (deg)');
    xlabel('x (deg)');	
	
	%% grab the current movie frame
	mov(n) = getframe(gcf);
end

%% save the .avi file, if a path is provided.
if ~isempty(aviFile)
	quality = 100;
	description = aviFile;
	keyframe = fps;
	if ispc
		compression = 'Indeo5';
	else
		compression = 'None';
	end
	
	ensureDirExists( fileparts(aviFile) );
	
	movie2avi(mov, aviFile, 'FPS', fps, 'Compression', compression, ...
		  'Quality', quality, 'Videoname', description, 'Keyframe', keyframe);
	fprintf('[%s]: Saved movie as %s.\n', mfilename, aviFile);

end

return
%--------------------------------------



%--------------------------------------
function [stimImage RF] = getCurStimImage(M, f, RFvals)
% Get a stimulus image matching the sampling positions as the RF.
% Also returns the RF resampled into a square grid.
x = prfSamplingGrid(M.params);

% account for the different stimuli that are shown next to each other
% f originally refers to the frame in the combined time series across scans:
% we want to break this down into scan n, frame f within that scan.
n = 1; 
nStimScans = numel(M.params.stim);
while n <= nStimScans,
    tmp = f + M.params.stim(n).prescanDuration; 
    if tmp > size(M.params.stim(n).images_org,2),
        f = tmp - size(M.params.stim(n).images_org,2);        
        n = n + 1;
    else
        f = tmp;
        break;
    end
end

% stim image
stimImage     = NaN(size(x));
stimImage(M.params.stim(1).instimwindow) = M.params.stim(n).images_org(:,f);
stimImage     = reshape(stimImage, size(x));

% RF
RF     = NaN(size(x));
RF(M.params.stim(1).instimwindow) = normalize(RFvals, 0, 1);
RF     = reshape(RF, size(x));

return