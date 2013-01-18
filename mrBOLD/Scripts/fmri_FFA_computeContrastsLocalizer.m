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
% 5 cars
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

hI=computeContrastMap2(hI, [1 2], [5 6],'ManChildVObjCar');
hI=computeContrastMap2(hI, [1 2], [5 6],'ManChildVObjCar_T','map','t');

hI=computeContrastMap2(hI, [1 2], [3 4],'ManChildVIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [3 4],'ManChildVIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [7 8],'ManChildVText');
hI=computeContrastMap2(hI, [1 2], [7 8],'ManChildVText_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjCarIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjCarIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVObjCarIndoorOutdoorText');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'ManChildVobjCarIndoorOutdoorText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2],'IndoorOutdoorVManChild');
hI=computeContrastMap2(hI, [3 4], [1 2],'IndoorOutdoorVManChild_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6],'IndoorOutdoorVObjCar');
hI=computeContrastMap2(hI, [3 4], [5 6],'IndoorOutdoorVObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [7 8],'IndoorOutdoorVText');
hI=computeContrastMap2(hI, [3 4], [7 8],'IndoorOutdoorVText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'IndoorOutdoorVManChildObjCar');
hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'IndoorOutdoorVManChildObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'IndoorOutdoorVObjCarText');
hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'IndoorOutdoorVObjCarText_T','map','t');

hI=computeContrastMap2(hI, [5 6], [7 8],'ObjCarVtext');
hI=computeContrastMap2(hI, [5 6], [7 8],'ObjCarVtext_T','map','t');

