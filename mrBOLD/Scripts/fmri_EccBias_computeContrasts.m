function fmri_EccBias_computeContrasts(hI, ecc_scan)

% Usage: fmri_EccBias_computeContrastsLocalizer(hI, ecc_scan)
%
% hI: view for GLM dataTYPE (output by applyGlm function)
% _scan: number of EccBias scan within GLMs dataTYPES
%
% This code is appropriate only for the LO localizer scans with
% parfiles corresponding to the conditions listed below:
% 0 blank baseline
% 1 face fovea
% 2 face periphery
% 3 place fovea
% 4 place periphery
% 5 noise
% 
% AL 09/17/2008
%
% TODO: Make a function that builds the contrast names from a dictionary as
% specified above (e.g., 0='blank') so that there isn't room for typos, etc
% in the contrast naming below. 

hI = setCurScan(hI,ecc_scan);

hI=computeContrastMap2(hI, [1 2], [3 4],'F(FovPer)vP(FovPer)');
hI=computeContrastMap2(hI, [1 2], [3 4],'F(FovPer)vP(FovPer)_T','map','t');

hI=computeContrastMap2(hI, [3 4], [1 2],'P(FovPer)vF(FovPer)');
hI=computeContrastMap2(hI, [3 4], [1 2],'P(FovPer)vF(FovPer)_T','map','t');

hI=computeContrastMap2(hI, [2 4], [1 3],'PER(FP)vFOV(FP)');
hI=computeContrastMap2(hI, [2 4], [1 3],'PER(FP)vFOV(FP)_T','map','t');

hI=computeContrastMap2(hI, [1 3], [2 4],'FOV(FP)vPER(FP)');
hI=computeContrastMap2(hI, [1 3], [2 4],'FOV(FP)vPER(FP)_T','map','t');

