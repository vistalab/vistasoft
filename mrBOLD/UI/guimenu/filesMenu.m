function view=filesMenu(view)
%
% view=filesMenu(view)
%
% Set up the callbacks for the FILE menu
%
% djh, 1/9/98
% arw, 06/15/15 Check for altered graphic handle behavior in R2014b onwards
mrGlobals

% create the file menu
fileMenu = uimenu('Label','File','separator','on');

% Load Anatomies callback:
%  view=loadAnat(view);
%  view=refreshScreen(view);
cb = [view.name,'=loadAnat(',view.name,'); ',...
    view.name,'=refreshScreen(',view.name,');'];
uimenu(fileMenu, 'Label', 'Reload Anatomies', 'Separator', 'off', ...
    'Callback',cb);

% Change vAnatomyPath callback:
%  vANATOMYPATH = setvAnatomyPath;
cb = ['vANATOMYPATH = setVAnatomyPath; ' ...
	  'fprintf(''New Volume Anatomy Path: %s\n'', vANATOMYPATH); '];
uimenu(fileMenu, 'Label', 'Select Volume Anatomy', ...
    'Separator', 'off', 'Callback',cb);

% Report current vAnatomyPath callback:
%  msgbox(['Reference Anatomy Path: ' getVAnatomyPath], ''getVAnatomyPath''); 
cb = ['msgbox([''Reference Anatomy Path: '' getVAnatomyPath], ''getVAnatomyPath''); '];
uimenu(fileMenu, 'Label', 'Report Current Volume Anatomy', ...
    'Separator', 'off', 'Callback',cb);


%%%%%attach submenus
corAnalSubmenu(fileMenu, view);
parMapSubmenu(fileMenu, view);
fileMenuROI = roiSubmenu(fileMenu, view);
retinoModelSubmenu(fileMenu, view);
% mrFilesSubmenu(fileMenu, fileMenuROI, view);

% %%%%%more individual options

% savePrefs(view);
cb=['savePrefs(',view.name,');'];
uimenu(fileMenu, 'Label', 'Save Preferences ', 'Separator', 'on', ...
		'Callback', cb);

% Write tiff callback:
%  writeTiffImage(view);
cb = ['writeTiffImage(',view.name,');'];
uimenu(fileMenu, 'Label', 'Write Tiff Image', 'Separator', 'off',...
    'Callback', cb);

if isequal(view.viewType, 'Volume')
	% publish 3-view option
    uimenu(fileMenu, 'Label', 'Publish Figure', ...
        'Separator', 'off', 'Callback', sprintf('publish3View(%s); ', view.name));    
end

%% RAS, 09/2008: commented this out, since we haven't used mrAlign for some
%% time. This will go away soon, unless someone mentions they need it.
% % Load Alignment callback:
% %   loadAlignment;
% if strcmp(view.viewType,'Inplane')
%     uimenu(fileMenu, 'Label', 'Load mrAlign Alignment', 'Separator', 'off',...
%         'Callback', 'loadAlignment');
% end

% Save mrSESSION file
uimenu(fileMenu, 'Label', 'Save mrSESSION', 'Separator', 'off',...
    'Callback', 'saveSession');

% (re-)create Readme.txt
cb=['mrCreateReadme'];
uimenu(fileMenu,'Label','(Re-)create Readme.txt','Separator','off',...
    'Callback',cb);

% Quit
if (verLessThan('matlab','8.4')) % Figure handle behavior changed in 2015
    cb = ['close(',num2str(view.ui.figNum),'); mrvCleanWorkspace;'];
else
    cb = ['close(',num2str(view.ui.figNum.Number),'); mrvCleanWorkspace;'];
end

uimenu(fileMenu,'Label','Quit ','Separator','on', 'Callback',cb);


return
% /---------------------------------------------------------------------/ %





% /---------------------------------------------------------------------/ %
function corAnalSubmenu(fileMenu, view);
% Attach Submenu for CorAnal options.
fileMenuCorAnal = uimenu(fileMenu,'Label','CorAnal','Separator','off');

% Load CorAnal callback:
%  view = loadCorAnal(view);
%  view = refreshScreen(view);
cb = [view.name,'=loadCorAnal(',view.name,'); ',...
      view.name,'=refreshScreen(',view.name,'); '];
uimenu(fileMenuCorAnal, 'Label', 'Load CorAnal', 'Separator', 'off', ...
		'Callback', cb);

