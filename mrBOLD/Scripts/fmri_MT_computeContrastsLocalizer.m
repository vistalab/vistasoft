function fmri_MT_computeContrastsLocalizer(hI, mt_scan)

% Usage: fmri_FFA_computeContrastsLocalizer(hI, lo_scan)
%
% hI: view for GLM dataTYPE (output by applyGlm function)
% mt_scan: number of localizer scan within GLMs dataTYPES
%
% This code is appropriate only for the MT localizer scans with
% parfiles corresponding to the conditions listed below:
% 0 still
% 1 motion
% 
% AL 10/07/2008
%
% TODO: Make a function that builds the contrast names from a dictionary as
% specified above (e.g., 0='blank') so that there isn't room for typos, etc
% in the contrast naming below. 

hI = setCurScan(hI,mt_scan);

hI=computeContrastMap2(hI, 1, 0,'MotionVStill');
hI=computeContrastMap2(hI, 1, 0,'MotionVStill_T','map','t');
