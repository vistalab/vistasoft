function [s, vw] = openGrayWindow
%
%   [s, vw] = openGrayWindow
%
% Calls openRawVolumeWindow to set up the VOLUME data structure,
% opens and initializes the volume window.  Then calls switch2Gray.
%
% djh, 2/99
% Junjie 2004.02.14 let function return s

mrGlobals

s = openRawVolumeWindow;
VOLUME{s} = switch2Gray(VOLUME{s});

selectView(VOLUME{s});


% If user requested a view output, give it to them:
if nargout > 1,	vw = VOLUME{s}; end

return;