function [images pics] = meshCompareScans(V, scans, dts, settings, savePath, leg);
%
% Create mosaic images showing data from different scans / data
% types superimposed on the same mesh and view angles. 
%
% [images pics]  = meshCompareScans(<view, scans, dts, settings, savePath, leg>);
%
% This code requires that you have saved some view angles using the 
% function meshAngles. The code will set the input view (which should
% have an open mesh attached) to each of the specified input scans, 
% display the current data (which depends on the display mode: co, amp,
% ph, map) on the mesh, set the mesh to the specified angles, and
% take a snapshot. For each angle provided, the code will produce an
% output image which is a mosaic of the maps across all the scans and data
% types. 
%
% INPUT ARGUMENTS:
%   view: gray view w/ open mesh attached. <Default: selected gray.>
%
%   scans: vector of scan numbers from which to take the data.
%       <default: all scans in cur data type>
%
%   dts: cell array of data type names / vector of data type numbers. 
%       if only one provided, and multiple scans, will assume all the
%       scans come from the current data type. <default: cur dt>
%
%   angles: struct array of angles. See meshAngles. Can also be a numeric
%       vector specifying which of the saved angles to show, or a cell of
%       names of angles. <default: all saved mesh angles>
%   
%   savePath: if provided, will either save the *.png files to this
%       directory (if dir) or append images to a power point file (if
%       using Windows and savePath ends in *.ppt).
%
%   leg: flag: if set to 1, will put the image in a figure, and add
%        a copy of the color bar for the view. <default: no legend>
%
%
%
% OUTPUT ARGUMENT:
%   images: cell of images, one for each input angle specified. Each image
%   is a montage of the same view angle across scans
%
%	pics: nested cell of images containing the source screenshots for the
%	'images' output. pics{i}{j} contains the screenshot for view angle i,
%	scan j. 
%
% ras, 02/02/06. I've been writing this code for 50 years, but it's still
% always the same day!
% ras, 11/08/06. Converted to use settings rather than angles.
if notDefined('V'),         V = getSelectedGray;                end
if notDefined('scans'),     scans = 1:numScans(V);              end
if notDefined('dts'),       dts = V.curDataType;                end
if notDefined('savePath'),  savePath = 'Images';                end
if notDefined('leg'),       leg = 0;                           end
if notDefined('settings') | notDefined('scans')  
    params = meshCompareScansParams(V, dts(1), savePath, leg);
    settings = params.settings;
    scans = params.scans;
    savePath = params.savePath;
    leg = params.leg;
end

% get the current mesh
msh = viewGet(V, 'currentMesh');

% make sure the dts list is a numeric array
if iscell(dts)
    for i = 1:length(dts),   tmp(i) = existDataType(dts{i});    end
    dts = tmp;
elseif ischar(dts), dts = existDataType(dts);
end

for i = length(dts)+1:length(scans), dts(i) = dts(i-1);         end


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
elseif isnumeric(settings)
    ind = settings;
    settingsFile = fullfile(fileparts(msh.path), 'MeshSettings.mat');
    load(settingsFile, 'settings');
    settings = settings(ind);
end
    

%%%%%initialize cell arrays for each image (corresponding to each 
%%%%%angle) for the main loop
for i = 1:length(settings), pics{i} = {}; end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop: go through each scan, put up the map, grab the image %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(scans)
    if dts(i)~=V.curDataType, V = selectDataType(V, dts(i)); end
    V = viewSet(V, 'curScan', scans(i));
    
    meshColorOverlay(V);
    
    % take a picture of the mesh, with this map, at each angle
    for j = 1:length(settings)
        msh = meshApplySettings(msh, settings(j));
        pics{j}{i} = mrmGet(msh, 'screenshot') ./ 255;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process the screenshot pics into montage images %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:length(pics)
    images{i} = imageMontage(pics{i});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if legend requested, put the image up in a figure w/ the  %
% view's color bar                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if leg==1
    for i = 1:length(images)
        h(i) = figure('Name', mfilename, 'Color', 'w', ...
                   'Units', 'normalized', 'Position', [.1 .2 .7 .7]);

		nRows = ceil( sqrt( length(scans) ) );
		nCols = ceil( length(scans) / nRows );
		for j = 1:length(scans)
			hAx(j) = subplot(nRows, nCols, j);  
			image(pics{i}{j}); axis image; axis off;
			title( annotation(V, scans(j)) );
			set(gca, 'Position', get(gca, 'OuterPosition') - [0 0 0 .08]);			
		end 
		
		% add a color bar
		hPanel = addCbarLegend(V, h(i), .15);
	end
