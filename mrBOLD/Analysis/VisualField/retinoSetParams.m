function params = retinoSetParams(vw, dt, scan, params)
% Set visual field mapping ("retinotopic", though it doesn't need
% to be) parameters for the selected scan, providing an input dialog
% if the parameters aren't passed in as an input argument.
%
% params = retinoSetParams(vw, <dt, scan, params>)
%
% vw: mrVista view. <Defaults to cur inplane>
% dt: data type <Defaults to cur dt>
% scan: scan <Defaults to cur scan>
% params: struct specifying the visual field mapping design. The
%    exact fields in the struct depend on the design of the experiment,
%    but it should have at least the field 'type'. params.type currently
%    has two allowed values, 'eccentricity' and 'polar_angle', 
%    corresponding to the two types of retinotopic mapping experiments.
%    It will have additional fields which will spell out the details of
%    how the parameter was mapped.
%
%   If params.type=='eccentricity', the other fields are:
%       startAngle: angle of the stimulus, in degrees of visual angle,
%           at the start of each cycle. (Angle of MIDDLE eccentricity of
%           stimulus, not leading or trailing edge -- that's figured out
%           using the 'width' field.)
%       endAngle: angle of the stimulus, in degrees of visual angle,
%           at the end of each cycle. (Angle of MIDDLE eccentricity of
%           stimulus, not leading or trailing edge -- that's figured out
%           using the 'width' field.)
%       width: width of the ring stimulus. Can be a single number, 
%           if the width was constant; or can be a 2xN vector if the 
%           width changed over time. In the latter case, the first
%           row should be time in each cycle, specified in normalized
%           units from 0 to 2*pi (0=start of cycle, 2*pi=end), and
%           the second row should be the width at those given times.
%       blankPeriod: string indicating what, if any, blank period
%           occurred between the outtermost and innermost ring.
%           Options: 'none', cycles continued w/o blank; 
%             'start of cycle', 'end of cycle': blank period
%             came at start, end of cycle, respectively,
%             'frequency tagged', blank periods came up
%             at a different frequency from the stimulus frequency.
%       dutyCycle: if there was a blank period, this indicates
%             the ratio of the non-blank period to the total cycle
%             duration.
%		startPhase: indicates proportion to circular shift a cycle
%			 (e.g., if the time series started 1/4 of the way into 
%			 the start phase, set this to 1/4; set 0 if it started
%			 right at the most foveal or peripheral ring)
%                 
%   If params.type=='polar_angle', the other fields are:
%       startAngle: angle of center of wedge stimulus, measured
%           in degrees clockwise from 12-o-clock, at the start of each
%           cycle;
%       width: width of wedge stimulus in degrees.
%       direction: 'clockwise' or 'counterclockwise', direction in which
%           the stimulus proceeded.
%       visualField: number of degrees the stimulus traversed
%           each cycle (e.g., 360 if it went all the way around).
%
% The params are kept in:
%   dataTYPES(dt).blockedAnalysisParams(scan).visualFieldMap.
%
% My goal in using these parameters is, right now, two-fold:
%   (1) keep information about different experiments for accurately
%       converting corAnal phase maps into parameter maps in units of
%       degrees (which will then be used in different meta-analyses);
%   (2) have the colorbar automatically update to the appropriate 
%       type of wedge / ring plot when viewing theses scans, as 
%       a convenience.
%
%
%
% ras, 01/06: testing the waters if this code is needed. I see many
% other places where similar parameters are set, but none of them
% seem immediately useable to me.
if notDefined('vw'), vw = getSelectedInplane;       end
if notDefined('dt'), dt = viewGet(vw, 'curdt');       end
if notDefined('scan'), scan = viewGet(vw, 'curscan'); end

global dataTYPES;

if isnumeric(dt)
    dtNum = dt;
    dt = viewGet(vw, 'dt name', dtNum); 
else
    dtNum = existDataType(dt);
end

% if many scans entered, iterate through each one
if length(scan)>1
    if notDefined('params')
        for s = scan, vw = retinoSetParams(vw, dt, s); end
    else
        for s = scan, vw = retinoSetParams(vw, dt, s, params); end
    end
    return
end

if notDefined('params')
    % sequence of two dialogs
    annotation = dataTYPES(dtNum).scanParams(scan).annotation;
    q = [sprintf('%s, scan %i (%s): ', dt, scan, annotation)...
         'Did this scan map out eccentricity or polar angle? '];
    resp = questdlg(q, 'retinoSetParams', 'Eccentricity', ...
                       'Polar Angle', 'Cancel', 'Cancel');
    
    if isequal(resp, 'Cancel'), warning('User Aborted'); return; end
    
    if isequal(resp, 'Eccentricity')
        params = eccentricityDialog(vw, dt, scan);
    else
        params = polarAngleDialog(vw, dt, scan);
    end
elseif isequal(params, 'none')
    params = [];
end

if isempty(params), return; end

dataTYPES(dtNum).blockedAnalysisParams(scan).visualFieldMap = params;
saveSession(0);

