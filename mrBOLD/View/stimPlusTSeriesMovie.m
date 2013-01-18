function view = stimPlusTSeriesMovie(view,stim,scans,slices,varargin);
%  view = stimPlusTSeriesMovie(view,stim,[scans,slices,options]);
%
% Similar to makeTSeriesMovie, makes a movie with the tSeries
% overlayed over anatomies, but with some additional features:
%
%   1) Shows next to the movie the stimuli that were showing
%   at each frame;
%
%   2) Has a simple interface allowing the threshold to be
%   set for what (normalized) values of the tSeries are 
%   overlayed over the anatomies.
%
% stim must be a struct containing the following fields:
%   images: cell specifying which images were shown. Each entry
%           in the cell can be a matrix containing the image, or
%           a string specifying the path to load the image;
%           [If left empty, will try to load these from the third
%           column of the parfiles assigned to the selected scans]
%   frames: array specifying which frames from the tSeries to use
%           [default is 1:numFrames, but if, e.g., many images appear
%           within one TR you may 'double up' those entries of the 
%           frames field]
%   order:  array specifying which image (index in the images cell)
%           to show for each frame. Should be the same length as
%           the frames field. [If empty, will use the conditions
%           specified in the parfiles assigned to the selected scans]
%   
%
% Defaults to the current scan and slices, though multiple 
% scans/slices may be specified.
%
%
% 05/04 ras.

% the callbacks from the UI controls give as the 
% first argument a string specifying the sort of
% callback. Check:
if ischar(view)
    % it's a callback, not a call to open a new movie
    switch view
        case 'play', playStimMovie; return;
        case 'rebuild', rebuildStimMovie;
        case 'export', exportStimMovie; return;
        otherwise, return;
    end
elseif ~isstruct(view)
    % if it's not a struct, something's wrong
    help stimPlusTSeriesMovie;
    error('stimPlusTSeriesMovie called wrong.');
end

% --------- Everything below is code to build the movie ----------- %

if ieNotDefined('scans')    scans = viewGet(view,'curScan');   end
if ieNotDefined('slices')   slices = viewGet(view,'curSlice'); end

%%%%% default params
thresh = 0.6;       % normalized func intensity val
detrend = 0;        % detrending takes a long time on a whole tSeries
cmap = hot(256);    % color map for tSeries overlay
movieRate = 6;     % rate in frames per second to play movie
TR = viewGet(view,'TR');

%%%%% parse options
% put code here

% check that the stim struct has the proper fields
if ~isfield(stim,'images') | ~isfield(stim,'frames') | ~isfield(stim,'order')
    help stimPlusTSeriesMovie;
    error('Second argument does not have proper fields.');
end

% allow for some fields to be empty; this means get the information
% from the parfiles:
if isempty(stim.images)
    trials = exp5_concatParfiles(view,scans);
    stim.images = trials.image;
end

if isempty(stim.frames)
    global dataTYPES;
    dt = viewGet(view,'curdt');
    nFrames = 0;
    for s = scans
        nFrames = nFrames + dataTYPES(dt).scanParams(s).nFrames;
    end
    stim.frames = 1:nFrames;
end

if isempty(stim.order)  
   % assume the conditions in the parfiles point to the index
   % of which image to use in trials.images -- interpolate
   % to make order a vector showing which condition at each frame
   trials = exp5_concatParfiles(view,scans); 
   ok = find(trials.onset < nFrames);
   stim.order = NaN*ones(1,nFrames);
   stim.order(trials.onset(ok)) = trials.cond(ok);
   % we've set the onset frames of each cond; now fill in the intervals
   fillin = find(isnan(stim.order));
   for j = fillin
       lastOnset = find((1:nFrames < j) & ~isnan(stim.order));
       stim.order(j) = stim.order(lastOnset(end));
   end
end

% load any images specified by paths in stim.images
for i = 1:length(stim.images)
    if ischar(stim.images{i})
        if exist(stim.images{i},'file')
            stim.images{i} = imread(stim.images{i},'jpg');
        else
            error(sprintf('File %s not found.',stim.images{i}));
        end
    end
end

% open the movie window; add handles to stim struct
stim.cmap = cmap;
stim = openMovieWin(view,stim,scans,slices);

% Get, rescale anatomy image
anatIm = makeMontage(view.anat,slices);
anatClip = viewGet(view,'anatClip');
minVal = double(min(anatIm(:)));
maxVal = double(max(anatIm(:)));
anatClipMin = min(anatClip)*(maxVal-minVal) + minVal;
anatClipMax = max(anatClip)*(maxVal-minVal) + minVal;
anatIm = (rescale2(double(anatIm),[anatClipMin,anatClipMax],[1,256]));
anatIm = normalize(anatIm,0,1);
imSize = size(anatIm);

