function [vw h] = grayMenu(vw)
% Add a menu with gray-matter-specific options to a mrVista view.
%
% [vw, menuHandle] = grayMenu([vw=cur view]);
%
% This menu includes both the options for gray/white segmentation
% previously stored in the segmentationMenu, as well as mesh-related
% options kept in the 3D Window.   I wrote this because there were
% consistent issues with the GUIDE implementation of the 3D Window that
% kept resurfacing for me, and I'd been successful at using menus to control 
% meshesin the mrVista 2 mrViewer app.
%
% ras, 11/04/2007.
if notDefined('vw'),		vw = getCurView;		end

% get the handle for the figure menu
if checkfields(vw, 'ui', 'windowHandle')
	figHandle = vw.ui.windowHandle;
else
	figHandle = gcf;
end

% make the main gray menu
h = uimenu(figHandle, 'Label', 'Gray');
vw.ui.menus.gray = h;

% I break up the previous segmentation menu options into 2 sub-menus:
% one related to installing / reinstalling segmentations, a second for
% installing a new flat map.  These are added to all view types.
vw.ui.menus.segmentation = submenu_segmentation(vw);
vw.ui.menus.flat = submenu_flat(vw);

% for volume/gray views, also add mesh options
if ismember(vw.viewType, {'Volume', 'Gray'})
	vw.ui.menus.meshFiles = submenu_meshFiles(vw);
	
	% option to update mesh display
	cb = [vw.name ' = meshColorOverlay(' vw.name '); '];
	uimenu(h, 'Label', 'Update Mesh', 'Callback', cb, ...
			  'Enable', 'off', 'Accelerator', '0');
		  
	% option to update all mesh displays
	cb = [vw.name ' = meshUpdateAll(' vw.name '); '];
	uimenu(h, 'Label', 'Update All Meshes', 'Callback', cb, ...
			  'Enable', 'off', 'Accelerator', '9');
	
	% option to toggle cursor visibility
	cb = sprintf('meshToggleCursor( viewGet(%s, ''Mesh'' ) ); ', vw.name);
	uimenu(h, 'Label', 'Toggle Mesh Cursor', 'Callback', cb, ...
			  'Enable', 'off', 'Accelerator', '/');
		  
	% option to toggle ROI mask
	cb = sprintf(['%s = viewSet(%s, ''showROIsOnMesh'', 1 - viewGet(%s, ''showROIsOnMesh'' ) ); \n',...
                  '%s = meshColorOverlay(%s);'],...
                  vw.name, vw.name,vw.name, vw.name, vw.name);
	uimenu(h, 'Label', 'Toggle Mesh ROI mask', 'Callback', cb, ...
			  'Enable', 'off');

                  
    vw.ui.menus.meshOptions = submenu_meshOptions(vw);
	vw.ui.menus.meshInflate = submenu_meshInflate(vw);
	vw.ui.menus.meshROIs = submenu_meshROIs(vw);
	vw.ui.menus.meshImages = submenu_meshImages(vw);
		
	vw.ui.menus.meshSelected = submenu_meshSelected(vw);
	vw.ui.menus.meshSettings = submenu_meshSettings(vw);	
end

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_segmentation(vw)
% this submenu allows users to install or reinstall a segmentation, 
% and view the segmentation files.
h = uimenu(vw.ui.menus.gray, 'Label', 'Gray/White Segmentation', ...
		   'Separator', 'off');
	   
% Install new segmentation
% (By default, this keeps only the gray nodes where there is functional
% data)
uimenu(h, 'Label', 'Install or Reinstall Segmentation', 'Separator', 'off', ...
		'Callback', 'installSegmentation;');
	   
% Install new segmentation (save all gray matter nodes)
uimenu(h, 'Label', 'Install or Reinstall Segmentation (keep all gray nodes)', ...
        'Separator', 'off', 'Callback', 'installSegmentation(1, 1);');
    
% Check segmentation info
uimenu(h, 'Label', 'Segmentation info', 'Separator','off',...
		'Callback', sprintf('segmentInfo(%s); ',vw.name));
	

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_flat(vw)
% this submenu allows users to install new flat patches / unfolds for the
% flat view.
h = uimenu(vw.ui.menus.gray, 'Label', 'Flat Patch', ...
		   'Separator', 'off');

% Install new unfold
uimenu(h, 'Label', 'Install New Unfold', 'Separator', 'off', ...
       'Callback', 'newFlat; ');
 
% Re-install existing unfold:
% If flat view, pass arg to specify which flat to re-install
% Otherwise, user will be prompted to pick one of the flat subdirectories
if strcmp(vw.viewType,'Flat')
    cb = sprintf('installUnfold(%s); ', vw.subdir);
