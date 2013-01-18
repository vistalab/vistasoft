function gray = vol2grayParMap(vol, gray, field, selectedScans, forceSave)
% xform a map from volume view to gray view
%
% gray = vol2grayParMap(vol, gray, [field], [selectedScans], [forceSave])
%
% 
% Example:
%   gray = VOLUME{1};
%   vol = VOLUME{2};
%   field = 'map';
%   gray = vol2grayParMap(vol, gray, field);

% Don't do this unless vol is really a vol and gray is really a gray
if ~strcmp(vol.viewType,'Volume')
    myErrorDlg('vol2grayParMap can only be used to transform from volume to gray.');
end
if ~strcmp(gray.viewType,'Gray') 
    myErrorDlg('vol2grayParMap can only be used to transform from volume to gray.');
end

% Var checks
if notDefined('field'),     field       = viewGet(vol, 'displayMode');  end
if notDefined('forceSave'), forceSave   = 0;                            end

% Check scanList
nScans = viewGet(vol, 'nScans');
if ~exist('selectedScans','var') || isempty(selectedScans)
    ttl = 'Select scans to xform from volume -> gray';
    selectedScans = er_selectScans(vol, ttl);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end

% Make sure gray view is set to same mode as volume
gray = viewSet(gray, 'displayMode', field);
dt   = viewGet(vol, 'curdt');
gray = viewSet(gray, 'curdt', dt);

% Find the mapping between gray and vol coordinates
[c a b] = intersectCols(gray.coords, vol.coords);
[foo, ii] = sort(a);
b = b(ii);

% Check it
if ~isequal(c(:, ii), gray.coords), 
    error('could not map gray coords to vol coords'); 
end

% Loop through scans
for scan = selectedScans
    % get the map from vol
    map.vol = vol.(field){scan};
    % import from vol to gray
    map.gray = map.vol(b);
    gray.(field){scan} = map.gray;
end

if checkfields(vol,'ui','mapMode') && checkfields(gray,'ui','mapMode')
    gray.ui.mapMode = vol.ui.mapMode;
end

gray = refreshScreen(gray);
% Save to file
saveParameterMap(gray, [], forceSave, 1);




