function cmapExportModeInformation(v, modeName, fname)
%
%   cmapExportModeInformation(view,[modeName],[fname])
%
%Author: AB, BW
%Purpose:
%    Save out the color information used to make a particular image.  The
%    user is queried for a file name if none is passed in.
%
% Example:
%
% v = FLAT{1};
% cmapExportModeInformation(v);
%

if ieNotDefined('v'), error('Must specify a view.'); end
displayType = viewGet(v,'displaymode');
if ieNotDefined('modeName'), modeName = translateName(displayType); end

modeInformation  = viewGet(v,modeName);

if ieNotDefined('fname')
    [filename, pathname] = uiputfile('*.mat', 'Save colormap information');
    fname = fullfile(pathname,filename)
end

save(fname,'modeInformation','displayType');

return;

%-----------------------------
function modeName = translateName(displayType)
%

switch(displayType)
    case 'ph'
        modeName = 'phMode';
    case 'amp'
        modeName = 'ampMode';
    case 'co'
        modeName = 'coMode';
    case 'map'
        modeName = 'mapMode';
    otherwise
        error('Unknown mode name')
end

return;