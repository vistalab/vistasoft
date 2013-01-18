function averageAnalyze(fileNameList, outFileBaseName);
% averageAnalyze(fileNameList, outFileBaseName)
%
% Uses spm2's 'spm_realign' and spm_reslice' to coregister and average the
% list of analyze-format input files.
%
% REQUIRES:
%  * Stanford anatomy tools (eg. /usr/local/matlab/toolbox/mri/Anatomy)
%  * spm2 tools (eg. /usr/local/matlab/toolbox/mri/spm2)
%
% HISTORY:
% 2002.09.12 RFD (bob@white.stanford.edu) wrote it.
% 2002.09.12 RFD changed interpolation method to sinc and added a normalization
%                step so that images with different intensity ranges are weighted equally.
% 2003.06.21 DHB (brainard@psych.upenn.edu) Add use of MATLAB's preferences
%                to find FSL software.  Shouldn't break anything that used
%                to work, but I haven't tested on a PC.  I tried to
%                maximize use of fullfile() to minimize chance of breaking
%                things.
% 2004.06.17 RFD & MBS: Major change- now uses spm2 functions for
%            coregistration & reslicing rather than fsl command-line tools.

if (~exist('fileNameList','var') | isempty(fileNameList) | ...
        ~exist('outFileBaseName','var') | isempty(outFileBaseName))
    help(mfilename);
    return;
end

% % allow cells of file names
% if iscell(fileNameList), fileNameList = strvcat(fileNameList); end

% Coregister
%
flagsC.quality = 1;
flagsC.fwhm = 3;
flagsC.sep = 4;
flagsC.interp = 2;
flagsC.rtm = 0;
spm_realign(fileNameList, flagsC);

% Reslice
%
flagsR.mask = 0;
flagsR.mean = 1;
flagsR.which = 0;
flagsR.interp = 7; % b-spline interpolation- we use the maximum quality (7)
spm_reslice(fileNameList, flagsR);
% Unfortunately, we can't tell spm_reslice how to name the output files.
[p,f,e] = fileparts(fileNameList{1});
movefile(fullfile(p,['mean' f '.hdr']), [outFileBaseName '.hdr']);
movefile(fullfile(p,['mean' f '.img']), [outFileBaseName '.img']);
%movefile(fullfile(p,['mean' f '.img']), [outFileBaseName '.mat']);
return;
