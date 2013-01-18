function s = openGeneralGrayWindow
%
%   openGeneralGrayWindow
%
% Calls openRawGeneralVolumeWindow to set up the VOLUME data structure,
% opens and initializes the volume window.  Then calls switch2Gray.
%
% ARW 030606
mrGlobals

s = openRawGeneralVolumeWindow;

return;