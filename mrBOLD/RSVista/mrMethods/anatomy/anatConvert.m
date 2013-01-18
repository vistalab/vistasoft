function mr = anatConvert(anatPath, ifilePath, segPaths, savePath);
%
% mr = anatConvert(anatPath, [ifilePath], [segPaths], [savePath]);
%
% Convert a mrVista 1.0 anatomy (vAnatomy.dat or .img) to a newer
% mrVista 2.0 format (compressed NIFTI, plus extra information).
%
% INPUTS:
%   anatPath: path to input anatomy. Default: dialog.
%
%   ifilePath: optional path to I-file directory. If provided,
%   will read header info in the I-files that is not present in
%   the anat file, and save it.
%   
%   segPaths: cell array of paths to segmentation directories
%   (e.g. {'Right' 'Left'}). Each directory must contain both
%   a .class and .gray file, or else a saved segmentation.mat file
%   (see segCreate). Will remember these paths, and load the segmentations
%   when viewing the new anatomy.
%
%   savePath: path to save the resulting NIFTI file. Default is
%   '[anatPath].nii.gz' (as well as an '[anatPath].mat' file with
%   extended, mrVista2-specific info like the space definitions).
%
% 
% Additionally, if the file '[anatPath]_talairach' is found, (which is 
% created by computeTalairach.m), the code will load the talairach 
% transformation information, as well as information on 
% how to get into AC/PC space.
%
% OUTPUTS:
%   mr: new mr structure.
%
%
% ras, 11/2006.

warning('Will be deprecated. You should use mrAnatConvertVanatToT1Nifti');

if notDefined('anatPath')
    m = 'Select an Anatomy File to Update to mrVista 2.0 format';
    anatPath = mrvSelectFile('r', {'.dat' '.img'}, [], m, pwd);
end

if notDefined('ifilePath'), ifilePath = ''; end
if notDefined('segPaths'), segPaths = {}; end

[p f ext] = fileparts(anatPath);

if notDefined('savePath'), savePath = fullfile(p, [f '.nii.gz']); end

mr = mrLoad(anatPath);

if ~isempty(ifilePath) & (exist(ifilePath, 'dir') | exist(ifilePath, 'file'))
    ifiles = mrLoad(ifilePath);
    
    mr.info = mergeStructures(mr.info, ifiles.info);
    mr.hdr = mergeStructures(mr.hdr, ifiles.hdr);
    
    % check for scanner coords definition
    % (though note: if the vAnat is the result of averaging
    % multiple anatomies, this header won't accurately map back
    % to true scanner coordinates)    
    iScanner = cellfind({ifiles.spaces.name}, 'Scanner');
    if ~isempty(iScanner)
        mr.spaces(end+1) = ifiles.spaces(iScanner);
    end
end

% check for talairach path
talPath = fullfile(p, [f '_talairach.mat']);
if exist(talPath, 'file')
    mr.settings.talairach = load(talPath);
    mr = mrACPC(mr);
end

if ~isempty(segPaths)
    mr.settings.segPaths = segPaths;
end

mrSave(mr, savePath, 'nifti');


return