% Load CorAnal (select file) callback:
%  view = loadCorAnal(view, 'ask');
%  view = refreshScreen(view);
cb = [view.name,' = loadCorAnal(',view.name,', ''ask''); ',...
      view.name,' = refreshScreen(',view.name,'); '];
uimenu(fileMenuCorAnal, 'Label', 'Load CorAnal (select file)', 'Separator', 'off', ...
		'Callback', cb);

% Save CorAnal callback:
%  saveCorAnal(view);
cb = ['saveCorAnal(',view.name,'); '];
uimenu(fileMenuCorAnal, 'Label', 'Save CorAnal', 'Separator', 'off', ...
		'Callback',cb);

% Save CorAnal (select file) callback:
%  saveCorAnal(view, 'ask');
cb = ['saveCorAnal(',view.name,', ''ask''); '];
uimenu(fileMenuCorAnal, 'Label', 'Save CorAnal (select file)', 'Separator', 'off', ...
		'Callback', cb);


return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function parMapSubmenu(fileMenu, view);
% Attach a submenu w/ Parameter Map options.
fileMenuMap = uimenu(fileMenu,'Label','Parameter Map','Separator','off');

% Load Parameter Map callback:
%  view=loadParameterMap(view);
cb = [view.name,' = loadParameterMap(',view.name,'); ' ...
	  view.name, '= refreshScreen(' view.name '); '];
uimenu(fileMenuMap,'Label','Load Parameter Map ','Separator','off',...
    'Accelerator', 'j', 'Callback', cb);


% Save Parameter Map callback:
%  saveParameterMap(view);
cb = ['saveParameterMap(',view.name,');'];
uimenu(fileMenuMap,'Label', 'Save Parameter Map ', 'Separator', 'off',...
    'Callback', cb);

% Save Parameter Map callback:
%  saveParameterMap(view);
cb = ['saveParameterMap(',view.name,', mrvSelectFile(''w'', ''.mat''));'];
uimenu(fileMenuMap,'Label', 'Save Parameter Map As...', 'Separator', 'off',...
    'Callback', cb);


% Load coherence map (scale)
cb = sprintf('%s = loadCoherenceMap(%s, [], 1); ', view.name, view.name);
uimenu(fileMenuMap,'Label', 'Load Parameter Map into Co field (scale)', 'Separator', 'on',...
    'Callback', cb);

% Load coherence map (divide by 100)
cb = sprintf('%s = loadCoherenceMap(%s, [], 2); ', view.name, view.name);
uimenu(fileMenuMap,'Label', 'Load Parameter Map into Co field (divide by 100)', ...
		'Separator', 'off', 'Callback', cb);

% Load coherence map (raw)
cb = sprintf('%s = loadCoherenceMap(%s, [], 0); ', view.name, view.name);
uimenu(fileMenuMap,'Label', 'Load Parameter Map into Co field (raw values)', ...
		'Separator', 'off', 'Callback', cb);

% Transfer Parameter Map into Coherence field callback:
%  view=loadParameterMap(view);
cb=[view.name,'=loadParameterMapintoCoherenceMap(',view.name,');'];
uimenu(fileMenuMap, 'Callback', cb, 'Separator', 'off', ...
	'Label', 'Transfer current map into co field (abs(p)/max(abs(p)))');

% Load Spatial Gradient callback:
%  view=loadSpatialGradient(view);
cb=[view.name,'=loadSpatialGradient(',view.name,');'];
uimenu(fileMenuMap, 'Separator', 'on', 'Callback', cb, ...
	'Label', 'Load Spatial Gradient for Inhomogeneity Correction');

% if ismember(view.viewType, {'Volume' 'Gray'})
%     % Load laminar distance map:
%     cb = [view.name, '= loadLaminae(', view.name, ');'];
%     uimenu(fileMenuMap, 'Label', 'Load laminar distance map',...
%         'Separator', 'off', 'Callback', cb);
% end

% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function fileMenuROI = roiSubmenu(fileMenu, view);
% Attach a submenu w/ ROI options
fileMenuROI = uimenu(fileMenu,'Label','ROI','Separator','off');

