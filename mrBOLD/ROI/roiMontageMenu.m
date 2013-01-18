function view=roiMontageMenu(view)
% 
% view=roiMenu(view)
%
% version of ROI menu for montage (inplane, flat level) views.
% callbacks call versions of ROI creation / display function
% that take into account display of multiple images at once.
%
% djh, 1/10/98
% rmk, 10/30/98 added combineROIs option
% rmk, 1/14/99 added overlay restrict option
% rfd, 3/31/99 added perimeter ROIs option
% rfd, 4/07/99 added  FlatAnat ROI to "Create" submenu
% huk, 4/15/99 added keyboard shortcuts
% bw   5/14/99 added line ROI to FLAT view
% bw   8/8/00  added disk ROI to FLAT view
% djh  2/15/01 added gray ROI to GRAY view
%              cleaned up to allow for multiple windows of each viewType
% fwc  12/07/02 added deleteMultipleROIs, combineMultipeROIsWithCurrent
% aab  2003.12.18 added combineMultipleROIsIntoOneROI
% ras  2004.09 broken off from roiMenu
%      Why did you break it off? -- BW

roimenu = uimenu('Label','ROI','Separator','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create ROI submenu

createROImenu = uimenu(roimenu,'Label','Create','Separator','off');

% Create Rectangle ROI with default name callback
%   view=newROI(view);
%   view=addROIrectMontage(view,1);
%   view=refreshScreen(view,1);
cb = [ view.name,'=newROI(',view.name,'); ',...
	view.name,'=addROIrectMontage(',view.name,',1); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(createROImenu,'Label','Create Rectangle ROI','Separator','off',...
    'Callback',cb,'Accelerator','r');

% Create Polygon ROI with default name callback
%   view=newROI(view);
%   view=addROIpolyMontage(view,1);
%   view=refreshScreen(view,0);
cb = [ view.name,'=newROI(',view.name,'); ',...
	view.name,'=addROIpolyMontage(',view.name,',1); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(createROImenu,'Label','Create Polygon ROI','Separator','off',...
    'Callback',cb,'Accelerator','p');

if strcmp(view.viewType,'Inplane')
	% Create Polygon ROI with default name callback
	%   view=makeSliceROI(view);
	%   view=refreshScreen(view,0);
	cb = [ view.name,'=makeSliceROI(',view.name,'); ',...
		view.name,'=refreshScreen(',view.name,',0);'];
      uimenu(createROImenu,'Label','Create ROI, Selected Slice','Separator','off',...
        'Callback',cb);
end

% create Blob (3D grow) ROI
cb = [sprintf('%s = newROI(%s); ', view.name, view.name) ...
      sprintf('%s = addROIgrow(%s); ', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 0);', view.name, view.name)];
uimenu(createROImenu, 'Label', 'Create Blob ROI (3D grow)', ...
        'Separator', 'off', 'Accelerator', 'B', 'Callback', cb);

% create point ROI
cb = [sprintf('%s = makePointROI(%s); ', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 0);', view.name, view.name)];
uimenu(createROImenu, 'Label', 'Create Point ROI', ...
        'Separator', 'off', 'Callback', cb);

% create Blob (3D grow) ROI
cb = [sprintf('%s = newROI(%s); ', view.name, view.name) ...
      sprintf('%s = addROIgrow(%s,[],1); ', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 0);', view.name, view.name)];
uimenu(createROImenu, 'Label', 'Create Blob ROI (3D grow) and fill holes', ...
        'Separator', 'off', 'Callback', cb);

% makeGrayROI callback:
%   view=makeGrayROI(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=makeGrayROI(',view.name,'); ',...
        view.name,'=refreshScreen(',view.name,',0);'];
uimenu(createROImenu,'Label','Create Gray ROI','Separator','off',...
    'Callback',cb);
    
if strcmp(view.viewType,'Volume') | strcmp(view.viewType,'Gray')
    % Create disk ROI with default name callback
    %    view=makeROIdiskGray(view);
    %    view=refreshScreen(view,0);
    cb= [view.name,'=makeROIdiskGray(',view.name,'); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI',...
        'Separator','off',...
        'Callback',cb);
end

if ismember(view.viewType, {'Volume' 'Gray' 'Inplane'})
    % Create disk ROI with default name callback
    %    view=makeROIdiskGray(view);
    %    view=refreshScreen(view,0);
    cb= [view.name,'=makeROIdiskGray(',view.name,',[],[],[],[],''roi''); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI (from center of cur ROI)',...
        'Separator', 'off', 'Callback', cb);    
end

    
if strcmp(view.viewType,'Flat')
    % Create Line ROI with default name callback
    %    view=newROI(view);
    %    view=addROIlineMontage(view,1);
    %    view=refreshScreen(view,0);
    cb = [view.name,'=newROI(',view.name,'); ',...
            view.name,'=addROIlineMontage(',view.name,',1); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(createROImenu,'Label','Create Line ROI','Separator','off',...
        'Callback',cb,'Accelerator','l');
    
    % Create disk ROI with default name callback
    %    view=makeROIdiskFlat(view);
    %    view=refreshScreen(view,0);
    cb= [view.name,'=makeROIdiskFlat(',view.name,'); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI',...
        'Separator','off',...
        'Callback',cb);
end

% Create  ROI from selected functional data
%   view=makeROIfromSelectedVoxels(view);
%   view=refreshScreen(view,0);
cb = [sprintf('%s = makeROIfromSelectedVoxels(%s); ', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 0);', view.name, view.name)];
uimenu(createROImenu, 'Label', 'Create ROI from functional mask', ...
        'Separator', 'off', 'Callback', cb);

  
% New ROI callback:
%   view=newROI(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=newROI(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(createROImenu,'Label','Create empty ROI','Separator','off',...
    'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Talairach ROI submenu

if strcmp(view.viewType,'Volume') | strcmp(view.viewType,'Gray')
    talmenu = uimenu(roimenu,'Label','Talairach','Separator','off');
    
    % Enter Talairach coords callback:
    %   view=findTalairachVolume(view);
    %   view=refreshScreen(view,0);
    cb = [view.name,'=findTalairachVolume(',view.name,'); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(talmenu,'Label','Enter Talairach coords','Separator','off',...
        'Callback',cb);
    
    % Load Talairach coords from file callback:
    %    view=installTalairachCoordinates(view);
    %    view=refreshScreen(view,0);
    cb= [view.name,'=installTalairachCoordinates(',view.name,'); ',...
            view.name,'=refreshScreen(',view.name,',0);'];
    uimenu(talmenu,'Label','Load Talairach coords from file',...
        'Separator','off',...
        'Callback',cb);
    
    % Compute Talairach coords callback:
    %    vol2talairachVolume(view);
    cb= ['vol2talairachVolume(',view.name,');'];
    uimenu(talmenu,'Label','Compute Talairach coords',...
        'Separator','off',...
        'Callback',cb);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Delete ROI submenu

deleteROImenu = uimenu(roimenu,'Label','Delete','Separator','off');

%Delete Selected ROI callback
%   view = deleteROI(view,view.selectedROI);
%   view=refreshScreen(view,0);
cb = [view.name,...
	'=deleteROI(',view.name,',',view.name,'.selectedROI); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(deleteROImenu,'Label','Delete ROI','Separator','off',...
    'Callback',cb,'Accelerator','d');

% Delete Multiple ROIs callback
%   view = deleteMultipleROIs(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=deleteMultipleROIs(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
   uimenu(deleteROImenu,'Label','Delete Many ROIs','Separator','off',...
    'Callback',cb);


% Delete All ROIs callback
%   view = deleteAllROIs(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=deleteAllROIs(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
   uimenu(deleteROImenu,'Label','Delete All ROIs','Separator','off',...
    'Callback',cb,'Accelerator','k');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add ROI submenu

addROImenu = uimenu(roimenu,'Label','Add','Separator','off');

% Add Rectangle 
%   view=addROIrectMontage(view,1);
%   view=refreshScreen(view,1);
cb = [ view.name,'=addROIrectMontage(',view.name,',1); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(addROImenu,'Label','Add Rectangle','Separator','off',...
    'Callback',cb,'Accelerator','e');

% Add Polygon
%   view=addROIpolyMontage(view,1);
%   view=refreshScreen(view,0);
cb = [ view.name,'=addROIpolyMontage(',view.name,',1); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(addROImenu,'Label','Add Polygon','Separator','off',...
    'Callback',cb,'Accelerator','o');

% Add/Remove Points callback
%   view=addROIpointsMontage(view);
%   view=refreshScreen(view);
cb = [ view.name,'=addROIpointsMontage(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(addROImenu,'Label','Add/Remove Points','Separator','off',...
    'Callback',cb,'Accelerator','i');

if strcmp('Flat',view.viewType)
  % Add Line to ROI
  % view=addROIlineMontage(view,1);
  % view=refreshScreen(view,0);
  cb = [ view.name,'=addROIlineMontage(',view.name,',1); ',...
	  view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(addROImenu,'Label','Add Line','Separator','off',...
      'Callback',cb);
end

% add point to ROI
cb = [sprintf('%s = makePointROI(%s, [], 0); ', view.name, view.name) ...
      sprintf('%s = refreshScreen(%s, 0);', view.name, view.name)];
uimenu(addROImenu, 'Label', 'Add point to selected ROI', ...
        'Separator', 'off', 'Callback', cb);

% if strcmp(view.viewType,'Inplane')
  % Add and grow callback
  %   view=addROIgrow(view);
  %   view=refreshScreen(view);
  cb = [ view.name,'=addROIgrow(',view.name,'); ',...
                view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(addROImenu,'Label','Add blob (3D grow)','Separator','off',...
         'Callback',cb);
% end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove ROI submenu

removeROImenu = uimenu(roimenu,'Label','Remove/Clear','Separator','off');

% Remove Rectangle callback
%   view=addROIrectMontage(view,0);
%   view=refreshScreen(view,0);
cb = [ view.name,'=addROIrectMontage(',view.name,',0); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Remove Rectangle','Separator','off',...
    'Callback',cb,'Accelerator','v');

% Remove Polygon callback
%   view=addROIpolyMontage(view,0);
%   view=refreshScreen(view,0);
cb = [ view.name,'=addROIpolyMontage(',view.name,',0); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Remove Polygon','Separator','off',...
    'Callback',cb);

% Add/Remove Points callback
%   view=addROIpointsMontage(view);
%   view=refreshScreen(view);
cb = [ view.name,'=addROIpointsMontage(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Add/Remove Points','Separator','off',...
    'Callback',cb,'Accelerator','i');

% Clear Slice callback
%   view=clearROIslice(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'=clearROIslice(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI Slice','Separator','off',...
    'Callback',cb);

% Clear ROI, all slices, callback
%   view=clearROI(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'=clearROIall(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI All Slices','Separator','off',...
    'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restrictROImenu = uimenu(roimenu,'Label','Restrict','Separator','off');

% Restrict ROI callback
%   view=restrictROIfromMenu(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'= restrictROIfromMenu(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(restrictROImenu,'Label','Restrict Selected ROI','Separator','off',...
    'Callback',cb,'Accelerator','x');

% Restrict All ROIs callback
%   view=restrictAllROIsfromMenu(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'= restrictAllROIsfromMenu(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(restrictROImenu,'Label','Restrict All ROIs','Separator','off',...
    'Callback',cb);

if strcmp(view.viewType,'Inplane')
  % Remove growth region
  %   view=addROIpoints(view);
  %   view=refreshScreen(view);
  cb = [ view.name,'=addROIgrow(',view.name,',0); ',...
                view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(removeROImenu,'Label','Remove and grow Points (3D)','Separator','off',...
         'Callback',cb);
end;


% Restrict To Gray callback
%   view=restrictRoiToGray(view,view.selectedROI);
%   view=refreshScreen(view,0);
cb = sprintf('%s = restrictRoiToGray(%s,%s.selectedROI);',...
             view.name,view.name,view.name);
cb = sprintf('%s \n %s = refreshScreen(%s,0);',cb,view.name,view.name);         
uimenu(restrictROImenu,'Label','Restrict To Gray','Separator','off',...
    'Callback',cb);

% Clear Slice callback
%   view=clearROIslice(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'=clearROIslice(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI Slice','Separator','off',...
    'Callback',cb);

% Clear ROI, all slices, callback
%   view=clearROI(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'=clearROIall(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI All Slices','Separator','off',...
    'Callback',cb);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit ROI menu

editROImenu = uimenu(roimenu,'Label','Select/Edit/Combine','Separator','off');

% Edit ROI Name/Color callback
%   view=editROIFields(view);
%   setROIPopup(view);
cb = [ view.name,'=editROIFields(',view.name,'); ',...
	'setROIPopup(',view.name,');'];
uimenu(editROImenu,'Label','Edit ROI Name/Color','Separator','off',...
    'Callback',cb,'Accelerator','n');

% Undo Last Modification callback
%   view=undoLastROImodif(view);
%   view=refreshScreen(view,0);
cb = [ view.name,'=undoLastROImodif(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(editROImenu,'Label','Undo Last Modification','Separator','off',...
    'Callback',cb,'Accelerator','z');


% Select ROI callback:
%   view = chooseROIwithMouseMontage(view);
%   view=refreshScreen(view,0);
cb = ['n=chooseROIwithMouseMontage(',view.name,'); ',...
	view.name,'=selectROI(',view.name,',n); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(editROImenu,'Label','Select ROI','Separator','off',...
    'Callback',cb);
%end

% combine ROI callback:
%   view = combineROIs(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=combineROIs(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(editROImenu,'Label','Combine ROIs','Separator','off',...
    'Callback',cb,'Accelerator','2');

% combine multiple ROIs with the selected ROI callback:
%   view = combineMultROIsWithCurrent(view);
%   view=refreshScreen(view,0);
cb = [view.name,'=combineMultROIsWithCurrent(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(editROImenu,'Label','Combine Multiple ROIs with current','Separator','off',...
    'Callback',cb);

% combine multiple ROIs into one callback:
% function [view,OK] = combineMultROIsIntoOneROI(view)
%   view=refreshScreen(view,0);
cb = [view.name,'=combineMultROIsIntoOneROI(',view.name,'); ',...
	view.name,'=refreshScreen(',view.name,',0);'];
uimenu(editROImenu,'Label','Combine Multiple ROIs into One ROI','Separator','off',...
    'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show ROIs submenu

showROIsMenu = uimenu(roimenu,'Label','Hide/Show ROIs','Separator','off');

% Set ROI Options callback:
% view = viewSet(view,'roiOptions');
cb = sprintf('%s = viewSet(%s,''roiOptions'');',view.name,view.name);
uimenu(showROIsMenu,'Label','Set ROI Options','Separator','off',...
        'Callback',cb,'Accelerator','3');

% Hide All ROIs callback
%   view.ui.showROIs = 0;
%   view=refreshScreen(view,0);
cb = [view.name,'.ui.showROIs=0; ',...
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(showROIsMenu,'Label','Hide ROIs','Separator','off',...
    'Callback',cb,'Accelerator','h');

% Show Selected ROI callback
%   view.ui.showROIs = -1;
%   view.ui.roiDrawMethod = 'boxes';
%   view=refreshScreen(view,0);
cb = [view.name,'.ui.showROIs = -1; ',...
      view.name '.ui.roiDrawMethod = ''perimeter''; ' ...    
	view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(showROIsMenu,'Label','Show Selected ROI boxes','Separator','off',...
    'Callback',cb);

% Show All ROIs callback
%   view.ui.showROIs = -2;
%   view.ui.roiDrawMethod = 'boxes';
%   view=refreshScreen(view,0);
cb = [view.name,'.ui.showROIs = -2; ', ...
      view.name '.ui.roiDrawMethod = ''boxes''; ' ...    
	  view.name,'=refreshScreen(',view.name,',0);'];
  uimenu(showROIsMenu,'Label','Show All ROIs boxes', ...
        'Callback',cb);

% Show Selected ROI Perimeter callback
%   view.ui.showROIs = -1;
%   view.ui.roiDrawMethod = 'perimeter';
%   view=refreshScreen(view,0);
cb = [view.name '.ui.showROIs = -1; ' ...
      view.name '.ui.roiDrawMethod = ''perimeter''; ' ...
      view.name,'=refreshScreen(',view.name,',0);'];
uimenu(showROIsMenu,'Label','Show Selected ROI Perimeter','Separator','off',...
    'Callback',cb,'Accelerator','s');

% Show All ROIs Perimeter callback
%   view.ui.showROIs = -2;
%   view.ui.roiDrawMethod = 'perimeter';
%   view=refreshScreen(view,0);
cb = [view.name,'.ui.showROIs = -2; ',...
      view.name '.ui.roiDrawMethod = ''perimeter''; ' ...    
	  view.name,'=refreshScreen(',view.name,',0);'];
uimenu(showROIsMenu,'Label','Show All ROIs Perimeter','Separator','off',...
    'Callback',cb,'Accelerator','a');

% Set filled perimeter
%   roiToggleFilledPerimeter(view);
%   view = refreshScreen(view,0);
cb = [view.name,'=roiToggleFilledPerimeter(',view.name,'); ',...
    view.name,'=refreshScreen(',view.name,',0);'];
uimenu(showROIsMenu,'Label','Toggle Perimeter Method','Separator','off',...
        'Callback',cb);


return;
