function ui = mrViewSet(ui, varargin);
%
% ui = mrViewSet([ui], [Property], [value], ...);
%
% Set properties of a mrViewer UI.
%
% Properties include:
%   'space',[space #]: set coordinate space to use.
%   'slice',[slice or handle to slice slider]: set current slice.
%   'time',[val or handle to time slider]: set time point for 4D underlay.
%   'ori',[val or button handle]: select orientation:
%                                 1: 'axials' or columns by slices
%                                 2: 'coronals' or rows by slices
%                                 3: 'sagittals' or rows by columns
%	'displayFormat', [#]:	set the display format of the viewer:
%						1: montage
%						2: 3-view
%						3: single slice
%	'curROI', [roi struct]: replace the selected ROI with a struct passed
%							in.
%	'curROINum', [#]:	select an ROI by number. Can also pass in a name.
%	'curROIColor', [col]: set the color of the current ROI.
%	'addAndSelectROI', [roi struct]: append a new ROI to the ui.rois list,
%					and select it.
%	'segmenationNum', [#]:	select a segmentation by number. Names are also
%							OK.
%	'mesh', [mesh struct]:	replace the current mesh with a passed in
%						struct.
%	'curMeshNum', [#]:	select the current mesh (for the current
%						segmentation) by number.
%
% ras, 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;        end
if ishandle(ui), ui = get(ui, 'UserData'); end

for i = 1:2:length(varargin)
	property = lower(varargin{i});

	if length(varargin)<i+1
		val = [];
	else
		val = varargin{i+1};
	end

	switch property
		case 'space', ui = mrViewSetSpace(ui,val); % attached below

		case 'slice',
			if isempty(val) % get from GUI
				val = get(ui.slice.sliderHandle,'Value');
			end
			
			oldSlice = ui.settings.slice;
			ui.settings.slice = val;			
						
			if val ~= oldSlice & checkfields(ui, 'slice', 'sliderHandle')
				% GUI update, only if slice has changed
				mrvSliderSet(ui.slice, 'Value', val);
				
				ui.settings.cursorLoc(ui.settings.ori) = val;				

				% redraw slice / montage starting w/ new slice
				ui = mrViewRefresh(ui);
			end

		case 'time',
			if isempty(val)
				val = get(ui.time.sliderHandle,'Value');
			end
			ui.settings.time = val;

		case {'ori', 'orientation'},
			% set view orientation:
			% if an integer is supplied, set
			% to that integer; if a handle
			% is supplied to a button, identify
			% that button in the UI and set accordingly.
			if isnumeric(val) & mod(val, 1)==0
				ui.settings.ori = val;

				% update orientation buttons if they exist
				if checkfields(ui,'controls','ori')
					selectButton(ui.controls.ori,val);
				end

			elseif ishandle(val)
				ui.settings.ori = find(ui.controls.ori==val);

				% set bounds on slice slider for this orientation
				b = ui.settings.bounds(ui.settings.ori,:);
				mrvSliderSet(ui.slice,'Range',b);
				slice = ui.settings.cursorLoc(ui.settings.ori);
				ui = mrViewSet(ui,'slice',slice);

			else
				error('Invalid specification for orientation.')

			end

		case 'displayformat'
			% set view format: if handles, find selected button
			if ishandle(val) & mod(val, 1) ~= 0 % non-integer: not a figure
				val = find(ui.controls.displayFormat==val);
			end

			ui.settings.displayFormat = val;

			if checkfields(ui, 'controls', 'displayFormat')
				selectButton(ui.controls.displayFormat, val);

				% if montage format selected, and  is present, make
				% rows/columns sliders visible. Otherwise, hide 'em:
				if ui.settings.displayFormat==1, vis = 'on';
				else, vis = 'off';
				end
				mrvSliderSet(ui.controls.montageRows,'Visible',vis);
				mrvSliderSet(ui.controls.montageCols,'Visible',vis);
				slice = ui.settings.cursorLoc(ui.settings.ori);
				ui = mrViewSet(ui,'slice',slice);
			end

		case 'overlay', ui = mrViewSetOverlay(ui,varargin);

		case 'montagerows'
			ui.settings.montageRows = round(val);
			if checkfields(ui, 'controls', 'montageRows')
				mrvSliderSet(ui.controls.montageRows, 'value', round(val));
			end

		case 'montagecols'
			ui.settings.montageCols = round(val);
			if checkfields(ui, 'controls', 'montageCols')
				mrvSliderSet(ui.controls.montageCols, 'value', round(val));
			end

		case 'labelaxes', ui.settings.labelAxes = val;

		case 'labeldirs', ui.settings.labelDirs = val;

		case 'labelslices',ui.settings.labelSlices = val;

		case 'showcursor'
			ui.settings.showCursor = val;
			if checkfields(ui,'controls','cursor')
				if val>0, vis = 'on'; else, vis = 'off'; end
				set(ui.controls.cursorType,'Visible',vis)
			end

		case 'cursortype', ui.settings.cursorType = val;

		case 'cursorloc'
			% if no argument passed, get from cursor edit fields
			if isempty(val)
				for i=1:3
					val(i) = str2num(get(ui.controls.cursorEdit(i),'String'));
				end
			end
			ui.settings.cursorLoc = val;

			% update GUI if needed
			if checkfields(ui, 'controls', 'cursorEdit')
				ui = mrViewCursorGUI(ui);
			end

		case 'cbarcolorscheme'  % set colorbars white-on-black of vice-versa
			ui.settings.cbarColorScheme = val;

		case 'infopanel'
			% update the info panel to show info for the
			% mr object (base object / map / ROI) selected by the
			% info panel popup:
			if isempty(val), val=get(ui.controls.infoPopup,'Value'); end
			val = min(val, length(ui.maps)+length(ui.rois)+1); % bounds check

			nMaps = length(ui.maps); nRois = length(ui.rois);
			if val==1   % show info for the base mr object
				txt = infoText(ui.mr);

			elseif val<=length(ui.maps)+1  % show info for map # [val]
				txt = infoText(ui.maps(val-1));

			else
				txt = infoTextROI(ui.rois(val-nMaps-1));

			end
			set(ui.controls.infoListbox, 'String', txt, 'Value', 1);

			% also update the popup to list all options
			str{1} = sprintf('Base: %s', ui.mr.name);
			for m = 1:nMaps
				str{m+1} = sprintf('Map %i: %s', m, ui.maps(m).name);
			end
			for r = 1:nRois
				str{r+nMaps+1} = sprintf('ROI %i: %s', r, ui.rois(r).name);
			end
			set(ui.controls.infoPopup,'String',str);

		case 'eqaspect', ui.settings.eqAspect = val;

		case 'roieditmode', ui.settings.roiEditMode = val;

		case {'roiviewmode' 'roidrawmode'},
			if isempty(val), val=get(ui.controls.roiViewMode,'Value'); end

			% see if the view mode has changed from its previous value:
			% if it has, we need to redraw the ROIs, but if not, we
			% can quietly update the setting:
			oldVal = ui.settings.roiViewMode;
			ui.settings.roiViewMode = val;
			if val ~= oldVal, ui = mrViewROI('draw', ui);  end
			
			if checkfields(ui, 'controls', 'roiViewMode') % update GUI
				set(ui.controls.roiViewMode, 'Value', val);
			end
			
		case {'curroicolor' 'selectedroicolor'},
			ui.rois(ui.settings.roi).color = val;

		case {'curroinum' 'selectedroinum', 'roinum' 'selroinum'}
			if ischar(val)
				val = cellfind({ui.rois.name}, val);
			end
			mrViewROI('select', ui, val);

		case {'curroi' 'roi' 'selectedroi'}
			% get ROI struct -- but allow names / index #s
			if ischar(val)
				val = ui.rois( cellfind({ui.rois.name}, val) );
			elseif isnumeric(val)
				val = ui.rois(val);
			end
			
			n = ui.settings.roi;
			ui.rois(n) = mergeStructures(ui.rois(n), val);
			
			% update ROI popup in viewer -- this will update based on UI
			mrViewROI('select', ui); 


		case {'newroi' 'addroi' 'addandselectroi'}
			ui = mrViewROI('new', ui);    % creates and selects new ROI
			ui = mrViewSet(ui, 'CurROI', val); % replace empty w/ val

		case 'tseries', ui = mrViewAttachTSeries(ui, val);

		case 'stim', ui = mrViewAttachStim(ui, val);

		case 'session', ui.session = val;

		case {'zoom' 'zoom3d'}, ui.settings.zoom = val;
		case {'zoom2d' 'axis' 'slicezoom'},
			% convert axis bounds [xmin xmax ymin ymax] to 3D Zoom bounds
			otherDims = setdiff(1:3, ui.settings.ori);
			ui.settings.zoom(otherDims(1),:) = val(3:4);
			ui.settings.zoom(otherDims(2),:) = val(1:2);

		case {'meshnum' 'curmeshnum' 'selectedmeshnum' 'curmeshn'},
			s = ui.settings.segmentation;
			ui.segmentation(s).settings.mesh = val;

			try
				if checkfields(ui, 'menus', 'segList')  % select mesh in menu
					set(ui.menus.meshList, 'Checked', 'off')
					set(ui.menus.meshList(val), 'Checked', 'on')
				end
				
				% try to load saved view settings for this mesh
				mrViewLoad(ui, '', 'meshsettings');
				
				% set the mesh list popup
				set(ui.controls.meshSelect, 'String', mrViewGet(ui, 'MeshList'));
			end

		case {'mesh' 'curmesh' 'selectedmesh'},
			s = ui.settings.segmentation;
			m = ui.segmentation(s).settings.mesh;
			if m==0, m = 1; end   % if no current mesh, add this one
			ui.segmentation(s).mesh{m} = val;

		case {'meshbackground' 'meshbg' 'meshbackgroundcolor' 'meshbgcolor'}
			if ishandle(val), val = get(val, 'UserData');
			elseif isequal(val, 'user'), val = uisetcolor;
			end
			mrmSet(mrViewGet(gcf, 'CurMesh'), 'background', val);


		case {'addandselectmesh'}
			ui = mrViewAddMesh(ui, val);

		case {'addsegmentation' 'newsegmentation'}
			if isfield(ui, 'segmentation')
				ui.segmentation(end+1) = val;
			else
				ui.segmentation = val;
			end
			
			% figure out the index of the new segmentation
			s =  length(ui.segmentation);
			
			% the mesh menu (and gray ROI options) can now be visible
			set(ui.menus.mesh, 'Visible', 'on');
			set(ui.menus.roiGray, 'Visible', 'on');

			% add an option to select this segmentation
			ui.menus.segList(s) = uimenu( ui.menus.meshSeg, ...
				'Label', ui.segmentation(s).name, ...
				'Callback', sprintf('mrViewSet(gcf, ''CurSegmentation'', %i); ', s) );

			% add a menu to the meshes menu as well, to slect the current mesh for
			% this segmentation
			ui.menus.meshSelect(s+1) = uimenu(ui.menus.meshSelect(1), ...
				'Label', ui.segmentation(s).name);		
			
			% select the new segmentation
			ui = mrViewSet(ui, 'CurSegmentation', s);
			
		case {'segmentation' 'seg'}
			ui.segmentation( ui.settings.segmentation ) = val;
			
		case {'segmentationnum' 'cursegmentation' 'selectedsegmentation'},
			if ischar(val)  % name of segmentation
				val = cellfind({ui.segmentation.name}, val);
				if isempty(val),  myErrorDlg('Segmentation not found'); end
			end
			ui.settings.segmentation = val;

			if checkfields(ui, 'menus', 'segList')  % select seg in menu
				set(ui.menus.segList, 'Checked', 'off')
				set(ui.menus.segList(val), 'Checked', 'on')
				
				try 
					set(ui.controls.segSelect, ...
						'String', {ui.segmentation.name}, 'Value', val)
				end
			end


		otherwise, warning( sprintf('Unknown property %s', property) );
	end
end

% set updated settings in the ui's figure, but don't
% always refresh:
if isfield(ui,'fig') & ishandle(ui.fig)
	set(ui.fig, 'UserData', ui);
end

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function ui = mrViewCursorGUI(ui);
% ui = mrViewCursorGUI(ui);
% set fields in the mrViewer GUI to agree with the current cursor location.
loc = ui.settings.cursorLoc;

% set cursor edit fields
set(ui.controls.cursorEdit(1), 'String', num2str(loc(1)));
set(ui.controls.cursorEdit(2), 'String', num2str(loc(2)));
set(ui.controls.cursorEdit(3), 'String', num2str(loc(3)));


if ismember(ui.settings.displayFormat,  [1 3])
	% need to set current slice as well as cursor loc
	slice = round( loc( ui.settings.ori ) );
	ui = mrViewSet(ui,  'slice',  slice);
end	

% decide whether to refresh based on the display format:
if ui.settings.displayFormat==2 
	% 3-axis view
	% update slice 
	ui = mrViewSet(ui, 'slice', loc(ui.settings.ori));
	ui = mrViewRefresh(ui);

elseif ui.settings.showCursor==1
	% single slice or montage format
	% we don't need to refresh, just redraw the cursor

	% first, delete old cursor objects
	delete(findobj('Tag', sprintf('%scursor',ui.tag)));

	% now, render cursor
	oris = ui.display.oris;
	slices = ui.display.slices;
	for i = 1:length(ui.display.axes)
		ui = mrViewRenderCursor(ui, oris(i), slices(i), ui.display.axes(i));
	end

	% update the cursor setting, w/o refreshing
	set(ui.fig, 'UserData', ui);
	
end



return