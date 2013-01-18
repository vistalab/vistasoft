function fmri_FFA_computeContrastsLocalizer(hI, lo_scan)

% Usage: fmri_FFA_computeContrastsLocalizer(hI, lo_scan)
%
% hI: view for GLM dataTYPE (output by applyGlm function)
% lo_scan: number of localizer scan within GLMs dataTYPES
%
% This code is appropriate only for the LO localizer scans with
% parfiles corresponding to the conditions listed below:
% 0 blank baseline
% 1 child faces
% 2 man faces
% 3 indoor places
% 4 outdoor places
% 5 jeeps
% 6 abstract objects
% 7 text
% 8 text
% 9 noise
%
% DY 06/05/2008
%
% TODO: Make a function that builds the contrast names from a dictionary as
% specified above (e.g., 0='blank') so that there isn't room for typos, etc
% in the contrast naming below. 

hI = setCurScan(hI,lo_scan);

hI=computeContrastMap2(hI, [1 2], [5 6],'ManChildVObjJeep');
hI=computeContrastMap2(hI, [1 2], [5 6],'ManChildVObjJeep_T','map','t');

hI=computeContrastMap2(hI, [1 2], [3 4],'ManChildVIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [3 4],'ManChildVIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [7 8],'ManChildVText');
hI=computeContrastMap2(hI, [1 2], [7 8],'ManChildVText_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjJeepIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjJeepIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjJeepIndoorOutdoorText');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVobjJeepIndoorOutdoorText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2],'IndoorOutdoorVManChild');
hI=computeContrastMap2(hI, [3 4], [1 2],'IndoorOutdoorVManChild_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6],'IndoorOutdoorVObjJeep');
hI=computeContrastMap2(hI, [3 4], [5 6],'IndoorOutdoorVObjJeep_T','map','t');

hI=computeContrastMap2(hI, [3 4], [7 8],'IndoorOutdoorVText');
hI=computeContrastMap2(hI, [3 4], [7 8],'IndoorOutdoorVText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'IndoorOutdoorVManChildObjJeep');
hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'IndoorOutdoorVManChildObjJeep_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'IndoorOutdoorVObjJeepText');
hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'IndoorOutdoorVObjJeepText_T','map','t');

hI=computeContrastMap2(hI, [5 6], [7 8],'ObjJeepVtext');
hI=computeContrastMap2(hI, [5 6], [7 8],'ObjJeepVtext_T','map','t');

