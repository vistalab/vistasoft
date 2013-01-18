function flatLevelMovie2(view,scans);
% flatLevelMovie(view,[scans]):
%
% Create (and export to .AVI if selected) a movie of 
% the tSeries for the selected scans and view settings,
% in the flat level view.
%
% ras 10/04.%   
%
% Defaults to the current scan and slices, though multiple 
% scans/slices may be specified.
%
%
% 10/04 ras, off stimPlusTSeriesMovie.
global dataTYPES;

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
    help flatLevelMovie2;
    error('flatLevelMovie2 called wrong.');
end

% --------- Everything below is code to build the movie ----------- %

if ieNotDefined('scans')    scans = viewGet(view,'curScan');   end

%%%%% default params
clipRange = [.1 1] ; % clip out values of the map in this range (normalized)
detrend = 0;        % detrending takes a long time on a whole tSeries
movieRate = 6;      % rate in frames per second to play movie
cnt = 0;            % counter, used below
slices = getFlatLevelSlices(view);
TR = dataTYPES(1).scanParams(1).framePeriod;

%%%%% parse options
% put code here

dt = viewGet(view,'curdt');
nFrames = 0;
for s = scans
    nFrames = nFrames + dataTYPES(dt).scanParams(s).nFrames;
end
stim.frames = 1:nFrames;
stim.movieRate = movieRate;

% the map field of the view will need to be initialized
if isempty(view.map)
    view.map = cell(1,numScans(view));
end

% open the movie window; add handles to stim struct
stim.cmap = view.ui.mapMode.cmap;
stim = openMovieWin(view,stim,scans);

% make a header over the image for text
header = uint8(zeros(50,size(view.ui.image,2)));

% ----- build the movie ----- %
% loop through selected scans
for scan = scans
    setCurScan(view,scan);
    
    % store the current map for this scan for later
    oldMap = view.map{scan};
    
    for f = 1:nFrames
        % set the current frame of the tSeries as the view's map
        % (do only for selected slices -- otherwise I'd use
        % flatLevelIndices2Coords):
        view.map{scan} = zeros(size(view.anat));
        for slice = slices
            % load the tSeries for this scan
            text(0,20,'Loading....');
            tSeries = loadtSeries(view,scan,slice);
            nFrames = size(tSeries,1);
            cla;

            % get/set clip range for this scan
            minVal = min(tSeries(:));
            maxVal = max(tSeries(:));
            rng = clipRange .* [minVal maxVal];
%            setMapWindow(view,rng);
            
            subCoords = view.coords{slice};
            mask = view.ui.mask(:,:,slice);
            
            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            img = myGriddata(subCoords,tSeries.',mask);
            
            % assign to map
            view.map{scan}(:,:,slice) = img;
        end        
        
        % get the frame image -- this takes into account montage, zoom,
        % rotations:
        [view frame] = recomputeFlatLevelImage(view,'map');
        
        % put the frame image up
        figure(stim.handles.figure);
%         frame = [header; frame];
        imshow(img,hot(256));
        
        % add some explanatory text
        htmp = text(20,20,num2str(f)); set(htmp,'Color','r');
        
        % add the frame image to the movie
        cnt = cnt + f;
        stim.movie(cnt) = getframe;
        
        set(gcf,'UserData',stim);
    end
    
	% restore the old map to the view
	view.map{scan} = oldMap;
end

colorbar horiz;
% colormap(stim.cmap);

% set some important params on the stim struct; stash in fig's UserData
stim.viewName = view.name;
stim.clipRange = clipRange;
stim.detrend = detrend;
stim.movieRate = movieRate;
set(stim.handles.figure,'UserData',stim);

return
% /----------------------------------------------------------------------/ %



% /----------------------------------------------------------------------/ %
function stim = openMovieWin(view,stim,scans);
% opens the movie window and adds the handles
stim.handles.figure = figure('Units','Normalized','Position',[.2 .2 .6 .6]);
set(gcf,'Name',['Flat tSeries movie, scan ',num2str(scans)]);
% set(gcf,'DefaultTextColor','blue');
stim.handles.axes = axes('Position',[.05 .3 .75 .6]);
cbstr = 's = get(gcf,''UserData''); movie(s.movie,1,s.movieRate);';
stim.handles.play = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .7 .12 .08],'String','Play',...
                              'Callback',cbstr);
stim.handles.rebuild = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .5 .12 .08],'String','Rebuild',...
                              'Callback','flatLevelMovie2(''rebuild'');');
stim.handles.export = uicontrol('Style','pushbutton','Units','Normalized',...
                              'Position',[.83 .3 .12 .08],'String','Export',...
                              'Callback','flatLevelMovie2(''export'');');
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
