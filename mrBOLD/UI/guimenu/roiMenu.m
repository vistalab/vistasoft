function vw = roiMenu(vw)
% 
% vw = roiMenu(vw)
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
% ras  2004.11.08 changed s and a accelerators to show perimeter
% arw  2005.08.24 Added multi-point line ROIs
% ras  2007.01.11 Updating ROI display options: new roiDrawMethod field
% jw   2008.09.04 Added call to create ROI from pRF plot or ph v coh plot 
% jw   2009.1.27  Removed callbacks to export ROIs for itkGray. Moved them
%                   to xFormMenu to be consistent with existing calls to
%                   export ROIs for mrGray 
% jw   6/2009     Added 'Restrict to layer 1'

roimenu = uimenu('Label','ROI','Separator','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create ROI submenu

createROImenu = uimenu(roimenu,'Label','Create','Separator','off');

% Create Rectangle ROI with default name callback
%   vw=newROI(vw);
%   vw=addROIrect(vw,1);
%   vw=refreshScreen(vw,1);
cb=[ vw.name,'=newROI(',vw.name,'); ',...
	vw.name,'=addROIrect(',vw.name,',1); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(createROImenu,'Label','Create Rectangle ROI','Separator','off',...
    'Callback',cb,'Accelerator','r');

% Create Polygon ROI with default name callback
%   vw=newROI(vw);
%   vw=addROIpoly(vw,1);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=newROI(',vw.name,'); ',...
	vw.name,'=addROIpoly(',vw.name,',1); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(createROImenu,'Label','Create Polygon ROI','Separator','off',...
    'Callback',cb,'Accelerator','p');

if strcmp(vw.viewType,'Inplane')
	% Create Polygon ROI with default name callback
	%   vw=makeSliceROI(vw);
	%   vw=refreshScreen(vw,0);
	cb=[ vw.name,'=makeSliceROI(',vw.name,'); ',...
		vw.name,'=refreshScreen(',vw.name,',0);'];
      uimenu(createROImenu,'Label','Create ROI, Selected Slice',...
          'Separator', 'off', 'Callback', cb);
end

% create point ROI
cb = [sprintf('%s = makePointROI(%s); ', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 0);', vw.name, vw.name)];
uimenu(createROImenu, 'Label', 'Create Point ROI', ...
        'Separator', 'off', 'Callback', cb);

% create Blob (3D grow) ROI
cb = [sprintf('%s = newROI(%s); ', vw.name, vw.name) ...
      sprintf('%s = addROIgrow(%s); ', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 0);', vw.name, vw.name)];
uimenu(createROImenu, 'Label', 'Create Blob ROI (3D grow)', ...
        'Separator', 'off', 'Accelerator', 'B', 'Callback', cb);

if ismember(vw.viewType,{'Volume' 'Gray'})
    % makeGrayROI callback:
    %   vw=makeGrayROI(vw);
    %   vw=refreshScreen(vw,0);
    cb=[vw.name,'=makeGrayROI(',vw.name,'); ',...
        vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Gray ROI','Separator','off',...
        'Callback',cb);

    % Create disk ROI with default name callback
    %    vw=makeROIdiskGray(vw);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIdiskGray(',vw.name,'); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI (choose start point)',...
        'Separator', 'on', 'Callback', cb);
    
    % Create disk ROI with default name callback
    %    vw=makeROIdiskGray(vw);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIdiskGray(',vw.name,',[],[],[],[],''roi''); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI (from center of cur ROI)',...
        'Separator', 'off', 'Callback', cb);    
end

if strcmp(vw.viewType,'Gray') | strcmp(vw.viewType,'Volume') | strcmp(vw.viewType,'Inplane')
    % Create sphere ROI from clicked point
    %    vw=makeROIsphere(vw);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIsphere(',vw.name,'); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Sphere ROI (choose start point)',...
        'Separator', 'on', 'Callback', cb);

    % Create sphere ROI from center of current ROI
    %    vw=makeROIsphere(vw,[],'roi');
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIsphere(',vw.name,',[],''roi''); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Sphere ROI (from center of ROI)',...
        'Separator', 'off', 'Callback', cb);
    