end

    
%%%%%%%%%%%%%%%%%%%%%
% save if specified %
%%%%%%%%%%%%%%%%%%%%%
if ~isempty(savePath)
	ensureDirExists( fileparts(savePath) );
	
    for i = 1:length(images)
        [p f ext] = fileparts(savePath);
        if isequal(lower(ext), '.ppt') & ispc
            % paste into powerpoint presentation
            fig = figure; imshow(img);
            [ppt, op] = pptOpen(savePath);
            pptPaste(op,fig,'meta');
            pptClose(op,ppt,savePath);
            close(fig);
            fprintf('Pasted image in %s.\n', fname);            
        else
            if isequal(lower(ext), '.ppt'), 
                q = ['Sorry, can only export to PowerPoint files on ' ...
                     'Windows machines right now. Save images as ' ...
                     '*.png files instead?'];
                resp = questdlg(q, mfilename); 
                if ~isequal(resp, 'Yes'), return; end
			end
			
            mapName = V.mapName;
            if checkfields(V, 'ui', 'displayMode')
                switch V.ui.displayMode
                    case 'ph', mapName = 'Phase';
                    case 'amp', mapName = 'Amplitude';
                    case 'co', mapName = 'Coherence';
                    case 'map', mapName = V.mapName;
                end
			end
			
            fname = sprintf('%s_%s.png', mapName, settings(i).name);
            imgPath = fullfile(savePath, fname);
            if leg==1   % save the figure w/ the image + colorbar
				% export the figure w/ the cbar included
				% (try to use exportfig, which is not always available)
				if exist('exportfig', 'file')
					 exportfig(h(1), imgPath, 'Format', 'png', 'Color', 'cmyk', ...
							   'width', 3.5, 'Resolution', 450);
				else
					saveas(h(1), imgPath, 'png');
				end
            else        % just write out the image
                imwrite(images{i}, imgPath, 'png');            
            end
            fprintf('Saved image %s.\n', imgPath);
        end
    end
end

return
% /---------------------------------------------------------------------/ % 




% /---------------------------------------------------------------------/ % 
function params = meshCompareScansParams(V, dt, savePath, leg);
% put up a dialog to get the scans and settings for meshCompareScans.
mrGlobals;
msh = viewGet(V, 'currentMesh');

% first check that there are saved settings:
settingsFile = fullfile(fileparts(msh.path),'MeshSettings.mat');
if ~exist(settingsFile,'file')
    myErrorDlg(['Sorry, you need to save some mesh settings first. ' ...
               'Use the menu Edit | Save Camer Angles | Save in ' ...
               'the 3D Window, or the meshAngle function.']);
end

load(settingsFile, 'settings');

% build dialog
scanList = {dataTYPES(dt).scanParams.annotation};
for i = 1:length(scanList)
    scanList{i} = sprintf('(%i) %s', i, scanList{i});
end
dlg(1).fieldName = 'scans';
dlg(1).style = 'listbox'; 
dlg(1).string = 'Take images of which scans?';
dlg(1).list = scanList;
dlg(1).value = 1;

dlg(2).fieldName = 'settings';
dlg(2).style = 'listbox'; 
dlg(2).string = 'Take a picture at which camera settings?';
dlg(2).list = {settings.name};
dlg(2).value = 1;

dlg(3).fieldName = 'savePath';
dlg(3).style = 'filenamew'; 
dlg(3).string = 'Save Image as? (Empty=no save)';
dlg(3).value = savePath;    

dlg(4).fieldName = 'leg';
dlg(4).style = 'checkbox'; 
dlg(4).string = 'Include Colorbar';
dlg(4).value = leg;    

% put up dialog
params = generalDialog(dlg, 'Mesh Multi-Angle');
if isempty(params)
    error('User aborted.')
end

% parse params
for s = 1:length(params.scans)
    tmp(s) = cellfind(dlg(1).list, params.scans{s});
end
params.scans = tmp;

return
