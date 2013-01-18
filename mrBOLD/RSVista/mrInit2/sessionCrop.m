function sessionCrop(sessDir, crop);
% Crop a mrVista 1.0 format session inplanes and functionals.
% 
% sessionCrop([sessDir=pwd], [crop=GUI]);
%
% The crop should be a 2x2 vector with the format:
%   [x1 y1; x2 y2].
%
% x1 should be the first x position in each inplane anatomical slice
% to include; x2 should be the end point, and so forth.
%
% Will adjust the crop bounds as needed to match the functional 
% voxels (such that the cropped inplanes and functionals both
% contain an integer number of voxels). Will update the 
% mrSESSION.inplanes.crop and cropSize fields, as well as those
% for mrSESSION.functionals. Will modify Inplane/anat.mat and 
% the Inplane/Original tSeries files. Clears out the mrSESSION.alignment
% field, since any alignment will need to be redone on the cropped 
% inplanes.
%
% Obviously, you want to do this before doing any further preprocessing
% or analyses.
%
% ras, 01/2007.
if notDefined('sessDir'),   sessDir = pwd;                      end
if notDefined('crop'),      crop = sessionCropGUI(sesDir);      end

%% check functional voxel size against inplane voxel size


%% update mrSESSION 
mrSESSION.inplanes.crop = crop;
mrSESSION.inplanes.cropSize = diff(crop, [], 2) + 1;

for i = 1:length(mrSESSION.functionals)
    mrSESSION.functionals(i).crop = funcCrop;
    mrSESSION.functionals(i).cropSize = diff(funcCrop, [], 2) + 1;
end
    

%% update Inplane/anat.mat

%% update tSeries

return