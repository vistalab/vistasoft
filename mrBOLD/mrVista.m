function [vw, s] = mrVista(windowType, varargin)
%Open the mrLoadRet (mrVista) package with a specific window type 
% 
%  [vw, s] = mrVista(windowType or 'help', [options])
%
% This script opens windows of several types:
%    'inplane','flat','volume','gray','3view', 'vol3view'
%
% You can also specify a particular vAnatomy file as a second input argument.  
% This is handy when you are working in a place where the default anatomy 
% folder is unavailble.
%
% For flat views, the second input argument can specify the name of the
% flat unfold to use. (mrVista allows you to install multiple unfolds, with
% different sizes and centered on different parts of gray matter) If you
% have multiple unfolds and omit this argument, you'll be asked to choose
% from a dialog.
%
% mrVista replaces the mrLoadRet script.  That script only opens an inplane
% window.  
%
% EXAMPLES:
%   mrVista('inplane')  % opens an inplane montage window
%
%	mrVista('flat', 'flatV1'); % opens a flat view with the flat patch
%							   % named 'flatV1'
%
%   myAnat = 'C:\u\brian\Matlab\mrDataExample\pn-anatomy\vAnatomy.dat';
%   mrVista('gray',myAnat');
%
%   [vw, s] = mrVista('inplane');  % opens an inplane montage window
%   mrVista('3'); % opens volume 3-view window with the default volume
%				  % anatomy
%
%	mrVista help  % opens the mrVista main page in a browser window
%
% REVISIONS:
%
% ras, 04/09 -- Several updates:
% (1) Added option to open a volume 3-view window ('v3' or 'vol3view'), as
% opposed to a gray 3-view window.
% (2) Added support for the 'help' option.
% (3) Allows you to pass in the flat subdirectory as an optional argument. 
% (4) I noticed the 'localAnatomy' option wasn't supported (must've been my
% own, older edit); since this might be useful to people, I re-enabled it,
% but only for volume/gray views (where you need to load the volume anat).
% (5) updated comments.

% Docs are kind of strewn all over, but at least this link will resolve
mrVistaHelpURL = 'https://github.com/vistalab/vistasoft/wiki';

if notDefined('windowType'), windowType = 'inplane'; end

% Define global variables and structures.
mrGlobals; %Defines mrSESSION and dataTYPES
evalin('base','mrGlobals');

% Check Matlab version number
% Change list after testing Matlab upgrades
earliestSupportedMatlabversion = '7.9';
notYetSupportedMatlabversion = '9.3.1';
if verLessThan('matlab', earliestSupportedMatlabversion)
    warning('Matlab version %s is less than the earliest supported Matlab version in vistasoft, %s.', version, earliestSupportedMatlabversion);
end
if ~verLessThan('matlab', notYetSupportedMatlabversion)
    warning('Matlab version %s is still being tested with vistasoft.', version);
end

%% set global variables/properties

% Set HOMEDIR 
HOMEDIR = pwd; %#ok<NASGU>

% Load mrSESSION structure
loadSession; %Requires a mrSESSION.mat file in the current directory called

% allow the user to set the volume anatomy, for volume/gray views
if ismember(windowType, {'v' 'volume' 'g' 'gray' '3' '3view'}) && ...
	~isempty(varargin) && ~isempty(varargin{1})
	setVAnatomyPath(varargin{1});
end
	
% open the appropriate window
switch lower(windowType)
   case {'i','m','inplane', 'montage'}
       [vw, s] = openMontageWindow;
   case {'f','flat'}
	   if ~isempty(varargin)
		   flatDir = varargin{1};
		   [s, vw] = openFlatWindow(flatDir);
	   else
	       [s, vw] = openFlatWindow;
	   end
   case {'v','volume'}
       [s, vw] = openVolumeWindow;
   case {'g','gray'}
       [s, vw] = openGrayWindow;
   case {'3','3view'}
       [vw, s] = open3ViewWindow('gray');
	case {'v3' '3v' 'vol3view'}
		[vw, s] = open3ViewWindow('volume');
    case {'help'}
        try
            web(mrVistaHelpURL,'-browser');
        catch  %#ok<CTCH>
            web(mrVistaHelpURL);
        end
   otherwise
       error('Unknown window type.');
end

%% clean up
clear expectedMatlabVersion version matlabVersion

return;
