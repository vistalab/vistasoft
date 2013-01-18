function val = guiGet(property, varargin);
% Get Property values for the mrVista Session GUI.
%
% val = guiGet(property, <optional args>);
% 
% This consolidates a set of small snippets of accessor code to more
% easily read info from the GUI struct created by sessionGUI. Note
% that I did try to design the GUI structure to be pretty easily 
% accessible directly, but am sympathetic to the approach which strictly
% treats it like an object. For instance, to get the currently-selected
% scans, you could either use:
%   scans = guiGet('scans')
%       or
%   scans = GUI.settings.scan;
%
% PROPERTIES TO GET:
%   'scan' or 'scans': currently-selected scans
%   'roi' or 'rois': currently-selected ROIs, as a cell array of structs
%   'slice': if a mrViewer is open for inplane data, the 
%            first-selected slice in this data; otherwise, the middle
%            slice.
%   'numScans' or 'nScans': total # of scans in the current data type.
%   'anatomyname': name of the MR anatomy being viewed by the selected
%       mrViewer UI. If no UI is open, returns empty.
%   'anatomyheader': header file info of the current anatomy (empty if no
%       viewer).
%   'anatomy', 'mr', 'base': loaded MR struct for the currrent anatomy
%       (loads from inplanes if no viewer.)
%
% ras, 07/11/06.
mrGlobals2;
val = [];

if isempty(GUI)
    myErrorDlg('guiGet only works if you''re running mrVista 2. ');
end

switch lower(property)
    case {'scans' 'scan' 'curscan' 'curscans' 'selectedscan' 'selectedscans'}
        val = GUI.settings.scan;
        
    case {'datatype' 'curdt' 'curdatatype' 'selecteddatatype'}
        val = GUI.settings.dataType;
        
    case {'roi' 'rois' 'curroi' 'currois' 'selectedroi' 'selectedrois'}
        ind = get(GUI.controls.roi, 'Value');
        for i = 1:length(ind)  
            roiPath = sessionGUI_roiPath(ind(i));
            val{i} = roiParse(roiPath);
        end
        
    case {'slice' 'curslice' 'firstslice' 'selectedslice'}
        % see if there's a mrViewer on the inplanes; if not, default
        % to middle slice        
        if ~isempty(GUI.viewers)
            ui = get(GUI.viewers(GUI.settings.viewer), 'UserData');
            if isequal(ui.mr.name, 'Inplane')
               val = ui.settings.slice;
            end
        else
            nSlices = size(INPLANE{1}.anat, 3);
            val = ceil(nSlices / 2);
        end
        
    case {'nscans' 'numscans'}
        val = length(dataTYPES(GUI.settings.dataType).scanParams);
        
    case {'anatomyname' 'anatname' 'basename' 'mrname'}
        if ~isempty(GUI.viewers)
            ui = get(GUI.viewers(GUI.settings.viewer), 'UserData');
            val = ui.mr.name;
        else,  val = '';
        end
        
    case {'anatomyheader' 'anatheader' 'mrheader' 'baseheader'}
        if ~isempty(GUI.viewers)
            ui = get(GUI.viewers(GUI.settings.viewer), 'UserData');
            val = ui.mr.hdr;
        else,  val = '';
        end
        
    case {'anatomy' 'mr' 'base' 'underlay'}
        if ~isempty(GUI.viewers)
            ui = get(GUI.viewers(GUI.settings.viewer), 'UserData');
            val = ui.mr;
        else
            val = mrLoad(fullfile(HOMEDIR, 'Inplane', 'anat.mat'));
        end
        
    case {'inplane'}
        val = mrLoad(fullfile(HOMEDIR, 'Inplane', 'anat.mat'));
        
    case{'viewer' 'curviewer' 'currentviewer' 'selectedviewer'}
        if isempty(GUI.viewers)
            val = [];
        else
            val = GUI.viewers(GUI.settings.viewer);
        end
        
end

return
