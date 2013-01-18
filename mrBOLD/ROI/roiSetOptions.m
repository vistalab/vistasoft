function vw = roiSetOptions(vw,opts)
%
% vw = roiSetOptions(vw,[opts]);
%
% Set options/prefs related to rendering
% of ROIs in mrVista. Right now this includes
% the color of the selected ROI, the format
% for rendering (boxes surrounding pixels,
% perimeter, thick perimeter), and the
% number of ROIs to view. Down the line, 
% this may be a better way to keep track 
% of how ROIs are viewed.
%
% If called with <2 input args, will pop
% up a dialog to get these prefs. But, you
% can pass in an opts struct, in which case
% no dialog will be put up and the options
% will be set from fields in opts. The following
% fields are looked for: 
%       selRoiColor: color vector [R G B], from 0-1 for each,
%                    or string (e.g.,'r','w','k') -- see help plot
%       showRois:    integer from 1-4:
%                    1: hide all ROIs
%                    2: show selected ROI
%                    3: show all ROIs
%                    4: selected displayed ROIs from a list
%       drawFormat:  integer from 1-3:
%                    1: use boxes around each pixel
%                    2: draw perimeter
%                    3: draw filled perimeter (looks nicer on some views 
%                                              like FLAT)
%          
%
% The settings are placed in the following
% fields in the view's ui substruct:
%   selected ROI color: selRoiColor
%   which ROIs to show: showROIs
%   rendering format: this is stored in both the 
%                     showRois and filledPerimeter
%                     fields. If either perimeter or
%                     filled perimeter is set, showROIs
%                     is negative (-1 show cur ROI perim,
%                     -2 show all ROIs perim). 
%                     filledPerimeter is 0 or 1, depending
%                     on whether to use the filled perimeter 
%                     option.
%
% Suggestions for down the line:
%       1) We should consolidate ROI-related UI info in a view into
%          a substruct like ui.roi. This should contain the info 
%          set here, as well as the pointers to the ROI popup, 
%          and additional info like the name of the current ROI
%          (w/ space to add more info)
%       2) I prefer separating the settings for which ROIs to show
%          and the rendering format as I use for the opts struct:
%          there should be space to add new rendering formats easily,
%          since even the existing 3 options don't always look great.
%          Might want to set things like line width, etc.
%
%
%
% ras 05/05.
if notDefined('vw'),    vw = getCurView;        end
methods = {'boxes' 'perimeter' 'filled perimeter' 'patches'};

% check for hidden view
if isequal(vw.name,'hidden') || ~checkfields(vw,'ui')
    error('This appears to be a hidden view.')
end

% get a selected ROI color: if it's not
% present in the view, set as default
ui = viewGet(vw,'ui');
if checkfields(ui,'selRoiColor')
    selRoiColor = ui.selRoiColor;
else
    selRoiColor = [0 0 1]; % blue default
end

% get the currently-selected option for showing ROIs
showRois = ui.showROIs;

% convert showRois into a flag that reflects which display option is used
if length(showRois) <= 1
    switch showRois
    case -2, showRoisFlag = 3;  % All ROIs
    case -1, showRoisFlag = 2;  % Current (selected) ROI
    case 0,  showRoisFlag = 1;  % Hide ROIs
    otherwise, showRoisFlag = 4;  % Manually Selected
    end
else
	showRoisFlag = 4;   
end
        
drawFormat = cellfind(methods, ui.roiDrawMethod);

if notDefined('opts')
    % user dialog
    inpt(1).fieldName = 'selRoiColor';
    inpt(1).style = 'edit'; 
    inpt(1).string = 'Selected ROI Color:';
    inpt(1).value = num2str(selRoiColor);

    inpt(2).fieldName = 'showRois';
    inpt(2).style = 'popup'; 
    inpt(2).string = 'Show which ROIs?';
    inpt(2).list = {'None (Hide ROIs)' 'Current' 'All' 'Select From List'};
    inpt(2).value = showRoisFlag;

    inpt(3).fieldName = 'drawFormat';
    inpt(3).style = 'popup'; 
    inpt(3).string = 'ROI Rendering Method:';
    inpt(3).list = {'Boxes Around Each Pixel' ...
                  'Perimeter' ...
                  'Filled Perimeter' 'Patches'};
    inpt(3).value = drawFormat;

    opts = generalDialog(inpt,'ROI Set Options');

    % if user quit, exit gracefully
    if isempty(opts)
        return
    end

    % parse responses
    if ~isempty(str2num(opts.selRoiColor)) %#ok<*ST2NM>
        opts.selRoiColor = str2num(opts.selRoiColor);
    end
    opts.showRois = cellfind(inpt(2).list,opts.showRois);
    opts.drawFormat = cellfind(inpt(3).list,opts.drawFormat); 
end

% set fields appropriately
if isfield(opts,'selRoiColor')
    ui.selRoiColor = opts.selRoiColor;
end

switch opts.showRois
    case 1, ui.showROIs = 0;  % hide
    case 2, ui.showROIs = -1; % selected
    case 3, ui.showROIs = -2; % all
    otherwise, % manually select below
end

ui.filledPerimeter = (opts.drawFormat==3);
if ui.filledPerimeter ~= vw.ui.filledPerimeter
    vw = roiToggleFilledPerimeter(vw);
end

% addd a new value: ROI draw method. This allows for patches, and
% is more expandable down the line:
ui.roiDrawMethod = methods{opts.drawFormat};

vw.ui = ui; 
if opts.showRois==4, vw = roiSelectDisplay(vw); end

% let's go ahead and save the viewing preferences
% as well
try savePrefs(vw); end %#ok<TRYNC>

disp('Updated ROI Viewing Options.')

vw = refreshScreen(vw);

return



    
