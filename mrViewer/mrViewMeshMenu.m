function ui = mrViewMeshMenu(ui);
%
% ui = mrViewMeshMenu(ui);
%
% Attaches a mesh menu to a mrViewer UI. Initializes
% it to be hidden, until a segmentation is loaded.
%
% ras 07/05.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.mesh = uimenu(ui.fig, 'Label', 'Mesh');


%%%%%mesh build, display, close options
hFile = uimenu(ui.menus.mesh, 'Label', 'Build \ Open \ Close', ...
                              'Separator', 'off');
                          
cb = 'mrViewLoad(gcf, [], ''Mesh''); mrViewDisplayMesh; ';
ui.menus.meshLoadDisp = uimenu(hFile, 'Label', 'Load and Display', ...
                        'Callback', cb);

ui.menus.meshBuild = uimenu(hFile, 'Label', 'Build Mesh', ...
                        'Separator', 'on', 'Callback', 'mrViewBuildMesh; ');
                    
ui.menus.meshSave = uimenu(hFile, 'Label', 'Save Selected Mesh', ...
                        'Callback', 'mrViewSave(gcf, [], ''Mesh''); ');                    

ui.menus.meshDisp = uimenu(hFile, 'Label', 'Display Selected Mesh', ...
                        'Callback', 'mrViewDisplayMesh;');
                       
cb = 'mrmSet( mrViewGet(gcf, ''CurMesh''), ''Close'' ); ';
ui.menus.meshCloseDisp = uimenu(hFile, 'Label', 'Close Mesh Display', ...
                        'Callback', cb);

ui.menus.meshClose = uimenu(hFile, 'Label', 'Close Mesh', ...
                        'Callback', 'mrViewCloseMesh(gcf);');
                    
%%%%%project data onto mesh options
ui.menus.meshUpdate = uimenu(ui.menus.mesh, 'Label', 'Project Data Onto Mesh', ...
                            'Separator', 'on', 'Callback', 'mrViewMesh(gcf); ');
ui.menus.meshUpdateAll = uimenu(ui.menus.mesh, 'Label', 'Update All Meshes', ...
                            'Separator', 'off', 'Callback', 'mrViewUpdateAllMeshes; ', ...
                            'Accelerator', '0');
                         
%%%%%mesh smooth, revert options
hInflate = uimenu(ui.menus.mesh, 'Label', 'Inflation', 'Separator', 'on');

cb = ['tmp = mrViewGet(gcf, ''CurMesh''); ' ...
      'tmp = meshSmooth(tmp); ' ...
      'mrViewSet(gcf, ''CurMesh'', tmp); ' ...
      'clear tmp '];
ui.menus.meshSmooth = uimenu(hInflate, 'Label', 'Inflate Mesh', ...
                        'Separator', 'off', 'Callback', cb);
                    
cb = ['tmp = mrViewGet(gcf, ''CurMesh''); ' ...
      'tmp = meshSmooth(tmp, 1); ' ...
      'mrViewSet(gcf, ''CurMesh'', tmp); ' ...
      'clear tmp '];
ui.menus.meshSmooth2 = uimenu(hInflate, 'Label', 'Inflate (Set Params)', ...
                                        'Callback', cb);
                        
cb = ['tmp = mrViewGet(gcf, ''CurMesh''); ' ...
      'tmp = meshSet(tmp, ''Vertices'', meshGet(tmp, ''InitialVertices'')); ' ...
      'tmp = meshSet(tmp, ''Smooth_Relaxation'', 0); ' ...
      'mrmSet(tmp, ''Vertices''); ' ...
      'mrViewSet(gcf, ''CurMesh'', tmp); ' ...
      'clear tmp '];
ui.menus.meshRevert = uimenu(hInflate, 'Label', 'Revert to InitVertices', ...
                                       'Callback', cb);
                            

                                   
%%%%%display tools (screenshot, multi-angle, movie)
hDisp = uimenu(ui.menus.mesh, 'Label', 'Display Tools', 'Separator', 'off');



ui.menus.meshPrefs = uimenu(hDisp, 'Label', 'Set Mesh Preferences', ...
                            'Accelerator', '.', 'Callback', 'mrmPreferences');

