function fmri_loc1_computeContrastsLocalizer(hI, lo_scan)

% Usage: fmri_loc1_computeContrastsLocalizer(hI, lo_scan)
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
% AL 11/08 modified for loc1 GLM
%
% TODO: Make a function that builds the contrast names from a dictionary as
% specified above (e.g., 0='blank') so that there isn't room for typos, etc
% in the contrast naming below. 

hI = setCurScan(hI,lo_scan);

hI=computeContrastMap2(hI, [1 2], [5 6],'loc1_ManChildVObjCar');
hI=computeContrastMap2(hI, [1 2], [5 6],'loc1_ManChildVObjCar_T','map','t');

hI=computeContrastMap2(hI, [1 2], [3 4],'loc1_ManChildVIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [3 4],'loc1_ManChildVIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [7 8],'loc1_ManChildVText');
hI=computeContrastMap2(hI, [1 2], [7 8],'loc1_ManChildVText_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc1_ManChildVObjCarIndoorOutdoor');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc1_ManChildVObjCarIndoorOutdoor_T','map','t');

hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc1_ManChildVObjCarIndoorOutdoorText');
hI=computeContrastMap2(hI, [1 2], [5 6 3 4],'loc1_ManChildVobjCarIndoorOutdoorText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2],'loc1_IndoorOutdoorVManChild');
hI=computeContrastMap2(hI, [3 4], [1 2],'loc1_IndoorOutdoorVManChild_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6],'loc1_IndoorOutdoorVObjCar');
hI=computeContrastMap2(hI, [3 4], [5 6],'loc1_IndoorOutdoorVObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [7 8],'loc1_IndoorOutdoorVText');
hI=computeContrastMap2(hI, [3 4], [7 8],'loc1_IndoorOutdoorVText_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'loc1_IndoorOutdoorVManChildObjCar');
hI=computeContrastMap2(hI, [3 4], [1 2 5 6],'loc1_IndoorOutdoorVManChildObjCar_T','map','t');

hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'loc1_IndoorOutdoorVObjCarText');
hI=computeContrastMap2(hI, [3 4], [5 6 7 8],'loc1_IndoorOutdoorVObjCarText_T','map','t');

hI=computeContrastMap2(hI, [5 6], [7 8],'loc1_ObjCarVtext');
hI=computeContrastMap2(hI, [5 6], [7 8],'loc1_ObjCarVtext_T','map','t');

