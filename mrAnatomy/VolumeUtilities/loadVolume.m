function [img, mmPerPix, vSize, fname, format] = loadVolume(pth)
%Read one of a variety of types of volume anatomies
%
% [img, mmPerPix, vSize, fname, format] = loadVolume([file or directory])
%
% An expanded version of loadVolumeDataAnyFormat (with a slightly
% less-unwieldy name). A generic function for loading MRI volume data.
% Hopefully this will be expanded as more file types are being worked
% with. 
% 
% The first argument can be the name/path of a single file (for formats
% like Analyze .img, mrVista .dat, etc containing and MRI volume, the first
% file in a directory, for formats like DICOM or Genesis I-files in which
% the volume is spread across several files (e.g. Ifiles/I.001), or else 
% the directory containing these files (e.g.'Ifiles). If omitted, a dialog
% pops up.
%
% Supported formats are:
%   * mrVista .dat (e.g. vAntomy.dat)
%   * ANALYZE .img or .hdr
%   * Gensis I-file (I.###)
%   * DICOM   .dcm
%   * Freesurfer/FS-FAST .bshort
%   * Freesurfer/FS-FAST .bfloat
%   * Lucas P*.mag fuctional files
%
% Examples:
%    [img, mmPerPix, vSize, fname, format] = loadVolume;
%  
% 02/14/05 ras. 

img = []; mmPerPix = []; vSize = []; fname = []; format = [];

% if pth is empty, have the user select the proper file. 
if ieNotDefined('pth')
    pth = mrvSelectFile('r');
    if isempty(pth), return;
    elseif ~exist(pth,'file'), error(sprintf('%s not found.\n',pth));
    end
else
    % If the user sent in pth, then it might be a directory containing I-files
    if exist(pth,'dir')
        ifileCheck = dir(fullfile(pth,'I*'));
        if ~isempty(ifileCheck)
            pth = fullfile(pth,ifileCheck(1).name);
        end
    end
end

[p,fname,ext] = fileparts(pth);

switch lower(ext)
    case '.dat',
        % vanat .dat
        format = 'vanat';
        [img, mmPerPix, vSize] = readVolAnat(pth);
    case {'.hdr','.img'},
        % ANALYZE
        format = 'analyze';
        [img, mmPerPix, hdr] = analyzeRead(pth);
		% we'll go ahead and reorient this to I|P|R orientation from R|A|S
		img = mrAnatRotateAnalyze(img);
		mmPerPix = mmPerPix([3 2 1]);		
        vSize = size(img);
	case {'.nii', '.gz'},
		% NIFTI (or compressed NIFTI)
		format = 'nifti';
		mr = mrLoad(pth);
		% we'll go ahead and reorient this to I|P|R orientation from R|A|S
		img = mrAnatRotateAnalyze(mr.data);
		mmPerPix = mr.voxelSize([3 2 1]);
		vSize = size(img);
		fname = mr.path;
    case '.bshort',
        % FS-FAST .bshort
        format = 'bshort';
        img = loopOverAnatFiles(p,'*.bshort','readBshort');
    case '.bfloat',
        % FS-FAST .bfloat
        format = 'bshort';
        img = loopOverAnatFiles(p,'*.bshort','readBfloat');
    case '.mag',
        % P*.mag functional file
        format = 'pmag';
        img = readMagFile(pth);
    case '.dcm',
        % DICOM
        format = 'dicom';
        img = loopOverAnatFiles(p,'*.dcm','ReadMRImage');
    otherwise,
        % check if it's a GENESIS I-file: extension should be numeric
        if ~isempty(str2num(ext(2:end)))
            % numeric extension -- try to load I-files
            format = 'ifile';
            img = loopOverAnatFiles(p,'I*','ReadMRImage');
        else
            error('Unknown file format!');
        end
end

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function img = loopOverAnatFiles(parent,pattern,func);
% img = loopOverAnatFiles(parent,pattern,func);
% Within the specified parent directory, find all files
% of the specified pattern and load them with the specified
% function.
img = [];
if ~exist(parent,'dir')
    warning(sprintf('Directory %s not found.',parent));
    return
end
flag4D = 0;
callingDir = pwd;
cd(parent);
w = dir(pattern);
fnames = {w.name};
cd(callingDir);
fprintf('Looping across files');
for i = 1:length(fnames)
    filepath = fullfile(parent,fnames{i});
    subvol = eval(sprintf('%s(''%s'');',func,filepath));
    if size(subvol,3) <= 1 % 2D image
        img(:,:,i) = subvol;
    else
        % try to build up a 4D matrix --
        % assume 3rd dimension is time
        img(:,:,:,i) = subvol;
        flag4D = 1; % will permute later
    end
    fprintf('.')
end
fprintf('done.\n');
if flag4D==1
    img = permute(img,[1 2 4 3]);
end
return
        
