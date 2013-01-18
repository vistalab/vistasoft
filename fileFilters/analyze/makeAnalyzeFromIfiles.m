function [img,hdr] = makeAnalyzeFromIfiles(ifileDir, outFileName, options,startIndex)
% [img,hdr] = makeAnalyzeFromIfiles(ifileDir, [outFileName], [options],[startIndex])
%
% ifileDir shall include the filename prefix- eg. 'spgr1/I' for I-files
% that look like 'I.001', 'I.002.dcm', etc...
%
% outFileName should not include '.hdr' or '.img'- just the base name.
% It defaults to a reasonable file name in the current working directory.
%
% options is a cell array specifying various little options. Currently 
% supported options:
%   'verbose' : displays various bits of information and progress (default).
%   'silent'  : opposite of verbose.
% 
% We will grab all suitable I-Files in ifileDir, the startIndex input is
% removed. If you did acquire many anatomies using the same prescription,
% you shall put them in separate folders respectively. -- Junjie
%
% The data in the resulting Analyze file will be oriented according to 
% the default Analyze convention- 'transverse unflipped' (orient code '0' in 
% the .hdr file). That is, the image will be reoriented so that left-right is 
% along the x-axis, anterior-posterior is along the y-axis, superior-inferior 
% is along the z-axis, and the leftmost, anterior-most, superior-most point is 
% at 0,0,0 (which, for Analyze, is the lower left-hand corner of the last slice). 
%
% To help you find the 0,0,0 point, a 4-pixel rectange is drawn there with a pixel
% value equal to the maximum image intensity.
%
% The reorientation involves only cannonical rotations and mirror flips- no
% interpolation is performed. Also, note that the reorientation depends on info
% in the GE I-file header- if this info is wrong, the reorientation will be wrong.
%
% REQUIRES:
%   * Stanford Anatomy and filter functions
%
% SEE ALSO: loadAnalyze, saveAnalyze, analyze2mrGray, mrGray2Analyze,
% makeAnalyzeFromRaw (that does all the hard work).
%
% HISTORY:
%   2002.05.31 RFD (bob@white.stanford.edu): wrote it.
%   2002.06.05 RFD: got it to actually work reliably.
%   2002.06.14 RFD: cleaned up the code and added more comments.
%   2003.06.19 RFD: Moved logic for computing the transform to the
%   cannonical pixel order from makeAnalyzeFromRaw to a separate function
%   (computeCannonicalXformFromIfile). What does that have to do with this
%   function? Well, in doing so, things got simple enough that we can just
%   do everything in here.
%   2004.01.24 Junjie: disable the startIndex input, with explanation.
%   2004.06.17 RFD: optionally reurns img and hdr.

if(~exist('ifileDir','var') | isempty(ifileDir))
    [f,p] = uigetfile({'*.dcm','DICOM';'*.*','All files'}, 'Select the first raw image file...');
    if(isnumeric(f))
        disp('User canceled.'); return;
    end
    ifileDir = fullfile(p,f);
    if(~exist('outFileName','var') | isempty(outFileName))
        [p,f] = fileparts(ifileDir);
        outFileName = fullfile(pwd, f);
    end
end
if(~ischar(ifileDir))
    help(mfilename);
    return;
end

if(exist('outFileName','file'))
    error([outFileName 'exists!']);
end
if(~exist('options','var'))
    options = {};
end
% if(~exist('startIndex','var'))
%     startIndex=1;
% end
% indSuffix = sprintf('%03d',startIndex);
if exist('startIndex','var');
    warning('startIndex no longer a valid input. Each folder shall contain only one series of anatomies, so that the code auto detect first and last slices');
end

[img2std, ifileBaseName, mmPerVox, imDim, notes] = computeCannonicalXformFromIfile(ifileDir);

% Load the image data 
disp(['Loading data from ', ifileDir, '...']);
img = int16(makeCubeIfiles(ifileDir, imDim([1,2]), 1:imDim(3))); %[startIndex:startIndex+imDim(3)-1]));

% The following does all the hard work.
%makeAnalyzeFromRaw(img, [ifileDir,'.001'], sprintf('%s.%03d',ifileDir,nSlices), nSlices, outFileName, options);
[img, mmPerVoxNew] = applyCannonicalXform(img, img2std, mmPerVox);

disp(['Saving ',outFileName,'.hdr and ',outFileName,'.img ...']);
hdr = saveAnalyze(img, outFileName, mmPerVoxNew, notes);

if(nargout<1)
    clear img hdr;
end
return;