else
    cb = 'installUnfold;';
end
uimenu(h, 'Label', 'Reinstall unfold', 'Separator', 'off', 'Callback', cb);

% Create Flat Patch from ROI:
if ismember(vw.viewType, {'Volume' 'Gray'})
	uimenu(h, 'Label', 'Create Flat Patch from Center of Current ROI', ...
			'Separator', 'on', 'Callback', ['flattenFromROI(' vw.name ');']);
end

% Verify Gray-Flat correspondence callback:
if strcmp(vw.viewType,'Flat')
    uimenu(h, 'Label', 'Verify Gray-Flat match', 'Separator', 'off', ...
        'Callback', sprintf('checkCoordsNodes(%s); ',vw.name));
end

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_meshFiles(vw)
% This submenu allows the user to load, close, display, and build new 
% meshes.
h = uimenu(vw.ui.menus.gray, 'Label', 'Surface Mesh', 'Separator', 'on');

%% load and display mesh                          
cb = sprintf('%s = meshLoad(%s, [], 1);', vw.name, vw.name);
uimenu(h, 'Label', 'Load and Display', 'Callback', cb, 'Accelerator', ',');

%% build new mesh options
hBuild = uimenu(h, 'Label', 'Build New Mesh');

% LH
cb = sprintf(['%s = meshBuild(%s, ''left'');  ' ...
			  'MSH = meshVisualize( viewGet(%s, ''Mesh'') ); ', ...
			  '%s = viewSet(%s, ''Mesh'', MSH); clear MSH; '], ...
			  vw.name, vw.name, vw.name, vw.name, vw.name);
uimenu(hBuild, 'Label', 'Left Hemisphere', 'Callback', cb);	

% RH
cb = sprintf(['%s = meshBuild(%s, ''right'');  ' ...
			  'MSH = meshVisualize( viewGet(%s, ''Mesh'') ); ', ...
			  '%s = viewSet(%s, ''Mesh'', MSH); clear MSH; '], ...
			  vw.name, vw.name, vw.name, vw.name, vw.name);
uimenu(hBuild, 'Label', 'Right Hemisphere', 'Callback', cb);	
                    
%% save selected mesh
cb = ['mrmWriteMeshFile( viewGet(' vw.name ', ''Mesh''), ' ...
						'viewGet(' vw.name ', ''MeshDir'') );'];
uimenu(h, 'Label', 'Save Selected Mesh', 'Callback', cb, 'Separator', 'on');                    

%% load w/o displaying
cb = sprintf('%s = meshLoad(%s);', vw.name, vw.name);
uimenu(h, 'Label', 'Load without displaying', 'Callback', cb);