% Load ROI (shared) callback:
%  filename=getROIfilename(view);
%  view=loadROI(view,filename);
%  view=refreshScreen(view,0);
if ismember(view.viewType, {'Gray' 'Volume'})
    % Load from a default location specified by a global preference
    % VISTA.defaultROIDir
    cb=[view.name,'=loadROI(',view.name,',''dialog'',[],[],1,0); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(fileMenuROI,'Label', 'Load ROI (shared) ', 'Separator', 'off', ...
        'Callback', cb);

    % Save the ROI to a default directory. Note that you >might< not have
    % permission to do this depending on how your filesystem is set up. The
    % standard ROIs are somewhat precious.
    % Save ROI callback:
    %  saveROI(view,view.ROIs(view.selectedROI));
    cb=['saveROI(',view.name,',',view.name,'.ROIs(',view.name,'.selectedROI),0);'];
    uimenu(fileMenuROI,'Label','Save ROI (shared)','Callback',cb);

    % Save All ROIs local:
    %  saveAllROIs(view);
    cb=['saveAllROIs(',view.name,', 0);'];
    uimenu(fileMenuROI,'Label','Save All ROIs (shared) ','Callback',cb);
end % End check on viewType


% Load ROI (local) callback:
if ismember(view.viewType, {'Volume' 'Gray'})
    cb = sprintf(['%s = loadROI(%s, ''dialog'', [], [], 1, 1); ' ...
        '%s = selectCurROISlice(%s); ' ...
        '%s = refreshScreen(%s); '], view.name, view.name, ...
        view.name, view.name, view.name, view.name); 
else
    cb = sprintf(['%s = loadROI(%s, ''dialog'', [], [], 1, 1); ' ...
        '%s = refreshScreen(%s); '], view.name, view.name, ...
        view.name, view.name); 

end
uimenu(fileMenuROI, 'Label', 'Load ROI (local)', 'Separator', 'on', ...
    'Callback', cb, 'Accelerator', 'L');

% Save ROI local:
%  saveROI(view, 'selected', 1);
cb = sprintf( 'saveROI(%s, ''selected'', 1);', view.name );
uimenu(fileMenuROI, 'Label', 'Save ROI (local)', 'Callback', cb);

% Save All ROIs local:
%  saveAllROIs(view);
cb=['saveAllROIs(',view.name,', 1);'];
uimenu(fileMenuROI,'Label','Save All ROIs (local)', 'Callback', cb);


if isequal(view.viewType, 'Inplane')
    % allow an option to quickly load and xform a volume ROI
    cb = sprintf('%s = roiLoadVol2Inplane(%s); ', view.name, view.name);
    uimenu(fileMenuROI, 'Label', 'Load + Xform Volume ROI', ...
        'Separator', 'off', 'Callback', cb);
end



% Browse for an ROI file:
uimenu(fileMenuROI, 'Label', 'Browse for ROI file', 'Separator', 'on', ...
    'Callback', sprintf('loadExternalROI(%s); ', view.name));

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function retinoModelSubmenu(fileMenu, view);
fileMenuRM = uimenu(fileMenu,'Label','Retinotopy Model','Separator','off');

% Retinotopy model callback
% It consists of two phases (a) select retinotopic file (.mat) and
% (b) select (and load) parameter into mrVista interface

% Select retinotopy model file
callBackstr=[view.name ' = rmSelect(',view.name,', 2); ' ...
		     view.name ' = rmLoadDefault(' view.name '); '];
uimenu(fileMenuRM, 'Label', 'Select and Load Model', 'Separator', 'off',...
		'CallBack', callBackstr, 'Accelerator', '8');

% Load retinotopy model parameter in interface
callBackstr=[view.name ' = rmLoad(' view.name '); '...
		     view.name ' = refreshScreen(' view.name '); '];
uimenu(fileMenuRM,'Label','Load Model Parameter','Separator','off',...
    'CallBack',callBackstr);

% Load all retinotopy model parameters
callBackstr=[view.name '= rmLoadDefault(',view.name,');'];
uimenu(fileMenuRM,'Label','Load Model Default Parameters','Separator','off',...
    'CallBack',callBackstr);

% Load all retinotopy model parameters
callBackstr=[view.name '= rmLoadAsWedgeRing(',view.name,');'];
uimenu(fileMenuRM,'Label','Load Model Parameters as if Wedge/Ring','Separator','off',...
    'CallBack',callBackstr);

% model info
callBackstr=['rmInfo(',view.name,');'];
uimenu(fileMenuRM,'Label','Model information','Separator','on',...
    'CallBack',callBackstr);

% stim info
callBackstr=['rmStimInfo(',view.name,');'];
uimenu(fileMenuRM,'Label','Stimulus information','Separator','off',...
    'CallBack',callBackstr);

% Clear model
callBackstr=[view.name '= rmClearSettings(',view.name,');'];
uimenu(fileMenuRM,'Label','Clear','Separator','on',...
    'CallBack',callBackstr);

return;
