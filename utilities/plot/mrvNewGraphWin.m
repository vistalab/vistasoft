function figHdl = mrvNewGraphWin(ftitle,fType)
% Open a new graph window  
%
%    figHdl = mrvNewGraphWin([title],[fType])
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
%
% (c) Stanford VISTA Team

figHdl = figure;

if notDefined('ftitle'), ftitle = 'mrVista: '; 
else                     ftitle = sprintf('mrVista: %s',ftitle);
end
if notDefined('fType'), fType = 'upper left'; end

set(figHdl,'Name',ftitle,'NumberTitle','off');
set(figHdl,'Color',[1 1 1]);

% Position the figure
fType = mrvParamFormat(fType);
switch(fType)
    case 'upperleft'
        set(figHdl,'Units','normalized','Position',[0.007 0.55  0.28 0.36]);
    case 'tall'
        set(figHdl,'Units','normalized','Position',[0.007 0.055 0.28 0.85]);
    case 'wide'
        set(figHdl,'Units','normalized','Position',[0.007 0.62  0.7  0.3]);
    otherwise % default
end

return;
