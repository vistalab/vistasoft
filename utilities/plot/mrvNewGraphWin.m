function figHdl = mrvNewGraphWin(ftitle,fType,visibility)
% Open a new graph window  
%
%    figHdl = mrvNewGraphWin([title],[fType],[visibility])
%
% A stanford mrVIsta graph window figure is opened and its handle is
% returned.
%
% By default, the window is placed in the 'upper left' of the screen.  The
% specifiable fTYpes are:
%
%    'upper left'
%    'tall'
%    'wide'
%
% Examples
%   mrvNewGraphWin;
%   mrvNewGraphWin('myTitle','tall')
%   mrvNewGraphWin('wideTitle','wide')
%   mrvNewGraphWin('wideTitle','wide')
%
% Franco Pestilli & Brian Wandell Stanford University
global GRAPHWIN


if notDefined('visibility'), visibility = 'on'; end

if notDefined('ftitle'), ftitle = 'mrVista: '; 
else                     ftitle = sprintf('mrVista: %s',ftitle);
end
if notDefined('fType'), fType = 'upper left'; end

% Position the figure
fType = mrvParamFormat(fType);
switch(fType)
    case 'upperleft'
        position = [0.007 0.55  0.28 0.36];
    case 'tall'
        position = [0.007 0.055 0.28 0.85];
    case 'wide'
        position = [0.007 0.62  0.7  0.3];
    otherwise % default
end

figHdl = figure('Name',ftitle, ...
                'NumberTitle','off', ...
                'visible',   visibility, ...
                'Color',[1 1 1], ...
                'Units','normalized', ...
                'Position',position);
            
GRAPHWIN=figHdl;
            
return;
