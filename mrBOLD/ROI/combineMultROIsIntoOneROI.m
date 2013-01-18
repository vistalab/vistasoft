function [vw,OK] = combineMultROIsIntoOneROI(vw)
% function [vw,OK] = combineMultROIsIntoOneROI(vw)
% 
% Purpose:
% opens a dialog box that allows the user to combine multiple ROIs
% with the current selection to make one ROI
% into a set of new ROI using logical operators:
% --built on the previous combineROIcode to combine many ROIS to create
% one new ROI. Note that the ROIs selected add to the currently selected
% ROI
%
% Union:  set union
% Intersection : set intersection
% XOR : exclusive or
% A not B : set difference (all elements in A that are not also
%           in B)
% 
% Authors: AAB 2003-12-16 changed and cleaned
% Other combination versions:
%   rmk 10/30/98 combine two ROIs
%   fwc 12/07/02 multiple ROIs into multiple combinations
%   fwc 25/07/02  fixed color assignment


% Select ROIs to combine with current
rois = viewGet(vw,'ROIs');
nRois=size(vw.ROIs,2);
roiList=cell(1,nRois);
for r=1:nRois
    roiList{r}=vw.ROIs(r).name;
end
reply = buttondlg('ROIs to combine with current ROI',roiList);
if isempty(reply)
    % 'Cancel' pressed; exit gracefully
    return
end
selectedROIs = find(reply);

nRois=length(selectedROIs);
if (nRois==0)
    error('No ROIs selected');
end

rois = rois(selectedROIs);


% Possible actions for combination
actionList = {'Union', 'Intersection', 'XOR', 'A not B'};

% possible colors for new ROI
colorList = {'yellow','magenta','cyan','red','green','blue','white','user'};

actionNum = 1; % default to Union

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make Dialog to get Combine Action, New ROI Name %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uiStruct(1).string      = 'Action:';
uiStruct(1).fieldName   = 'action';
uiStruct(1).list        = actionList;
uiStruct(1).choice      = actionNum;
uiStruct(1).style       = 'popupmenu';
uiStruct(1).value       = 'Union';

uiStruct(2).string      = 'New ROI Name:';
uiStruct(2).fieldName   = 'newRoiName';
uiStruct(2).list        = {};
uiStruct(2).choice      = actionNum;
uiStruct(2).style       = 'edit';
uiStruct(2).value       = [rois(1).name '_Combined'];

uiStruct(3).string      = 'New ROI Color:';
uiStruct(3).fieldName   = 'newRoiColor';
uiStruct(3).list        = colorList;
uiStruct(3).choice      = 6; % default to blue
uiStruct(3).style       = 'popup';
uiStruct(3).value       = 'blue';

% put up the dialog, get user response
outStruct = generalDialog(uiStruct,'Combine ROIs Into One ROI');   

% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if ~isempty(outStruct)
    
    % If user-defined color selected, get that color
    if isequal(outStruct.newRoiColor,'user')
        outStruct.newRoiColor = uisetcolor([0 0 0]);            
    end
    
    % first find starting ROI (selected ROI):
    coords = rois(1).coords;
    
    for r=2:nRois
        coords = combineCoords(coords,rois(r).coords,outStruct.action);
    end
    
    %    % ras, 04/05: disabled: what if we're doing something in an automated
    %    % fashion and care that we get back an empty set?
    %     if isempty(coords)
    %         warnstr=['FYI: ROI ' outStruct.newRoiName ' was not created because it was empty.'];
    %         disp(warnstr);
    %     else
    
    % If the new ROI color is a character, it 
    % needs to be a single char, not the whole name:
    if ischar(outStruct.newRoiColor)
        outStruct.newRoiColor = outStruct.newRoiColor(1);
    end
    
    % now add new ROI:
    ROI.color    = outStruct.newRoiColor;
    ROI.coords   = coords;
    ROI.name     = outStruct.newRoiName;
    ROI.viewType = vw.viewType;
    ROI          = sortFields(ROI);  
    vw = addROI(vw,ROI);
    
    OK = 1;
else 
    OK = 0;
end

return;