ui.menus.meshToggleCursor = uimenu(hDisp, 'Label', 'Toggle Cursor', ...
						'Accelerator', '/', ...
						'Callback', 'meshToggleCursor(mrViewGet(gcf, ''mesh''));');

% recolor sulcul/gyral curvature
cb = ['msh = mrViewGet(gcf, ''CurMesh''); ' ...
	 'msh = meshColor(msh, 1); ' ...
	 'mrViewSet(gcf, ''CurMesh'', msh); ' ...
	 'mrViewMesh(gcf); '...
	 'clear msh ']; 
uimenu(hDisp, 'Label', 'Set Sulcus/Gyrus Modulation', 'Callback', cb);

% Set lighting parameters
uimenu(hDisp, 'Label', 'Set Lighting Levels', 'Callback', 'mrViewMeshLighting;');						  

% Take mesh snapshot	
cb = ['img = mrmGet( mrViewGet(gcf, ''Mesh''), ''screenshot'' ) ./ 255; ' ...
	  'hTmp = figure(''Color'', ''w''); ' ...
	  'imagesc(img); axis image; axis off; ' ...
	  'try, figToCB(hTmp); end; clear hTmp; '...
	  'disp(''Image copied to clipboard as well as variable "img".'')'];
uimenu(hDisp, 'Label', 'Copy Mesh Image to Clipboard', 'Callback', cb);						  
					
ui.menus.meshBgColor = uimenu(hDisp, 'Label', 'Set background color...');
                                
% individual callbacks for different colors
colors = {[0 0 0], [.3 .3 .3], [1 1 1], [0 .1 .8]};                                
names = {'black' 'gray' 'white' 'blue'};
for i = 1:length(colors)
    ui.menus.meshBgColor(i+1) = uimenu(ui.menus.meshBgColor(1), ...
        'Label', names{i}, 'UserData', colors{i}, 'Separator', 'off', ...
        'Callback', 'mrViewSet(gcf, ''MeshBackground'', gcbo); ');
end

cb = 'meshMultiAngle2(mrViewGet(gcf, ''CurMesh''), ''dialog''); ';    
ui.menus.meshMultiAngle = uimenu(hDisp, 'Label', 'Multi-Angle Snapshot', ...
                                    'Separator', 'off', 'Callback', cb);
  
cb = ['VOLUME{1}.mesh{1} = mrViewGet(gcf, ''mesh''); ' ...
	  'meshMovie(VOLUME{1}); ' ...
	  'VOLUME{1}.mesh = {}; '];								
ui.menus.meshMovie = uimenu(hDisp, 'Label', 'Mesh Movie', ...
						'Separator', 'off', 'Callback', cb);
  
								


%%%%%ROI tools 
hRoi = uimenu(ui.menus.mesh, 'Label', 'Mesh ROIs', 'Separator', 'off');
              
ui.menus.meshCursor = uimenu(hRoi, 'Label', 'Get Cursor Position From Mesh', ...
						'Callback', 'mrViewSetCursorFromMesh(gcf); ');

ui.menus.meshROI1 = uimenu(hRoi, 'Label', 'Get From Mesh (Layer 1)', ...
						'Callback', 'mrViewROI(''mesh'', gcf, ''layer1'');');

ui.menus.meshROI2 = uimenu(hRoi, 'Label', 'Get From Mesh (All Layers)', ...
						'Callback', 'mrViewROI(''mesh'', gcf, ''all'');');

ui.menus.diskROI = uimenu(hRoi, 'Label', 'Create Disk ROI', ...
							'Callback', 'mrViewROI(''disk'', gcf);');
                 
                                
%%%%%select segmentation submenu 
% (will be added to in mrViewLoad([], [], 'segmentation'))
ui.menus.meshSeg = uimenu(ui.menus.mesh, 'Label', 'Selected Segmentation', ...
                          'Separator', 'on');


%%%%%select mesh submenu (will be added to in mrViewLoad([], [], 'mesh'))
ui.menus.meshSelect = uimenu(ui.menus.mesh, 'Label', 'Selected Mesh', ...
                             'Separator', 'off');

                                                   

% initialize to invisible, until a segmentation is loaded                        
set(ui.menus.mesh, 'Visible', 'off');

return                        
                    