%% display only
cb = sprintf(['MSH = meshVisualize( viewGet(%s, ''Mesh'') ); ' ...
			  '%s = viewSet(%s, ''Mesh'', MSH); clear MSH '], ...
			  vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Display Selected Mesh', 'Callback', cb, 'Separator', 'on');
                
%% close mesh display
cb = sprintf('%s = meshCloseWindow(%s); ', vw.name, vw.name);
uimenu(h, 'Label', 'Close Mesh Display', 'Callback', cb, 'Separator', 'off');

%% close selected mesh
cb = sprintf('%s = meshDelete(%s, viewGet(%s, ''CurMeshNum'') ); ', ...
			vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Close Mesh and Remove from view', 'Callback', cb, ...
		'Separator', 'on');

%% close all meshes
cb = sprintf('%s = meshDelete(%s, inf); ', vw.name, vw.name);
uimenu(h, 'Label', 'Remove / Close All Meshes', 'Callback', cb);


return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_meshSelected(vw)
% This submenu creates a menu in which to store the handles for selecting
% different meshes, once they've been loaded.
h = uimenu(vw.ui.menus.gray, 'Label', 'Selected Mesh...', ...
		  'Separator', 'off', 'Enable', 'off');

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_meshSettings(vw)
% This submenu will contain options for setting / editing mesh view
% settings. This may be the trickiest one to implement.
h = uimenu(vw.ui.menus.gray, 'Label', ' Mesh View Settings', ...
			'Tag', 'MeshSettingsList', ...
			'Separator', 'off', 'Enable', 'off');

						  
%% store current view settings
cb = sprintf('meshStoreSettings( viewGet(%s, ''Mesh'') ); ', vw.name);
uimenu(h, 'Label', 'Store Current View Settings', 'Callback', cb);						  

%% load view settings for this hemisphere
cb = sprintf('meshSettingsList( viewGet(%s, ''Mesh'') ); ', vw.name);
uimenu(h, 'Label', 'Reload View Settings for this hemisphere', ...
			'Callback', cb);						  

%% rename view settings
cb = sprintf('meshRenameSettings( viewGet(%s, ''Mesh'') ); ', vw.name);
uimenu(h, 'Label', 'Rename View Settings', 'Callback', cb);						  

%% delete view settings
cb = sprintf('meshDeleteSettings( viewGet(%s, ''Mesh'') ); ', vw.name);
uimenu(h, 'Label', 'Delete View Settings', 'Callback', cb);						  

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function h = submenu_meshOptions(vw)
% This submenu will contain options for specifying mesh view settings, such
% as the display preferences, background, etc.
h = uimenu(vw.ui.menus.gray, 'Label', 'Mesh Display Options', ...
                              'Separator', 'on');
	
%% set mesh prefs						  
uimenu(h, 'Label', 'Set Mesh Preferences', 'Accelerator', '.', ...
	   'Callback', 'mrmPreferences');						  

%% Take mesh snapshot	
cb = ['img = mrmGet( viewGet(%s, ''Mesh''), ''screenshot'' ) ./ 255; ' ...
	  'hTmp = figure(''Color'', ''w''); ' ...
	  'imagesc(img); axis image; axis off; ' ...
	  'try, figToCB(hTmp); end; clear hTmp; '...
	  'disp(''Image copied to clipboard as well as variable "img".'')'];
cb = sprintf(cb, vw.name);
uimenu(h, 'Label', 'Copy Mesh Image to Clipboard', 'Callback', cb);						  
   
   
%% set the mesh background color
hBgColor = uimenu(h, 'Label', 'Set background color...');

% individual callbacks for different colors
colors = {[0 0 0], [.3 .3 .3], [1 1 1], [0 .1 .8]};                                
names = {'black' 'gray' 'white' 'blue'};
for i = 1:length(colors)
	cb = sprintf('mrmSet( viewGet(%s, ''Mesh''), ''background'', [%s]); ', ...
				 vw.name, num2str(colors{i}));
	
    uimenu(hBgColor(1), 'Label', names{i}, 'UserData', colors{i}, ...
		'Separator', 'off', 'Callback', cb);
end

% recolor sulcul/gyral curvature
cb = [sprintf('msh = viewGet(%s, ''CurMesh''); ', vw.name) ...
	 'msh = meshColor(msh, 1); ' ...
	 sprintf('%s = viewSet(%s, ''CurMesh'', msh); ', vw.name, vw.name) ...
	 sprintf('meshColorOverlay(%s); ', vw.name) ...
	 'clear msh ']; 
uimenu(h, 'Label', 'Set Sulcus/Gyrus Modulation', 'Callback', cb);

%% Set lighting parameters
cb = sprintf('%s = meshLighting(%s);', vw.name, vw.name);
uimenu(h, 'Label', 'Set Lighting Levels', 'Callback', cb);						  

%% mesh movie options
h_tmp = uimenu(h, 'Label', 'Create Mesh Movie...');

% hide ROIs
cb = sprintf('MESHMOVIE = meshMovie(%s, 0, ''dialog'');', vw.name);
uimenu(h_tmp, 'Label', 'Hide ROIs', 'Callback', cb);

% use view's ROI settings
cb = sprintf('MESHMOVIE = meshMovie(%s, -1, ''dialog'');', vw.name);
uimenu(h_tmp, 'Label', 'Use current ROI settings', 'Callback', cb);

% show cursor ROIs
cb = sprintf('MESHMOVIE = meshMovie(%s, 3, ''dialog'');', vw.name);
uimenu(h_tmp, 'Label', 'Show disc around cursor', 'Callback', cb);

%% Recompute vertex -> gray map
cb = ['MSH = viewGet(%s, ''Mesh''); ' ...
	  'vertexGrayMap = mrmMapVerticesToGray( ' ...
	  'meshGet(MSH, ''initialvertices''), '...
				    'viewGet(%s, ''nodes''), ' ...
				    'viewGet(%s, ''mmPerVox''), ' ...
					'viewGet(%s, ''edges'') ); ' ...
	  'MSH = meshSet(MSH, ''vertexgraymap'', vertexGrayMap); ' ...
	  '%s = viewSet(%s, ''Mesh'', MSH); ' ...
	  'clear MSH vertexGrayMap '];
cb = sprintf(cb, vw.name, vw.name, vw.name, vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Recompute vertex / gray map', 'Callback', cb, 'Separator', 'on');  
								
								
return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function h = submenu_meshInflate(vw)
% This submenu contains mesh-related operations, such as inflating /
% de-inflating the mesh.
h = uimenu(vw.ui.menus.gray, 'Label', 'Inflate', ...
            'Enable', 'off', 'Separator', 'off');
		
cb = '%s = viewSet( %s, ''Mesh'', meshSmooth( viewGet(%s, ''Mesh''), 1) ); ';
cb = sprintf(cb, vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Inflate (Set Params)', 'Callback', cb);

cb = '%s = viewSet( %s, ''Mesh'', meshSmooth( viewGet(%s, ''Mesh'')) ); ';
cb = sprintf(cb, vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Inflate Mesh (Use Stored Params)', 'Callback', cb);
                    
                        
cb = ['MSH = viewGet(%s, ''Mesh''); ' ...
      'MSH = meshSet(MSH, ''Vertices'', meshGet(MSH, ''InitialVertices'')); ' ...
      'MSH = meshSet(MSH, ''Smooth_Relaxation'', 0); ' ...
      'mrmSet(MSH, ''Vertices''); ' ...
      '%s = viewSet(%s, ''CurMesh'', MSH); ' ...
      'clear MSH '];
cb = sprintf(cb, vw.name, vw.name, vw.name);  
uimenu(h, 'Label', 'Uninflate (Revert to Initial Vertices)', 'Callback', cb);
  
return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function h = submenu_meshROIs(vw)
% This submenu contains options related to selecting ROIs with the mesh
% (either by using the 'd' key/draw functionality, or by double-clicking to
% place the cursor, and setting a disk radius about the cursor).
h = uimenu(vw.ui.menus.gray, 'Label', 'Mesh ROIs', ...
		  'Enable', 'off', 'Separator', 'off');

%% Cursor-related options
% synch the view's cursor position with the mesh cursor
cb = ['pos = meshCursor2Volume(%s); ' ...
	  '%s = viewSet(%s, ''CursorPosition'', pos); ' ...
	  '%s = refreshScreen(%s); '];
cb = sprintf(cb, vw.name, vw.name, vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Get Cursor Position From Mesh', 'Callback', cb);

% create a disk ROI around the mesh cursor
cb = ['pos = meshCursor2Volume(%s);' ...
	  '%s = makeROIdiskGray(%s, [], [], [], [], pos); '];
cb = sprintf(cb, vw.name, vw.name, vw.name);
uimenu(h, 'Label', 'Create Disk ROI Around Cursor', 'Callback', cb);

% grow a mesh ROI around the cursor
% create a disk ROI around the mesh cursor
cb = '%s = meshGrowROI(%s); ';
cb = sprintf(cb, vw.name, vw.name);
uimenu(h, 'Label', 'Grow Gray Matter Patch ROI From Cursor', 'Callback', cb);

%% Mesh ROI options
% NOTE: the callbacks here are based on the 3D Window, and assumes that
% this view is the selected Volume view (using selectedVOLUME).
% once this menu is used more often, update the callback.  
cb = ['meshROI2Volume([], 2); ' ...
	  sprintf('%s.ROIs(%s.selectedROI) = roiSortLineCoords(%s); ', ...
			  vw.name, vw.name, vw.name) ...
	  sprintf('setROIPopup(%s); ', vw.name)];
uimenu(h, 'Label', 'Get Line ROI From Mesh (drawn with "d" key, Layer 1)', ...
		  'Separator', 'on', 'Callback', cb);


uimenu(h, 'Label', 'Get ROI From Mesh (drawn with "d" key, Layer 1)', ...
		  'Separator', 'on', 'Callback', 'meshROI2Volume([], 2);');

uimenu(h, 'Label', 'Get ROI From Mesh (drawn with "d" key, All Layers)', ...
		  'Callback', 'meshROI2Volume([], 3);', 'Accelerator', ' ');	  
	  
return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function h = submenu_meshImages(vw)
% this submenu allows users to create images that are composites of
% multiple mesh images, for easy comparisons of maps on the mesh surface.
h = uimenu(vw.ui.menus.gray, 'Label', 'Mesh Images', ...
		   'Enable', 'off', 'Separator', 'off');
	   
%% mesh multi-angle snapshot
cb = sprintf('MESHIMAGE = meshMultiAngle( viewGet(%s, ''Mesh'') ); ', vw.name);    
uimenu(h, 'Label', 'Multi-Angle Snapshot', 'Separator', 'off', 'Callback', cb);   
								
%% mesh images across scans			
cb = sprintf('MESHIMAGES = meshCompareScans(%s); ', vw.name);    
uimenu(h, 'Label', 'Mesh Images Across Scans', 'Separator', 'off', ...
		'Callback', cb);   
								
%% mesh event-related amplitude maps
cb=['[MESHIMAGES MAPVALS] = meshAmplitudeMaps(' vw.name ', 1);'];
uimenu(h, 'Label', 'Condition Amplitude Maps (needs parfiles)', ...
		'Separator', 'off', 'CallBack', cb);

return
