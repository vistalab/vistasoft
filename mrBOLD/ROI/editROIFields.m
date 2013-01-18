function [view,OK] = editROIFields(view,n)
% Edit the fields in a region of interest
%
%  [view,OK] = editROIFields(view,n)
%
% You can set the name and color of an ROI
% ARW 040104 : Added uisetcolor option, ability to use [R G B] color format
% RAS, DR, 2007: several new options, including size report and
% save options.
% ras, 01/24/07: records date created, last modified.
% ras, 10/08/07: for the 'save ROI' checkbox, the code now determines
% whether to default to checked or unchecked based on whether the ROI
% is already saved, as well as its name. E.g., if the file has already
% been saved, or it's named 'ROI1', it leaves it unchecked by default.
colorList = {'yellow','magenta','cyan','red','green','blue','white','kblack','user'};

colorChar = char(colorList)';
colorChar = colorChar(1,:);

if ~exist('n','var'), n = view.selectedROI; end
if n==0
    myErrorDlg('Sorry,  you need to load an ROI first.')
end

ROI = view.ROIs(n);
if (ischar(ROI.color))

    colorNum = findstr(ROI.color,colorChar);
    switch lower(ROI.color)
        case 'yellow',  colorRGB=[1 1 0];
        case 'magenta', colorRGB=[1 0 1];
        case 'cyan',    colorRGB=[0 1 1];
        case 'red',     colorRGB=[1 0 0];
        case 'green',   colorRGB=[0 1 0];
        case 'blue',    colorRGB=[0 0 1];
        case 'white',   colorRGB=[1 1 1];
        case 'k',       colorRGB=[0 0 0];
        otherwise
            colorRGB=[0 0 0];
    end
else
    colorNum=8; colorRGB=ROI.color;
end

if ~isfield(ROI, 'created'), ROI.created = datestr(now); end
if ~isfield(ROI, 'modified'), ROI.modified = datestr(now); end
if ~isfield(ROI, 'comments'), ROI.comments = ''; end

dlg(1).string = 'ROI name:';
dlg(1).fieldName = 'name';
dlg(1).style = 'edit';
dlg(1).value = ROI.name;

dlg(2).string = 'Color:';
dlg(2).fieldName = 'color';
dlg(2).list = colorList;
dlg(2).choice = colorNum;
dlg(2).style = 'popupmenu';
if ischar(ROI.color), dlg(2).value = colorList{colorNum};
else                  dlg(2).value = 'user';
end

dlg(end+1).string = 'Comments on ROI:';
dlg(end).fieldName = 'comments';
dlg(end).style = 'edit3';
dlg(end).value = ROI.comments;

dlg(end+1).string = 'Date Created:';
dlg(end).fieldName = 'created';
dlg(end).style = 'text';
dlg(end).value = ROI.created;

dlg(end+1).string = 'Last Modified:';
dlg(end).fieldName = 'modified';
dlg(end).style = 'text';
dlg(end).value = datestr(now);

% ras 01/07: let's also report the ROI size where it's not too hard
if ismember(view.viewType, {'Inplane' 'Volume' 'Gray'})
    dlg(end+1).string = 'ROI Size';
    dlg(end).fieldName = 'roiSize';
    dlg(end).style = 'text';
    nVoxels = size(ROI.coords, 2);
    roiVolume = nVoxels .* prod(viewGet(view, 'voxelSize'))';
    if isequal(view.viewType, 'Inplane')
        % get anatomical and functional sizes
		if nVoxels > 0
			funcVoxels=roiSubCoords(view, ROI.coords);
			nFuncVoxels = size(funcVoxels,2);
			str = strvcat([num2str(nVoxels) ' anatomical voxels'], ...
				[num2str(nFuncVoxels) ' functional voxels'], ...
				sprintf('%3.1fmm^3', roiVolume));
		else
			str = 'No voxels';
		end
        dlg(end).value = str;
    else
        % functionals are resampled to match anat, only one size
        dlg(end).value = sprintf('%i voxels, %3.1fmm^3', nVoxels, roiVolume);
    end
end

if isequal(view.viewType, 'Inplane') & nVoxels > 0
    % another nicety: report which slices the ROI may be found in
    dlg(end+1).string = 'Slices containing ROI';
    dlg(end).fieldName = 'roiSlices';
    dlg(end).style = 'text';
    dlg(end).value = num2str( unique(ROI.coords(3,:)) );
end

%% add checkbox to save the modified ROI:
% default to checked if the ROI has not been saved, unchecked if it has
roiIsSaved = check4File( fullfile(roiDir(view), ROI.name) ); 
tempRoi = strncmp(ROI.name, 'ROI', 3); % ROI1, ROI2, etc... don't want to save
saveFlag = ( ~roiIsSaved & ~tempRoi );

dlg(end+1).string = 'Save this ROI when done';
dlg(end).fieldName = 'save';
dlg(end).style = 'checkbox';
dlg(end).value = saveFlag;

if ismember(view.viewType, {'Volume' 'Gray'})
    dlg(end+1).string = 'If saving, save in local / shared directory?';
    dlg(end).fieldName = 'local';
    dlg(end).style = 'popup';
    dlg(end).list = {'local' 'shared'};
    dlg(end).value = 2;
end

resp = generalDialog(dlg,'Edit ROI Fields');


% If user selects 'OK', change the parameters.  Otherwise the
% user isn't happy with these settings so bail out.
if ~isempty(resp)
    ROI = mergeStructures(ROI, resp);
    if (strcmp(ROI.color,'user'))
        ROI.color = uisetcolor(colorRGB);
    else
        ROI.color = ROI.color(1);
    end

    % enforce proper ROI fields
    ROI = rmfield(ROI, 'save');
    ROI = roiCheck(ROI);

    if ismember(view.viewType, {'Volume' 'Gray'})   % get local flag from resp
        local = isequal(resp.local, 'local');
    else
        local = 1; % Inplane/Flat: always save locally
    end

    if resp.save==1
        saveROI(view, ROI, local);
    end

    for f = fieldnames(ROI)'
        view.ROIs(n).(f{1}) = ROI.(f{1});
    end

    OK = 1;
else
    OK = 0;
end


return

