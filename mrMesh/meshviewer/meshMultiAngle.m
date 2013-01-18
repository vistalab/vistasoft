function [img, hfig] = meshMultiAngle(msh, settings, savePath, varargin);
% Takes a picture of a mesh at multiple camera settings, and saves as a 
% .png in a directory or pastes in a PowerPoint file.
%
% img = meshMultiAngle([mesh], [settings], [save directory or .ppt file], 
%                       [options]);
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
%
% In addition to the three input arguments, you may specify the following
% options: 
%
% 'cbarFlag', [val]: flag for whether to show the colorbar and ROI legends. 
%			Possible values:
%		0: just save / export the mesh images.
%		1  [default]: display image in a separate figure and add 
%					 a subplot with the colorbar legend at the bottom. 
%					 Will also add an ROI legend if ROIs are shown.
%
% 'montageSize', [val]: specify the size of the image montage in 
%					[# rows # cols]. [Defaults to being as close 
%					to square as possible, leaning towards having 
%					more rows]
%
%
% 'titleText', [val]: add a title text. This will go above the 
%				mesh images; if a powerpoint file is provided, it
%				will also be exported in the file. If the 'titleText'
%				flag is specified without adding an extra argument
%				(or an empty argument), a default title text will be
%				selected based on the session / data type / scan.
%				Unless this flag is set, no title text will be added.
%
% Returns a montage image of the mesh from all the specified settings.
% 
%
% ras, 10/2005.
% ras, 05/2006: now uses mesh settings files instead of settings file.
% ras, 06/2007: added title text; set the cbarFlag and msz params as
%				optional input arguments; changed the default cbarFlag
%				value to 1 (just seemed like this was used more often).
if notDefined('msh'), msh = viewGet(getSelectedGray,'mesh'); end
if notDefined('cbarFlag'), cbarFlag = 1; end

if notDefined('settings')
    % put up a dialog -- but first check there are saved settings:
    settingsFile = fullfile(fileparts(msh.path),'MeshSettings.mat');
    if ~exist(settingsFile,'file')
        myErrorDlg(['Sorry, you need to save some mesh settings first. ' ...
                   'Use the menu Edit | Save Camer Angles | Save in ' ...
                   'the 3D Window, or the meshAngle function.']);
    else
        load(settingsFile, 'settings');
        dlg(1).fieldName = 'whichSettings';
        dlg(1).style = 'listbox'; 
        dlg(1).string = 'Take a picture at which camera settings?';
        dlg(1).list = {settings.name};
        dlg(1).value = 1;
        
        dlg(2).fieldName = 'order';
        dlg(2).style = 'edit';
        dlg(2).string = 'OPTIONAL: Order of settings (e.g. [1 2 3 4] vs. [4 3 2 1])?';
        dlg(2).value = ''
        
        resp = generalDialog(dlg,'Mesh Multi-Angle');
        if isempty(resp), return; end   % user canceled
        for j = 1:length(resp.whichSettings)
            sel(j) = cellfind(dlg(1).list, resp.whichSettings{j});
        end
        if ~isempty(resp.order), order = str2num(resp.order);
        else,                    order = 1:length(sel);
        end
        settings = settings(sel(order));
    end
end

if notDefined('msz')
    ncols = ceil(sqrt(length(settings)));
    nrows = ceil(length(settings)/ncols); 
    msz = [nrows ncols];
end

% allow settings to be cell of names of settings
if iscell(settings)
    selectedNames = settings; % will load over the 'settings' variable below
    settingsFile = fullfile(fileparts(msh.path), 'MeshSettings.mat');
    load(settingsFile, 'settings');
    names = {settings.name};
    for i = 1:length(selectedNames)
        ind(i) = cellfind(names, selectedNames{i});
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

%% Parse the options
for i = 1:length(varargin)
	if ischar(varargin{i}), 
		switch lower(varargin{i})
		case 'cbarflag', cbarFlag = varargin{i+1};
		case 'cbar',	cbarFlag = 1;
		case 'nocbar',	cbarFlag = 0;
		case {'msz' 'montagesize'}, msz = varargin{i+1};
		case {'ttl' 'title' 'titletext'}
			if length(varargin) > i
				titleText = varargin{i+1};
			else
				titleText = '';
			end

			% for empty title text, create a reasonable default
			if isempty(titleText)
				gray = getSelectedGray;
				dtName = viewGet(gray, 'dataTypeName');
				scans = viewGet(gray, 'curScan');
				mapName = viewGet(gray, 'displayMode');
				if isequal(mapName, 'map')
					 mapName = gray.mapName;
				end

				titleText = sprintf('%s %s %s %i %s', ...
									mrSESSION.sessionCode, ...
									msh.name, ...
									dtName, ...
									scan, ...
									mapName);
			end
		end
	end
end
						
				

%%%%%%%%%%%%%%%%%%%%%%%
% get the screenshots %
%%%%%%%%%%%%%%%%%%%%%%%
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

	hax = subplot('Position', [0 0 1 1]);
	imagesc(img); axis image; axis off;
	
	if exist('titleText', 'var')
		title(titleText);
	end
    
    % find the mrVista 1.0 view for the cbar
    gray = getSelectedGray;
    if isempty(gray)
        myWarnDlg('No colorbar to attach to image.')        
    elseif ~isequal(gray.ui.displayMode, 'anat')
		addCbarLegend(gray, hfig);
    end
    
    % let's go ahead and add an ROI legend
    if checkfields(gray, 'ui', 'showROIs') & gray.ui.showROIs ~= 0 & ...
            ~isempty(gray.ROIs)
        addRoiLegend(gray, hfig);
    end
        
    
elseif nargout>1
    hfig = [];
    
end

%% save / export if a path is specified
if exist('savePath', 'var') & ~isempty(savePath)
    savePath = fullpath(savePath);
    [p f ext] = fileparts(savePath);
    if isequal(lower(ext),'.ppt')
        %% export to a powerpoint file
		% put up a figure if it doesn't already exist
		if ~cbarFlag, hfig = figure; imshow(img); end
		
		% if we have title text, we can place it as the
		% title of the .ppt slide, instead of on the mesh image:
		figure(hfig);		title('');
		
		% open the PPT file; 
        [ppt, op] = pptOpen(savePath);
		
		% paste
		if exist('titleText', 'var')
			pptPaste(op, hfig, 'meta', titleText);
		else
	        pptPaste(op, hfig, 'meta');
		end
		
		% close the PPT file / figure:
        pptClose(op, ppt, savePath);
        close(hfig);
        fprintf('Pasted image in %s.\n', savePath);
		
    else
        %% export to a .png image in a directory
        if isempty(f), f=sprintf('mrMesh-%s',datestr(clock)); end
        if isempty(ext), ext = '.png'; end
        fname = fullfile(p,[f ext]);
        if cbarFlag
            % export the figure w/ the cbar included
%             exportfig(hfig, fname, 'Format','png', 'Color','cmyk', ...
%                       'width',3.5, 'Resolution',450);
            saveas(hfig, fname, 'png');
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

