function [M, mov] = flatLevelMovie(vw,scans,saveAviFile)
%
% flatLevelMovie(vw,[scans,saveAviFile]):
%
% Create (and export to .AVI if selected) a movie of 
% the tSeries for the selected scans and view settings,
% in the flat level view.
%
% scans: which scans to use. Default to cur scan.
%
% saveAviFile: if set to 1, will save as an .avi movie file
% in the view's data dir. Default is to prompt user. Note that
% in unix environments, the resulting .avi file will be
% quite large (as they lack access to compression algorithms).
%
%
% ras 10/04.
if ieNotDefined('scans')
    scans = getCurScan(vw);
end

if ieNotDefined('saveAviFile')
    % ask user
    button = questdlg('Export the movie to .AVI?');
    if isequal(button,'Cancel')
        return
    else
        saveAviFile = isequal(button,'Yes');
    end
end

%%%%%% params
% clip out values of the map in this range (normalized)
clipRange = [0.5 1] ;
convertToPct = 1;   % if 1, will convert raw vals to % of mean
cnt = 1;

% get slice, zoom settings from the view
slices = getFlatLevelSlices(vw);
zoom = vw.ui.zoom;

% get the anat images as an underlay
anat = vw.anat;

% grab the selected slices and zoom for the anat
[underlay mask] = flatLevelMontage(vw,anat);

% get a cmap for the movie
cmap = vw.ui.mapMode.cmap;
numGrays = vw.ui.mapMode.numGrays;
numColors = vw.ui.mapMode.numColors;

% loop through selected scans
fprintf('Making movie...\n');
for scan = scans    
    % get (compute or load) a 4-D tSeries array
    tMat = flatLevelTSeries(vw,scan);    
    
    nFrames = size(tMat,4);
    
    % if converting to % change, get mean values over time:
    if convertToPct==1
        meanImg = flatLevelMontage(vw,mean(tMat,4));
    end
    
    fprintf('Scan %i.',scan);
    
    for frame = 1:nFrames
        % get montage image of each frame
        % based on view settings
        img = flatLevelMontage(vw,squeeze(tMat(:,:,:,frame)));
                
        % convert to % change if desired
        if convertToPct==1
            img(mask==1) = img(mask==1)./meanImg(mask==1);
        end
        
        % threshold, add underlay
        minVal = min(img(mask));
        maxVal = max(img(mask));
        clipVals = minVal + (clipRange .* (maxVal-minVal));
        img(mask==1) = rescale2(img(mask==1),clipVals,[128 255]);
        img(mask==0) = rescale2(underlay(mask==0),[0 1],[0 127]);
        
        % add to movie array
        M(:,:,:,cnt) = ind2rgb(img,cmap);
        cnt = cnt + 1;
        
        fprintf('.');        
    end
    
    fprintf('\n')
end

% view using MoviePlayer interface
mov = mplay(M);

% export if selected
% (add later)

return
% /----------------------------------------------------------------------/ %




% /----------------------------------------------------------------------/ %
function [montage, mask] = flatLevelMontage(vw,vol)
% [montage mask] = flatLevelMontage(vw,vol);
%
% Takes the specified volume, which should be 
% in flat level space (slices are diff't gray levels)
% and creates a montage according to the preferences
% specified in the view.
% Also returns an image of the same size with
% a binary mask showing where measurements were made.
slices = getFlatLevelSlices(vw);
nSlices = length(slices);
nrows = ceil(sqrt(nSlices));
ncols = ceil(nSlices/nrows);
zoom = round(vw.ui.zoom);
[rotations,flipLR]=getFlatRotations(vw); 
rotateDeg=rotations(viewGet(vw, 'Current Slice'));
flipFlag=flipLR(viewGet(vw, 'Current Slice'));    
montage = [];
mask = [];
for row = 1:nrows
    rowIm = [];
    rowMask = [];
    
    for col = 1:ncols
        sliceind = (row-1)*ncols + col;
        
        if sliceind <= length(slices)
            % if there's a slice for this row/col
            slice = slices(sliceind);
        else
            % otherwise, set it to show black space below
            slice = slices(end) + 1;
        end
        
        if slice <= slices(end)
            % Get anatomy image
			volIm = vol(:,:,slice);
            maskIm = vw.ui.mask(:,:,slice);
            
            % rotate if selected
            if (rotateDeg | flipFlag) 
                volIm = imrotate(volIm,-1*rotateDeg,'bicubic','crop');                   
                if (flipFlag), volIm=fliplr(volIm); end 
                maskIm = imrotate(maskIm,-1*rotateDeg,'bicubic','crop');                   
                if (flipFlag), maskIm=fliplr(maskIm); end 
            end
            
            % zoom
            volIm = volIm(zoom(3):zoom(4),zoom(1):zoom(2));
            maskIm = maskIm(zoom(3):zoom(4),zoom(1):zoom(2));
        else
            volIm = zeros(size(volIm));
            maskIm = zeros(size(maskIm));
        end
        
        rowIm = [rowIm volIm];
        rowMask = [rowMask maskIm];
    end
    
    montage = [montage; rowIm];
    mask = [mask; rowMask];
end
montage = double(montage);
mask = logical(round(mask));
return
% /----------------------------------------------------------------------/ %







% OLDER CODE:
% % open the window for the movie
% fig = figure('Name',figName,'Color',[1 1 1],...
%              'Units','Normalized','Position',[0 .4 .5 .5]);

% 
% 
% % /----------------------------------------------------------------------/ %
% function stim = openMovieWin(vw,stim,scans,slices);
% % opens the movie window and adds the handles
% stim.handles.figure = figure('Units','Normalized','Position',[.2 .2 .6 .6]);
% set(gcf,'Name',['tSeries movie, scan ',num2str(scans),', slices ',num2str(slices)]);
% % set(gcf,'DefaultTextColor','blue');
% stim.handles.axes = axes('Position',[.05 .3 .75 .6]);
% cbstr = 's = get(gcf,''UserData''); movie(s.movie,1,s.movieRate);';
% stim.handles.play = uicontrol('Style','pushbutton','Units','Normalized',...
%                               'Position',[.83 .7 .12 .08],'String','Play',...
%                               'Callback',cbstr);
% stim.handles.rebuild = uicontrol('Style','pushbutton','Units','Normalized',...
%                               'Position',[.83 .5 .12 .08],'String','Rebuild',...
%                               'Callback','stimPlusTSeriesMovie(''rebuild'');');
% stim.handles.export = uicontrol('Style','pushbutton','Units','Normalized',...
%                               'Position',[.83 .3 .12 .08],'String','Export',...
%                               'Callback','stimPlusTSeriesMovie(''export'');');
% return
% % /----------------------------------------------------------------------/ %
