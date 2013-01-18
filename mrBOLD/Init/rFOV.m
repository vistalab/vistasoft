function anat =  rFOV(fovRatio, dirName)

% anat =  rFOV(fovRatio[, dirName]);
%
% Reduce the FOV of inplanes by the rational fraction provided by the input
% fovRatio, a 2-element vector. The FOV is precisely adjusted to the
% original value scaled by fovRatio(1)/fovRatio(2). An optional mrVISTA
% directory can be provided; default value is pwd. Inplane anatomy is
% returned. Updated anat.mat file with new anat and inplanes variables is
% created, and mrSESSION is updated as well.
%
% Ress, 9/03

if ~exist('dirName', 'var'), dirName = pwd; end

aFile = fullfile(dirName, 'Inplane', 'anat.mat');
load(aFile);

[anat, inplanes] = ReduceFOV(anat, inplanes, fovRatio);

save(aFile, 'anat', 'inplanes');

sFile = fullfile(dirName, 'mrSESSION.mat');
load(sFile);
mrSESSION.inplanes = inplanes;

save(sFile, 'mrSESSION', 'dataTYPES')