end

if strcmp(vw.viewType,'Gray') | strcmp(vw.viewType,'Volume')
    % Create sphere ROI from current position
    %    vw=makeROIsphere(vw,[],vw.loc);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIsphere(',vw.name,',[],''curloc''); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Sphere ROI (from current position)',...
        'Separator', 'off', 'Callback', cb);
    
    % Create ROI from range of values in parameter map
    %   vw=CreateROIFromRange(vw, range);
    %   vew=refreshScreen(vw,0);
    cb= [vw.name,'=CreateROIFromRange(',vw.name,',[]); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create ROI from range of values',...
        'Separator', 'off', 'Callback', cb);
end

    
if strcmp(vw.viewType,'Flat')
    % Create Line ROI with default name callback
    %    vw=newROI(vw);
    %    vw=addROIline(vw,1);
    %    vw=refreshScreen(vw,0);
    cb=[vw.name,'=newROI(',vw.name,'); ',...
            vw.name,'=addROIline(',vw.name,',1); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Line ROI','Separator','off',...
        'Callback',cb,'Accelerator','l');
    
    % Create Multi-point line ROI with default name callback

    cb=[vw.name,'=newROI(',vw.name,'); ',...
            vw.name,'=addROICurvedline(',vw.name,',1); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Multi-point Line ROI','Separator','off',...
        'Callback',cb);
        
        
    % Create disk ROI with default name callback
    %    vw=makeROIdiskFlat(vw);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=makeROIdiskFlat(',vw.name,'); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(createROImenu,'Label','Create Disk ROI',...
        'Separator','off',...
        'Callback',cb);
end

