function [vw, roi, ok] = combineROIs(vw, rois, action, name, color, comments)
% function [vw, roi, ok] = combineROIs(vw, [rois=dialog], [action='union'], [name], [color='b'], [comments])
%
% that allows the user to combine 2 ROIs
% into a third new roi using logical operators:
%
% Union:  set union
% Intersection : set intersection
% XOR : exclusive or
% A not B : set difference (all elements in A that are not also
%           in B)
%
% INPUTS: 
% vw: mrVista view. Defaults to current view.
%
% rois: cell array of input ROIs (name of roi, or index into the view's
%		roi list). Can have more than two input ROIs, though the dialog
%		that pops up is geared towards combining two ROIs. The same action
%		(AND, OR, XOR, ANOTB) will be applied sequentially to the input
%		ROIs: e.g. ((A AND B) AND C), or ((A OR B) OR C) etc...
%
% action: one of {'and' 'or' 'xor' 'anotb'} per above. Case insensitive.
%		can also use 'intersection' and 'union' for 'and' and 'or',
%		respectively.
%
% name: name of the combined roi. [Defaults to "roi[#]", with the
%		number of the next roi in the view.]
%
% color: color of the combined roi. [Defaults to 'b'.]
%
% If params is omitted, opens a dialog box to get the params.
%
% rmk 10/30/98
% ras 02/08/04 -- added white as a color option (otherwise, why allow white
% ROIs?)
% ras 03/28/07 -- made params an input argument, moved most of the old code
% into the *GUI subfunction.
% ras, 10/08/07 -- returns the ROI as well as the view.
if notDefined('vw'),        vw = getCurView;                            end
if notDefined('name'),      name = sprintf('ROI%i', length(vw.ROIs)+1);	end
if notDefined('action'),    action = 'union';							end
if notDefined('color'),	    color = 'b';								end
if notDefined('comments'),	comments = '';								end
if notDefined('rois')
	[rois action name color comments ok] = combineROIsGUI(vw);
	if ok==0
		fprintf('[%s]: combineROIs aborted.\n', mfilename); return
	end
end

% first find input ROIs:
for r = 1:length(rois)
    % check whether rois is cell array or vector
    if iscell(rois), thisroi = rois{r};
    else             thisroi = rois(r); end
	rois_cell{r} = tc_roiStruct(vw, thisroi);
end

rois = rois_cell;

% now perform operation:
coords = rois{1}.coords;
for r = 2:length(rois)
	coords = combineCoords(coords, rois{r}.coords, action);
end

% now add new roi:
roi = roiCreate1;
roi.color = color;
roi.coords = coords;
roi.name = name;
roi.viewType = vw.viewType;
roi.comments = comments;

if ischar(roi.color)
	if isequal(lower(roi.color), 'user')
		roi.color = uisetcolor([0 0 0]);
	else
		roi.color = roi.color(1);  % just the first letter
	end
end

roi = sortFields(roi);

vw = addROI(vw, roi);

return
% /-------------------------------------------------------------/ %




% /-------------------------------------------------------------/ %
function [rois, action, name, color, comments, ok] = combineROIsGUI(vw)
% Create a dialog to get the combineROIs params.
% This dialog assumes you are only combining two ROIs. Use the
% 'combineManyROIs*' functions for more than one. (TODO: integrate
% those functions to call back to the core combineROIs function.)
% ras 03/07, this is essentially the old combineROIs code.
actionList = {'Union' 'Intersection' 'XOR' 'A not B'};

actionNum = 1; % default to union

colorList = {'blue' 'red' 'green' 'yellow' 'magenta' 'cyan' ...
			 'white' 'kblack' 'user'};

colorChar = char(colorList)';
colorChar = colorChar(1,:);

if ~isempty(vw.ROIs)
    % JL 20070518: choose ROI from a pop menu rather than edit, to avoid errors.
    % You shall load ROIs into view before combine them.
    for iROI = 1:length(vw.ROIs); roiNameList{iROI} = vw.ROIs(iROI).name; end;
    defROINum = vw.selectedROI;
    defColorNum = findstr(vw.ROIs(defROINum).color, colorChar);
else % if no ROI -- pop up empty.
    roiNameList = {''};
    defROINum = 1; defColorNum = 1;
end

c=0;

c=c+1;
dlg(c).string = 'ROI 1:';
dlg(c).fieldName = 'name1';
dlg(c).list = roiNameList;
dlg(c).style = 'popupmenu';
dlg(c).value = max(defROINum-1,1); % default: combine selectedROI with the one before it on list.

c=c+1;
dlg(c).string = 'ROI 2:';
dlg(c).fieldName = 'name2';
dlg(c).list = roiNameList;
dlg(c).style = 'popupmenu';
dlg(c).value = defROINum;

c=c+1;
dlg(c).string = 'Action';
dlg(c).fieldName = 'action';
dlg(c).list = actionList;
dlg(c).value = actionNum;
dlg(c).style = 'popupmenu';

c=c+1;
dlg(c).string = 'Combined ROI Name:';
dlg(c).fieldName = 'name3';
dlg(c).style = 'edit';
dlg(c).value = 'Combined ROI';

c=c+1;
dlg(c).string = 'Combined ROI Color:';
dlg(c).fieldName = 'color';
dlg(c).list = colorList;
dlg(c).value = defColorNum;
dlg(c).style = 'popupmenu';

c=c+1;
dlg(c).string = 'Comments for new roi:';
dlg(c).fieldName = 'comments';
dlg(c).value = '';
dlg(c).style = 'edit3';


resp = generalDialog(dlg, mfilename, [.3 .3 .25 .25]);

% If user selects 'ok', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if ~isempty(resp)
	rois = {resp.name1 resp.name2};
	action = resp.action;
	name = resp.name3;
	color = resp.color;
	comments = resp.comments;	
    ok = 1;
else
	rois = {};
	action = '';
	name = '';
	color = '';
	comments = '';
    ok = 0;
end

return







