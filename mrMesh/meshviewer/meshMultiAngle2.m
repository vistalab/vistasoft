function img = meshMultiAngle2(msh, settings, savePath, cbarFlag, msz);
% Takes a picture of a mesh at multiple camera settings, and saves as a
% .png in a directory or pastes in a PowerPoint file.
%
% img = meshMultiAngle2([mesh], [settings], [save directory or .ppt file],
%                       [cbarFlag], [montageSize]);
%
% mesh: mesh structure of which to take pictures. [Defaults to current
%       mesh of selected mrVista gray view]
% settings: struct array specifying the camera settings for each picture.
%       Each entry should have a 'cRot' field which specifies
%       the camera settings (see meshAngle).
%       Can also specify a vector of integers, with the indices into
%       the saved settings struct (using meshAngle). E.g. [1 3 2 4]
%       will display the 1st, 3rd, 2nd, and 4th settings, in that order.
%       [If omitted, opens a dialog to select settings from the saved settings
%       -- again, see meshAngle.]
% savePath: directory in which to save a .png file of the image, or
%       else path to a powerpoint file to paste the image. (PowerPoint
%       is Windows only). [If omitted, doesn't save the image.]
% cbarFlag: if 1, will display image in a separate figure and add
%       a subplot with the colorbar leged at the bottom. [default 0]
% montageSize: specify the size of the image montage in [# rows # cols].
%       [Defaults to being as close to square as possible, leaning
%        towards having more rows]
%
% Returns a montage image of the mesh from all the specified settings.
%
%
% ras, 10/2005.
% ras, 05/2006: now uses mesh settings files instead of settings file.
% ras, 08/2006: mrVista2 version.
if notDefined('msh'), msh = viewGet(getSelectedGray,'mesh'); end
if notDefined('cbarFlag'), cbarFlag = 0; end

if notDefined('settings') | isequal(settings, 'dialog')
    % put up a dialog 
    settingsFile = fullfile(fileparts(msh.path), 'MeshSettings.mat');    
    [settings savePath cbarFlag msz] = meshMultiAngleGUI(settingsFile);
    if isempty(settings) % user aborted, exit quietly
        return
    end        
end

if notDefined('msz')
    ncols = ceil(sqrt(length(settings)));
    nrows = ceil(length(settings)/ncols);
    msz = [nrows ncols];
end

if ischar(settings), settings = {settings}; end  % use cell parsing code below

% allow settings to be cell of names of settings
if iscell(settings)
    selectedNames = settings; % will load over the 'settings' variable below
    settingsFile = fullfile(fileparts(msh.path), 'MeshSettings.mat')
    load(settingsFile, 'settings');
    names = {settings.name};
    for i = 1:length(selectedNames)
        ind(i) = cellfind(lower(names), lower(selectedNames{i}));
    end
    settings = settings(ind);
end

% allow settings to be index vector into saved settings
if isnumeric(settings)
    ind = settings; % will load over the 'settings' variable below...
    settingsFile = fullfile(fileparts(msh.path), 'MeshSettings.mat');
    load(settingsFile, 'settings');
    settings = settings(ind);
end

%get the screenshots
for i = 1:length(settings)
    msh = meshApplySettings(msh, settings(i));
    images{i} = mrmGet(msh, 'screenshot') ./ 255;
    pause(1); %empirically-needed wait, or screenshots get corrupted
end

% make the montage image
img = imageMontage(images, msz(1), msz(2));

% if specified, display img in a figure and add View's cbar
if cbarFlag
    hfig = figure('Color', 'w');
    image(img); axis image; axis off;

    % get the cbar(s) from the current mrViewer
    ui = mrViewGet;
	
	isHidden = [ui.overlays.hide];
	nColorBars = sum(~isHidden);
	overlayList = find(~isHidden);
	w = max( .25, 1/(nColorBars+2) ); % cbar width
	h = .15;	 % cbar height
	
	panel = mrVPanel('below', 100, hfig, 'pixels');	
    for ii = 1:nColorBars
		o = overlayList(ii);
		pos = [((ii-1) * 1.2*w + .1) .4 w h];
        hax = axes('Parent', panel, 'Units', 'norm', 'Position', pos);
        cbarDraw(ui.overlays(o).cbar, hax);
        m = ui.overlays(o).mapNum;
		title(ui.maps(m).name, 'FontSize', 12);		
		if ~isempty(ui.maps(m).dataUnits)
	       xlabel(ui.maps(m).dataUnits, 'FontSize', 10);
		end        
    end

    % let's go ahead and add an ROI legend
    if ui.settings.roiViewMode > 1 & ~isempty(ui.rois)
        legendPanel({ui.rois.name}, {ui.rois.color});
    end

end

% save / export if a path is specified
if ~notDefined('savePath')
    savePath = fullpath(savePath);
    [p f ext] = fileparts(savePath);
    if isequal(lower(ext),'.ppt')
        % export to a powerpoint file
        fig = figure; imshow(img);
        [ppt, op] = pptOpen(savePath);
        pptPaste(op,fig,'meta');
        pptClose(op,ppt,savePath);
        close(fig);
        fprintf('Pasted image in %s.\n', fname);
    else
        % export to a .png or .tiff image in a directory
        if isempty(f), f=sprintf('mrMesh-%s',datestr(clock)); end
        if isempty(ext), ext = '.tiff'; end
        fname = fullfile(p,[f ext]);
        if cbarFlag
            % export the figure w/ the cbar included
            saveas(hfig, fname, ext(2:end));
            
%             exportfig(hfig, fname, 'Format',ext(2:end), 'Color','cmyk', ...
%                 'width',3.5, 'Resolution',450);
        else
            % write directly to the image
            imwrite(img, fname, 'png');
        end
        fprintf('Saved montage as %s.\n', fname);
    end
else % save to pwd
    %         % export to a pwd-mrMesh-date.png image in current directory
    %         pwdname=pwd;ll=length(pwdname)
    %         f=sprintf('%s-mrMesh-%s',pwdname(ll-4:ll),datestr(now,1));ext = '.png';
    %         fname = [f ext]
    %         udata.rgb = img;
    %         imwrite(udata.rgb, fname);
    %         fprintf('Saved montage as %s.\n', fname);
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function [settings, savePath, cbarFlag, msz] = meshMultiAngleGUI(settingsFile);
% [settings, savePath, cbarFlag, msz] = meshMultiAngleGUI(settingsFile);
% put up a dialog to get the parameters for meshMultiAngle2.
settings = []; savePath = []; cbarFlag = []; msz = [];
if ~exist(settingsFile,'file')
    myErrorDlg('Sorry, you need to save some mesh settings first. ');
end

load(settingsFile, 'settings');

% set up dialog
dlg(1).fieldName = 'whichSettings';
dlg(1).style = 'listbox';
dlg(1).string = 'Take a picture at which camera settings?';
dlg(1).list = {settings.name};
dlg(1).value = 1;

dlg(2).fieldName = 'order';
dlg(2).style = 'edit';
dlg(2).string = 'OPTIONAL: Order of settings (e.g. [1 2 3 4] vs. [4 3 2 1])?';
dlg(2).value = '';

dlg(3).fieldName = 'savePath';
dlg(3).style = 'filenamew';
dlg(3).string = 'Path to save image (.tiff, .png, .ppt slide)?';
nSnapshotFiles = length( dir('Images/meshSnapshot_*') );
dlg(3).value = sprintf('Images/Mesh Snapshot %i.png', nSnapshotFiles+1);

dlg(4).fieldName = 'cbarFlag';
dlg(4).style = 'checkbox';
dlg(4).string = 'Add Colorbar / ROI Legend?';
dlg(4).value = 1;

dlg(5).fieldName = 'montageSize';
dlg(5).style = 'edit';
dlg(5).string = 'OPTIONAL: Size of image montage [rows cols]?';
dlg(5).value = '';


% put up dialog and get response
resp = generalDialog(dlg, mfilename);

% parse response
if isempty(resp), settings = []; return; end   % user canceled
for j = 1:length(resp.whichSettings)
    sel(j) = cellfind(dlg(1).list, resp.whichSettings{j});
end
if ~isempty(resp.order), order = str2num(resp.order);
else,                    order = 1:length(sel);
end
settings = settings(sel(order));

savePath = resp.savePath;

cbarFlag = resp.cbarFlag;

msz = str2num(resp.montageSize);

return
