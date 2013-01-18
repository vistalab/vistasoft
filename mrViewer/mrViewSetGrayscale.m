function ui = mrViewSetGrayscale(ui, varargin);
%
% ui = mrViewSetGrayscale(ui, [property], [val]);
%
% Set grayscale level of a mrViewer UI. 
%
% 'property' can be one of the following:
%   'brightness': brighten/darken the default gray cmap by the 
%                 specified delta (see help brighten for more info).
%
%   'clipMin','clipMax': set minimum and maximum clip values for
%                 manual clipping of values.
%
%	'manualclip': toggle whether to use the clip value sliders
%				to set the clip, or to automatically choose the
%				grayscale clip for each slice. The extra argument
%				can be one of 'on', 'off', 1, 0, or a handle to 
%				a checkbox (such as ui.controls.manualClip).
%
%   'clip':     set clip to [clipMin clipMax]. Can also be
%               'auto' [the initial setting], in which case
%               will auto-scale each displayed image separately, 
%               or 'guess', in which case it will use the intensity
%				distribution of the data to guess reasonable clip 
%			    values (see mrClipOptimal).
%
% If property/val args are omitted, the code will read the
% values off the GUI.
%
% If a more general mrViewSet function is written,
% this may well get subsumed into that broader function.
%
% ras, 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end

if ishandle(ui), ui = get(ui, 'UserData');		end

% test if GUI is open (slowly building support for hidden views)
guiOpen = checkfields(ui, 'controls', 'clipMin');

%% if no arguments set, update from GUI
if length(varargin)==0  & guiOpen
	if get(ui.controls.manualClip, 'Value')==1
		clipMin = get(ui.controls.clipMin.sliderHandle, 'Value');
		clipMax = get(ui.controls.clipMax.sliderHandle, 'Value');
		ui.settings.clim = [clipMin clipMax];
	else
		ui.settings.clim = [];
	end
	
	brightness = get(ui.controls.brightness.sliderHandle, 'Value');
	ui.settings.cmap = brighten(gray(256), brightness);
end
	

%% parse any property settings
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'brightness'
			brightness = varargin{i+1};
			ui.settings.cmap = brighten(gray(256), brightness);
			
        case {'clipmin' 'climmin' 'lowerclip'} 
			% only update clipMin if manual color limits are set:
			% that is, if ui.settings.clim is not empty
			if ~isempty(ui.settings.clim)
				ui.settings.clim(1) = varargin{i+1};
           
				if guiOpen
					mrvSliderSet(ui.controls.clipMin, 'Value', clipMin);
				end
			end			
			
        case {'clipmax' 'climmax' 'upperclip'}
			% only update clipMax if manual color limits are set:
			% that is, if ui.settings.clim is not empty
			if ~isempty(ui.settings.clim)
				ui.settings.clim(2) = varargin{i+1};

				if guiOpen
					mrvSliderSet(ui.controls.clipMax, 'Value', clipMax);
				end
			end
			
			
		case {'manualclip' 'clipsliders'}
			if length(varargin) < i+1
				% get value from UI
				val = ui.controls.manualClip;
			else
				val = varargin{i+1};
			end
			
			onoff = {'off' 'on'};
			
			% parse how the value was passed in
			if ischar(val)
				val = cellfind(onoff, lower(val)) - 1;
				if isempty(val), error('unknown property value.'); end
				
			elseif ~ismember(val, [0 1]) & ishandle(val)
				val = get(val, 'Value');
				
			end
			
			if val==1	% manual clip on
				if guiOpen
					clim(1) = get(ui.controls.clipMin.sliderHandle, 'Value');
					clim(2) = get(ui.controls.clipMax.sliderHandle, 'Value');					
				else
					clim = [min(ui.mr.data(:)) max(ui.mr.data(:))];
				end
				
			else		% manual clip off
				clim = 'auto';
			end
				
			ui = mrViewSetGrayscale(ui, 'clim', clim);
					
			
        case {'clip' 'clim' 'clipvals'}, 
            clim = varargin{i+1};
			
            if isnumeric(clim) & length(clim)==2
                ui.settings.clim = clim;

				% if GUI open, set clim sliders to visible
				if guiOpen
					set(ui.controls.manualClip, 'Value', 1);                
					mrvSliderSet(ui.controls.clipMin, 'Value', clim(1), 'Visible', 'on');
					mrvSliderSet(ui.controls.clipMax, 'Value', clim(2), 'Visible', 'on');				
				end
				
            elseif isequal(clim, 'guess')
                % guess using histograms
                h = msgbox('Computing Clip Values From Histogram...');
				
                if ndims(ui.mr.data)==4
                    t = round( get(ui.time.sliderHandle, 'Value') );
                    vol = ui.mr.data(:,:,:,t);
                else
                    vol = ui.mr.data;
				end                
				
%                 [ignore clipMin clipMax] = mrClipOptimal(vol);				
                [ignore clipMin clipMax] = histoThresh(vol);				
				ui = mrViewSetGrayscale(ui, 'clim', [clipMin clipMax]);
				
                close(h);
				
            else
                % assume 'auto', set to empty
                ui.settings.clim = [];
				
				% if GUI open, set clim sliders to hidden
				if guiOpen
					set(ui.controls.manualClip, 'Value', 0);                					
					mrvSliderSet(ui.controls.clipMin, 'Visible', 'off');
					mrvSliderSet(ui.controls.clipMax, 'Visible', 'off');				
				end				
			end
			
	end			% switch statement
end			% loop through property settings

% refresh UI
ui = mrViewRefresh(ui);

return