% if there's a UI, re-set the color bar
if checkfields(vw, 'ui', 'colorbarHandle') && isequal(vw.ui.displayMode, 'ph')
	setColorBar(vw, 'on');
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function params = eccentricityDialog(vw, dt, scan)
% param] = eccentricityDialog;
% put up a dialog to get parameters for an eccentricity-mapping scan.
% checks if any existing params are already assigned to use as defaults.
defaults = retinoGetParams(vw, dt, scan);
if ~isfield(defaults, 'startAngle'),    defaults.startAngle = 0;       end
if ~isfield(defaults, 'endAngle'),      defaults.endAngle = 3;         end
if ~isfield(defaults, 'width'),         defaults.width = 1.2;          end
if ~isfield(defaults, 'blankPeriod'),   defaults.blankPeriod = 'none'; end
if ~isfield(defaults, 'dutyCycle'),     defaults.dutyCycle = 1/12;     end
if ~isfield(defaults, 'startPhase'),    defaults.startPhase = 0;     end

% set up dialog fields:
dlg(1).fieldName = 'startAngle';
dlg(1).style = 'edit';
dlg(1).string = 'Eccentricity (degrees) at START of cycle? ';
dlg(1).value = num2str(defaults.startAngle);

dlg(2).fieldName = 'endAngle';
dlg(2).style = 'edit';
dlg(2).string = 'Eccentricity (degrees) at END of cycle? ';
dlg(2).value = num2str(defaults.endAngle);

dlg(3).fieldName = 'width';
dlg(3).style = 'edit';
dlg(3).string = 'Width of stimulus? (degrees)';
dlg(3).value = num2str(defaults.width);

dlg(4).fieldName = 'blankPeriod';
dlg(4).style = 'popup';
dlg(4).string = 'Were there blank periods during the scan?';
dlg(4).list = {'none' 'start of cycle' 'end of cycle' ...
                'frequency tagged'};
dlg(4).value = num2str(defaults.blankPeriod);

dlg(5).fieldName = 'dutyCycle';
dlg(5).style = 'edit';
dlg(5).string = 'If blank, ratio of blank time / cycle time? (1 - duty cycle)';
dlg(5).value = num2str(1-defaults.dutyCycle);


dlg(6).fieldName = 'startPhase';
dlg(6).style = 'edit';
dlg(6).string = ['Cycle Phase shift? (e.g. 0=time series started with cycle,' ...
				'1/4=time series started 1/4 way into cycle)'];
dlg(6).value = num2str(defaults.startPhase);


% put up the dialog
resp = generalDialog(dlg, 'Eccentricity Parameters');

% parse the response 
% (could just set resp = params, except I want the 'type' field first)
params.type = 'eccentricity';
params.startAngle   = str2double(resp.startAngle);
params.endAngle     = str2double(resp.endAngle);
params.width        = str2double(resp.width);
params.blankPeriod  = resp.blankPeriod;
params.dutyCycle    = 1 - str2double(resp.dutyCycle);
params.startPhase   = str2double(resp.startPhase);

return
% /---------------------------------------------------------------------/ %





% /---------------------------------------------------------------------/ %
function params = polarAngleDialog(vw, dt, scan)
% param] = polarAngleDialog;
% put up a dialog to get parameters for a polar-angle-mapping scan.
% checks if any existing params are already assigned to use as defaults.
defaults = retinoGetParams(vw, dt, scan);
if ~isfield(defaults, 'startAngle'),    defaults.startAngle = 90;    end
if ~isfield(defaults, 'direction'), defaults.direction = 'clockwise'; end
if ~isfield(defaults, 'width'),         defaults.width = 0;        end
if ~isfield(defaults, 'visualField') || isequal(defaults.visualField, 360)
    defaults.visualField = 'both';  
else
    defaults.visualField = 'left';
end

% set up dialog fields:
dlg(1).fieldName = 'startAngle';
dlg(1).style = 'edit';
dlg(1).string = ['Angle at start of cycle [in degrees clockwise ' ...
                 'from 12 o clock]?'];
dlg(1).value = num2str(defaults.startAngle);

dlg(2).fieldName = 'direction';
dlg(2).style = 'popup';
dlg(2).string = 'Which direction was the stimulus rotating?';
dlg(2).list = {'clockwise' 'counterclockwise'};
dlg(2).value = cellfind(dlg(2).list, defaults.direction);

dlg(3).fieldName = 'visualField';
dlg(3).style = 'popup';
dlg(3).string = 'Visual Field covered?';
dlg(3).list = {'left' 'right' 'both'};
dlg(3).value = cellfind(dlg(3).list, defaults.visualField);

dlg(4).fieldName = 'width';
dlg(4).style = 'edit';
dlg(4).string = 'Width of stimulus in degrees?';
dlg(4).value = num2str(defaults.width);

% put up the dialog
resp = generalDialog(dlg, 'Polar Angle Parameters');
if isempty(resp), params = []; return; end

% parse the response
% (could just set resp = params, except I want the 'type' field first)
params.type = 'polar_angle';
params.startAngle = str2double(resp.startAngle);
params.direction = resp.direction;
if isequal(resp.visualField, 'left')
    params.visualField = 180;
elseif isequal(resp.visualField, 'right')
	params.visualField = -180; % hack
else
    params.visualField = 360;
end
params.width = str2double(resp.width);

return
% /---------------------------------------------------------------------/ %

