function roi = roiEdit(roi);
% Edit / View roi properties dialog.
%
%  roi = roiEdit(roi);
%
% ras 09/06/2005: wrote it (based on editROIFields).

%%%%%%%%%%
% PARAMS %
%%%%%%%%%%
% convert color into [R G B] vector if needed
colorList = {'yellow' 'magenta' 'cyan' 'red' 'green' 'blue' ...
            'white' 'kblack' 'user'};
colorChar = char(colorList)';
colorChar = colorChar(1,:);
if ischar(roi.color)
    colorNum = findstr(roi.color,colorChar);
    switch (colorNum)
        case 'yellow', colorRGB=[1 1 0];
        case 'magenta', colorRGB=[1 0 1];
        case 'cyan', colorRGB=[0 1 1];
        case 'red', colorRGB=[1 0 0];
        case 'green', colorRGB=[0 1 0];
        case 'blue', colorRGB=[0 0 1];
        case 'white', colorRGB=[1 1 1];
        case 'k', colorRGB=[0 0 0];
        otherwise
            colorRGB=[0 0 0];
    end
else
    colorNum=8; colorRGB=roi.color;
end

% options for ROI type
typeList = {'volume' 'area' 'line' 'point'};
typeNum = cellfind(typeList, lower(roi.type));

% options for ROI fill mode
fillList = {'perimeter' 'filled' 'patches'};
fillNum = cellfind(fillList, lower(roi.fillMode));

%%%%%%%%%%%%%%%%%
% Create Dialog %
%%%%%%%%%%%%%%%%%
dlg(1).string = 'ROI name:';
dlg(1).fieldName = 'name';
dlg(1).style = 'edit';
dlg(1).value = roi.name;

dlg(end+1).string = 'Color:';
dlg(end).fieldName = 'color';
dlg(end).list = colorList;
dlg(end).choice = colorNum;
dlg(end).style = 'popupmenu';
if ischar(roi.color)
    dlg(end).value = colorList{colorNum};
else
    dlg(end).value = 'user';
end

dlg(end+1).string = 'Size:';
dlg(end).fieldName = 'size';
nVoxels = size(roi.coords, 2);
volume = nVoxels * prod(roi.voxelSize);
dlg(end).value = sprintf('%i voxels, %3.1f mm^3', nVoxels, volume);
dlg(end).style = 'text';

dlg(end+1).string = 'Fill ROI When Drawing?';
dlg(end).fieldName = 'fillMode';
dlg(end).list = fillList;
dlg(end).value = fillNum;
dlg(end).style = 'popupmenu';

dlg(end+1).string = 'Save ROI As:';
dlg(end).fieldName = 'viewType';
dlg(end).list = {'Inplane' 'Volume'};
dlg(end).value = roi.viewType;
dlg(end).style = 'popup';

dlg(end+1).string = 'Created:';
dlg(end).fieldName = 'created';
dlg(end).value = roi.created;
dlg(end).style = 'text';

dlg(end+1).string = 'Last Modified:';
dlg(end).fieldName = 'modified';
dlg(end).list = colorList;
dlg(end).value = roi.modified;
dlg(end).style = 'text';

dlg(end+1).string = 'Comments:';
dlg(end).fieldName = 'comments';
dlg(end).value = roi.comments;
dlg(end).style = 'edit4';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% put up dialog, get response %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
resp = generalDialog(dlg, 'Edit ROI Fields', [.24 .5 .25 .25]);
% resp.color = cellfind(colorList, resp.color);

% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if isempty(resp), return; end

resp = rmfield(resp, 'size');

roi = mergeStructures(roi, resp); 
if (strcmp(roi.color,'user'))
    roi.color = uisetcolor(colorRGB);
else
    roi.color = roi.color(1);
end

roi.modified = datestr(now);

return