% make all the stimulus images squares with the edge equal to
% the y-size of the fnctional image (this will ensure everything 
% stays the same relative size):
for i = 1:length(stim.images)
    if ~isequal(size(stim.images{i}),[imSize(1) imSize(1)])
        stim.images{i} = imresize(stim.images{i},[imSize(1) imSize(1)]);
    end
end

% make a spacer b/w the functional img and stimulus img
spacer = uint8(205*ones(imSize(1),50,3));

% load the tSeries for the selected scans and slices
fprintf('Loading tSeries...');
for s = 1:length(scans)
    for i = 1:length(slices)
        tS = loadtSeries(view,scans(s),slices(i));
        if s==1
            tSeriesAll{i} = tS;
        else
            tSeriesAll{i} = [tSeriesAll{i} tS];
        end   
    end
end
fprintf('done.\n');

% ----- build the movie ----- %
nFrames = length(stim.frames);
dims = sliceDims(view,scans(1));
for f = 1:nFrames
    
    % construct the functional img (anat + overlay) for this frame
    func = zeros(imSize(1),imSize(2),3); % truecolor image
    clear tSeries;
    for ii = 1:length(slices)
        tSeries(:,:,ii) = reshape(tSeriesAll{ii}(f,:),dims);
    end
    tSeries = makeMontage(tSeries);
    overlay = upSampleRep(tSeries,size(anatIm));
    overlay = normalize(overlay,0,1); 
    mask = find(overlay >= thresh);
    overlay(mask) = normalize(overlay(mask),1,256); % indices into cmap
    overlay = round(overlay);
    for col = 1:3
        tmp = anatIm;
        tmp(mask) = cmap(overlay(mask),col);
        func(:,:,col) = tmp;
    end
    func = uint8(256 .* func);
    
    % get stimulus img for this frame
    whichStim = stim.order(f);
    if whichStim==0  % null condition, maybe a better way to do this
        stimulus = zeros(imSize(1),imSize(1));
    else
        stimulus = stim.images{whichStim};
    end
    stimulus = repmat(stimulus,[1 1 3]);
    stimulus = uint8(stimulus);
       
    % merge the images together, display and grab a movie frame
    axes(stim.handles.axes);
    img = [stimulus spacer func];
    imshow(img);
    htmp = text(20,20,num2str(f)); set(htmp,'Color','r');
    title(sprintf('%i secs',f*TR),'FontSize',16);
    stim.movie(f) = getframe;
    
    % might also be good to have this be attached to
    % the view like makeTSeriesMovie, but I have to
    % do some other things to ensure full compatibility:
    view.ui.movie.movie(f) = getframe;
end

colorbar horiz;
colormap(stim.cmap);

% set some important params on the stim struct; stash in fig's UserData
stim.viewName = view.name;
stim.thresh = thresh;
stim.detrend = detrend;
stim.movieRate = movieRate;
set(stim.handles.figure,'UserData',stim);

return
% /----------------------------------------------------------------------/ %



% /----------------------------------------------------------------------/ %
function stim = openMovieWin(view,stim,scans,slices);
% opens the movie window and adds the handles
stim.handles.figure = figure('Units','Normalized','Position',[.2 .2 .6 .6]);
set(gcf,'Name',['tSeries movie, scan ',num2str(scans),', slices ',num2str(slices)]);
% set(gcf,'DefaultTextColor','blue');
stim.handles.axes = axes('Position',[.05 .3 .75 .6]);
cbstr = 's = get(gcf,''UserData''); movie(s.movie,1,s.movieRate);';
stim.handles.play = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .7 .12 .08],'String','Play',...
                              'Callback',cbstr);
stim.handles.rebuild = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .5 .12 .08],'String','Rebuild',...
                              'Callback','stimPlusTSeriesMovie(''rebuild'');');
stim.handles.export = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .3 .12 .08],'String','Export',...
                              'Callback','stimPlusTSeriesMovie(''export'');');
return
% /----------------------------------------------------------------------/ %



% /----------------------------------------------------------------------/ %
function playStimMovie(nTimes);
% plays the movie once it's made.
if ieNotDefined('nTimes')   nTimes = 1;   end
stim = get(gcf,'UserData');
movie(stim.movie,nTimes,stim.movieRate);
return
% /----------------------------------------------------------------------/ %



% /----------------------------------------------------------------------/ %
function rebuildStimMovie;
% rebuild the stimulus movie, with user-modified params.
return
% /----------------------------------------------------------------------/ %



% /----------------------------------------------------------------------/ %
function exportStimMovie;
% export the movie to an AVI file.
if isunix
    compression = 'None';
else
    compression = 'Indeo5';
end
stim = get(gcf,'UserData');
[fname, pth] = myUiPutFile(pwd,'*.avi','Name your saved movie...');
savePath = fullfile(pth,fname);
movie2avi(stim.movie,savePath,'FPS',stim.movieRate,'Compression',compression);
fprintf('Saved %s.\n',savePath);
return