if strcmp(vw.viewType,'Inplane')
  % Create grow ROI with default name callback
  %   vw=newROI(vw);
  %   vw=addROIpoly(vw,1);
  %   vw=refreshScreen(vw,0);
  cb=[ vw.name,'=newROI(',vw.name,'); ',...
                vw.name,'=addROIgrow(',vw.name,',1); ',...
                vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(createROImenu,'Label','Create and grow ROI (3D)','Separator','off',...
         'Callback',cb);
end; 

% Create  ROI from selected functional data
%   vw=makeROIfromSelectedVoxels(vw);
%   vw=refreshScreen(vw,0);
cb = [sprintf('%s = makeROIfromSelectedVoxels(%s); ', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 0);', vw.name, vw.name)];
uimenu(createROImenu, 'Label', 'Create ROI from functional mask', ...
        'Separator', 'off', 'Callback', cb);

% New ROI callback:
%   vw=newROI(vw);
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=newROI(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(createROImenu,'Label','Create empty ROI','Separator','off',...
    'Callback',cb);

% Create ROI from pRF plot (needs ret model and cur ROI)
callback = [sprintf('%s = plotEccVsPhase(%s, [], [], 1); ' ,vw.name , vw.name)...
            sprintf('%s = plotEccVsPhase(%s, [], [], 0); ' ,vw.name , vw.name)];
uimenu(createROImenu, 'Label', 'Create ROI from pRF plot (requires current ret model & ROI)', ...
	'Separator', 'on', 'CallBack', callback);

% Create ROI from ph vs coh plot (needs coranal and cur ROI)
callback = [sprintf('plotCorVsPhase(%s, [], 1); ' ,vw.name)...
            sprintf('plotCorVsPhase(%s, [], 0); ' ,vw.name)];
uimenu(createROImenu, 'Label', 'Create ROI from ph vs coh plot (requires current coranal & ROI)', ...
	'Separator', 'off', 'CallBack', callback);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Talairach ROI submenu

if strcmp(vw.viewType,'Volume') | strcmp(vw.viewType,'Gray')
    talmenu = uimenu(roimenu,'Label','Talairach','Separator','off');
    
    % Enter Talairach coords callback:
    %   vw=findTalairachVolume(vw);
    %   vw=refreshScreen(vw,0);
    cb=[vw.name,'=findTalairachVolume(',vw.name,'); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(talmenu,'Label','Enter Talairach coords','Separator','off',...
        'Callback',cb);
    
    % Load Talairach coords from file callback:
    %    vw=installTalairachCoordinates(vw);
    %    vw=refreshScreen(vw,0);
    cb= [vw.name,'=installTalairachCoordinates(',vw.name,'); ',...
            vw.name,'=refreshScreen(',vw.name,',0);'];
    uimenu(talmenu,'Label','Load Talairach coords from file',...
        'Separator','off',...
        'Callback',cb);
    
    % Compute Talairach coords callback:
    %    vol2talairachVolume(vw);
    cb= ['vol2talairachVolume(',vw.name,');'];
    uimenu(talmenu,'Label','Compute Talairach coords',...
        'Separator','off',...
        'Callback',cb);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Delete ROI submenu

deleteROImenu = uimenu(roimenu,'Label','Delete','Separator','off');

%Delete Selected ROI callback
%   vw = deleteROI(vw,vw.selectedROI);
%   vw=refreshScreen(vw,0);
cb=[vw.name,...
	'=deleteROI(',vw.name,',',vw.name,'.selectedROI); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(deleteROImenu,'Label','Delete ROI','Separator','off',...
    'Callback',cb,'Accelerator','d');

% Delete Multiple ROIs callback
%   vw = deleteMultipleROIs(vw);
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=deleteMultipleROIs(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
   uimenu(deleteROImenu,'Label','Delete Many ROIs','Separator','off',...
    'Callback',cb);


% Delete All ROIs callback
%   vw = deleteAllROIs(vw);
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=deleteAllROIs(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
   uimenu(deleteROImenu,'Label','Delete All ROIs','Separator','off',...
    'Callback',cb,'Accelerator','k');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add ROI submenu

addROImenu = uimenu(roimenu,'Label','Add','Separator','off');

% Add Rectangle 
%   vw=addROIrect(vw,1);
%   vw=refreshScreen(vw,1);
cb=[ vw.name,'=addROIrect(',vw.name,',1); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(addROImenu,'Label','Add Rectangle','Separator','off',...
    'Callback',cb,'Accelerator','e');

% Add Polygon
%   vw=addROIpoly(vw,1);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=addROIpoly(',vw.name,',1); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(addROImenu,'Label','Add Polygon','Separator','off',...
    'Callback',cb,'Accelerator','o');

% Add/Remove Points callback
%   vw=addROIpoints(vw);
%   vw=refreshScreen(vw);
cb=[ vw.name,'=addROIpoints(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(addROImenu,'Label','Add/Remove Points','Separator','off',...
    'Callback',cb,'Accelerator','i');

% add point to ROI
cb = [sprintf('%s = makePointROI(%s, [], 0); ', vw.name, vw.name) ...
      sprintf('%s = refreshScreen(%s, 0);', vw.name, vw.name)];
uimenu(addROImenu, 'Label', 'Add point to selected ROI', ...
        'Separator', 'off', 'Callback', cb);

% if strcmp(vw.viewType,'Inplane')
  % Add and grow callback
  %   vw=addROIgrow(vw);
  %   vw=refreshScreen(vw);
  cb=[ vw.name,'=addROIgrow(',vw.name,'); ',...
                vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(addROImenu,'Label','Add blob (3D grow)','Separator','off',...
         'Callback',cb);
% end;

if strcmp('Flat',vw.viewType)
  % Add Line to ROI
  % vw=addROIline(vw,1);
  % vw=refreshScreen(vw,0);
  cb=[ vw.name,'=addROIline(',vw.name,',1); ',...
	  vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(addROImenu,'Label','Add Line','Separator','off',...
      'Callback',cb);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove ROI submenu

removeROImenu = uimenu(roimenu,'Label','Remove/Clear','Separator','off');

% Remove Rectangle callback
%   vw=addROIrect(vw,0);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=addROIrect(',vw.name,',0); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(removeROImenu,'Label','Remove Rectangle','Separator','off',...
    'Callback',cb,'Accelerator','v');

% Remove Polygon callback
%   vw=addROIpoly(vw,0);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=addROIpoly(',vw.name,',0); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(removeROImenu,'Label','Remove Polygon','Separator','off',...
    'Callback',cb);

% Add/Remove Points callback
%   vw=addROIpoints(vw);
%   vw=refreshScreen(vw);
cb=[ vw.name,'=addROIpoints(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(removeROImenu,'Label','Add/Remove Points','Separator','off',...
    'Callback',cb,'Accelerator','i');

if strcmp(vw.viewType,'Inplane')
  % Remove growth region
  %   vw=addROIpoints(vw);
  %   vw=refreshScreen(vw);
  cb=[ vw.name,'=addROIgrow(',vw.name,',0); ',...
                vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(removeROImenu,'Label','Remove and grow Points (3D)','Separator','off',...
         'Callback',cb);
end;

% Restrict To Gray callback
%   vw=restrictRoiToGray(vw,vw.selectedROI);
%   vw=refreshScreen(vw,0);
cb = sprintf('%s = restrictRoiToGray(%s,%s.selectedROI);',...
             vw.name,vw.name,vw.name);
cb = sprintf('%s \n %s = refreshScreen(%s,0);',cb,vw.name,vw.name);         
uimenu(removeROImenu,'Label','Restrict To Gray','Separator','off',...
    'Callback',cb);


% Clear Slice callback
%   vw=clearROIslice(vw);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=clearROIslice(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI Slice','Separator','off',...
    'Callback',cb);

% Clear ROI, all slices, callback
%   vw=clearROI(vw);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=clearROIall(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(removeROImenu,'Label','Clear ROI All Slices','Separator','off',...
    'Callback',cb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restrictROImenu = uimenu(roimenu,'Label','Restrict','Separator','off');

% Restrict ROI callback
%   vw=restrictROIfromMenu(vw);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'= restrictROIfromMenu(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(restrictROImenu,'Label','Restrict Selected ROI','Separator','off',...
    'Callback',cb,'Accelerator','x');

% Restrict All ROIs callback
%   vw=restrictAllROIsfromMenu(vw);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'= restrictAllROIsfromMenu(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(restrictROImenu,'Label','Restrict All ROIs','Separator','off',...
    'Callback',cb);

% Restrict To Gray callback
%   vw=restrictRoiToGray(vw,vw.selectedROI);
%   vw=refreshScreen(vw,0);
cb = sprintf('%s = restrictRoiToGray(%s,%s.selectedROI);',...
             vw.name,vw.name,vw.name);
cb = sprintf('%s \n %s = refreshScreen(%s,0);',cb,vw.name,vw.name);         
uimenu(restrictROImenu,'Label','Restrict To Gray','Separator','off',...
    'Callback',cb);

% Restrict To Layer 1 callback
%   vw=roiRestrictByLayer(vw,vw.selectedROI,1);
%   vw=refreshScreen(vw,0);
cb = sprintf('%s = roiRestrictByLayer(%s,%s.selectedROI,1);',...
             vw.name,vw.name,vw.name);
cb = sprintf('%s \n %s = refreshScreen(%s,0);',cb,vw.name,vw.name);         
uimenu(restrictROImenu,'Label','Restrict To Layer 1','Separator','off',...
    'Callback',cb);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Edit ROI menu

editROImenu = uimenu(roimenu,'Label','Select/Edit/Combine','Separator','off');

% Edit ROI Name/Color callback
%   vw=editROIFields(vw);
%   setROIPopup(vw);
cb=[ vw.name,'=editROIFields(',vw.name,'); ',...
	'setROIPopup(',vw.name,');'];
uimenu(editROImenu,'Label','Edit ROI Name/Color','Separator','off',...
    'Callback',cb,'Accelerator','n');

% Undo Last Modification callback
%   vw=undoLastROImodif(vw);
%   vw=refreshScreen(vw,0);
cb=[ vw.name,'=undoLastROImodif(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(editROImenu,'Label','Undo Last Modification','Separator','off',...
    'Callback',cb,'Accelerator','z');


% Select ROI callback:
%   vw = chooseROIwithMouse(vw);
%   vw=refreshScreen(vw,0);
%
% We don't think this works properly, and it is less convenient than the
% pulldown on the right, so we deleted it.  The bug is that it selects
% properly in the 3window in  Ant<->Pos, but not in the other windows.
% Perhaps it works in the original one view window 'Gray'? -- BW
%
% cb=['n=chooseROIwithMouse(',vw.name,'); ',...
% 	vw.name,'=selectROI(',vw.name,',n); ',...
% 	vw.name,'=refreshScreen(',vw.name,',0);'];
%   uimenu(editROImenu,'Label','Select ROI','Separator','off',...
%     'Callback',cb,'Accelerator','1');
%end

% combine ROI callback:
%   vw = combineROIs(vw);
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=combineROIs(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(editROImenu,'Label','Combine ROIs','Separator','off',...
    'Callback',cb,'Accelerator','2');

% combine multiple ROIs with the selected ROI callback:
%   vw = combineMultROIsWithCurrent(vw);
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=combineMultROIsWithCurrent(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(editROImenu,'Label','Combine Multiple ROIs with current','Separator','off',...
    'Callback',cb);

% combine multiple ROIs into one callback:
% function [vw,OK] = combineMultROIsIntoOneROI(vw)
%   vw=refreshScreen(vw,0);
cb=[vw.name,'=combineMultROIsIntoOneROI(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(editROImenu,'Label','Combine Multiple ROIs into One ROI','Separator','off',...
    'Callback',cb);

% This call to mrv_dilateCurrentROI has been replaced by a call to a new
% function, roiDilate. The former seems not to work.
%
% if (strcmp(vw.viewType,'Volume') & (strcmp(vw.viewType,'Volume')))
%     cb=[vw.name,'=mrv_dilateCurrentROI(',vw.name,'); ',...
%         vw.name,'=refreshScreen(',vw.name,',0);'];
%     uimenu(editROImenu,'Label','Dilate current ROI','Separator','off',...
%         'Callback',cb);
% end
 
if strcmpi(vw.viewType,'volume')
     cb=[vw.name,'=roiDilate(',vw.name,'); ',... 	 
         vw.name,'=refreshScreen(',vw.name,',0);']; 	 
     uimenu(editROImenu,'Label','Dilate current ROI','Separator','off',... 	 
     'Callback',cb); 	 
 end
 
 % split ROIs into equal bins
 cb=[vw.name,'=roiSplitToBins(',vw.name,'); ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(editROImenu,'Label','Split selected ROI into equal bins','Separator','off',...
    'Callback',cb);

 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show ROIs submenu

% The show 
showROIsMenu = uimenu(roimenu,'Label','Hide/Show ROIs','Separator','off');

% Set ROI Options callback:
% vw = viewSet(vw,'roiOptions');
cb = sprintf('%s = viewSet(%s,''roiOptions'');',vw.name,vw.name);
uimenu(showROIsMenu,'Label','Set ROI Options','Separator','off',...
        'Callback',cb,'Accelerator','3');


% Hide All ROIs callback
%   vw.ui.showROIs=0;
%   vw=refreshScreen(vw,0);
cb=[vw.name,'.ui.showROIs=0; ',...
    'updateGlobal(' vw.name '); '...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(showROIsMenu, 'Label', 'Hide ROIs', 'Separator', 'off', ...
            'Callback', cb, 'Accelerator', 'h');

%% submenu for selecting which ROIs to show
showSubmenu = uimenu(showROIsMenu, 'Label', 'Show Which ROIs...');

% Select ROIs for display callback
%   vw = roiSelectDisplay(vw);
%   vw = refreshScreen(vw,0);
%   INPLANE = roiSelectDisplay(INPLANE);
cb=[vw.name,'=roiSelectDisplay(',vw.name,');',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(showSubmenu,'Label','Select display ROIs', 'Callback', cb);

% Show Selected ROI callback
%   vw.ui.showROIs = -1;
%   vw.ui.roiDrawMethod = 'boxes';
%   vw=refreshScreen(vw,0);
cb = [vw.name,'.ui.showROIs = -1; ',...
	vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(showSubmenu,'Label','Show Selected ROIs','Accelerator','S',...
    'Callback',cb);

% Show All ROIs callback
%   vw.ui.showROIs = -2;
%   vw=refreshScreen(vw,0);
cb = [vw.name,'.ui.showROIs = -2; ', ...
	  vw.name,'=refreshScreen(',vw.name,',0);'];
  uimenu(showSubmenu,'Label','Show All ROIs', 'Accelerator', 'A', ...
        'Callback',cb);
    
%% submenu for quickly setting rendering method
methodSubmenu = uimenu(showROIsMenu, 'Label', 'Drawing Method');

% boxes
cb = sprintf('%s.ui.roiDrawMethod = ''boxes''; %s = refreshScreen(%s); ', ...
             vw.name, vw.name, vw.name);
uimenu(methodSubmenu, 'Label', 'Boxes around each pixel', 'Callback', cb);

% perimeter
cb = sprintf('%s.ui.roiDrawMethod = ''perimeter''; %s = refreshScreen(%s); ', ...
             vw.name, vw.name, vw.name);
uimenu(methodSubmenu, 'Label', 'Perimeter', 'Callback', cb);

% filled perimeter
cb = sprintf('%s.ui.roiDrawMethod = ''filled perimeter''; %s = refreshScreen(%s); ', ...
             vw.name, vw.name, vw.name);
uimenu(methodSubmenu, 'Label', '''Filled'' Perimeter', 'Callback', cb);

% translucent patches
cb = sprintf('%s.ui.roiDrawMethod = ''patches''; %s = refreshScreen(%s); ', ...
             vw.name, vw.name, vw.name);
uimenu(methodSubmenu, 'Label', 'Translucent patches', 'Callback', cb);


% Set filled perimeter
%   roiToggleFilledPerimeter(vw);
%   vw = refreshScreen(vw,0);
cb=[vw.name,'=roiToggleFilledPerimeter(',vw.name,'); ',...
    vw.name,'=refreshScreen(',vw.name,',0);'];
uimenu(showROIsMenu,'Label','Toggle Perimeter Method','Separator','off',...
    'Callback',cb);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

meshROImenu = uimenu(roimenu,'Label','Mesh vertices','Separator','off');

% Get mesh vertex indices ROI callback
%   vw = roiSetVertInds(vw);
cb=[ vw.name,'= roiSetVertInds(',vw.name,'); '];
  uimenu(meshROImenu,'Label','Get all ROI mesh vertices, current mesh','Separator','off',...
    'Callback', cb);

%   vw = roiSetVertIndsAllMeshes(vw);
cb=[ vw.name,'= roiSetVertIndsAllMeshes(',vw.name,'); '];
  uimenu(meshROImenu,'Label','Get all ROI mesh vertices, all meshes','Separator','off',...
    'Callback', cb);

% Clear mesh vertex indices ROI callback
%   vw = roiRemoveVertInds(vw);
cb=[ vw.name,'= roiRemoveVertInds(',vw.name,'); '];
  uimenu(meshROImenu,'Label', 'Clear ROI mesh vertices (all ROIs)','Separator','off',...
    'Callback', cb);

%   vw = roiRemoveVertInds(vw, vw.selectedROI);
cb= sprintf('%s = roiRemoveVertInds(%s, %s.selectedROI);', vw.name, vw.name,  vw.name);
  uimenu(meshROImenu,'Label', 'Clear ROI mesh vertices (selected ROI)','Separator','off',...
    'Callback', cb);


return;