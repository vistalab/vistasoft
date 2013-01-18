function v = cmapImportModeInformation(v,modeName,fname)
%
%   v = cmapImportModeInformation(v,[modeName],[fname])
%
%Author: AB, BW
%Purpose:
%    Import the color information that was used to make a particular image.  The
%    user is queried for a file name if none is passed in.  The view is set
%    to the display mode specified in modeName.  
%
% Example:
%
% v = FLAT{1};
% v = cmapImportModeInformation(v);
%

% Programming Notes:
%   I am not sure why the mode is managed in this routine.  I think it is
%   because of the way mode information is stored in the view, though.

if ieNotDefined('v'), error('Must specify a view.'); end

if ieNotDefined('fname')
    [filename, pathname] = uigetfile('*.mat', 'Load colormap information');
    fname = fullfile(pathname,filename);
end

load(fname,'modeInformation','displayType');

if ieNotDefined('modeName'), modeName = translateName(displayType); end

v  = viewSet(v,modeName,modeInformation);
v  = viewSet(v,'displaymode',displayType);

return;

%-----------------------------
function modeName = translateName(displayType)
%

switch(displayType)
    case {'ph','phase','phasemode'}
        modeName = 'phMode';
    case {'amplitude','amp','ampmode'}
        modeName = 'ampMode';
    case {'coherence','co','coherencemode'}
        modeName = 'coMode';
    case {'map','parametermap'}
        modeName = 'mapMode';
    otherwise
        error('Unknown mode name')
end

return;