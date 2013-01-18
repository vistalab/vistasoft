function fmri_loc2_computeContrastsLocalizer(hI, lo_scan)

% Usage: fmri_loc2_computeContrastsLocalizer(hI, lo_scan)
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

hI=computeContrastMap2(hI, [1 2], [5 6],'loc2_ManChildVObjCar');
hI=computeContrastMap2(hI, [1 2], [5 6],'loc2_ManChildVObjCar_T','map','t');

hI=computeContrastMap2(hI, [1 2], [3 4],'loc2_ManChildVIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [3 4],'loc2_ManChildVIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [7 8],'loc2_ManChildVText');
hI=computeContrastMap2(hI, [1 2], [7 8],'loc2_ManChildVText_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc2_ManChildVObjCarIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc2_ManChildVObjCarIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc2_ManChildVObjCarIndoorOutdoorText');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc2_ManChildVobjCarIndoorOutdoorText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2],'loc2_IndoorOutdoorVManChild');
hI=computeContrastMap2(hI, [3 4], [1 2],'loc2_IndoorOutdoorVManChild_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6],'loc2_IndoorOutdoorVObjCar');
hI=computeContrastMap2(hI, [3 4], [5 6],'loc2_IndoorOutdoorVObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [7 8],'loc2_IndoorOutdoorVText');
hI=computeContrastMap2(hI, [3 4], [7 8],'loc2_IndoorOutdoorVText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'loc2_IndoorOutdoorVManChildObjCar');
hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'loc2_IndoorOutdoorVManChildObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'loc2_IndoorOutdoorVObjCarText');
hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'loc2_IndoorOutdoorVObjCarText_T','map','t');

hI=computeContrastMap2(hI, [5 6], [7 8],'loc2_ObjCarVtext');
hI=computeContrastMap2(hI, [5 6], [7 8],'loc2_ObjCarVtext_T','map','t');

