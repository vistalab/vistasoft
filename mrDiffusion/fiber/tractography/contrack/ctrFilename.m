function txt = ctrFilename(str1,str2,tString,fType)
%Generate a Contrack file name for roi, pdf, sampler files
%
%   txt = ctrFilename(str1,str2,tString,fType)
%
% This routine encapsulates the methods for creating Contrack file names
% for the processed ROI, the PDF, and the Sampler.
%
% This routine has lots of problems we need to coordinate it with ctrInit,
% and we need to make sure the file names are all relative to the dt6
% directory.
%
% Example:
%   ctrFilename([],[],[],'xmask')
%   ctrFileName('roi1','roi2','hiya','roi')
%

% Hmm... I wonder if we should be making this stuff up or throwing an
% error? 
if notDefined('str1'), str1 = ''; end
if notDefined('str2'), str2 = ''; end
if notDefined('tString'), tString = ''; end
if ieNotDefined('fType'), fType = 'roi'; end

%
switch(lower(fType))
    case 'roi'
        txt = [str1,'_',str2,'_',tString,'.nii.gz'];
    case 'sampler'
        disp('Not yet implemented')
    case 'pdf'
        disp('Not yet implemented')
    case 'xmask'
        txt = 'None';
    otherwise
        error('Unknown Contrack file type')
end

return

% Example
% samplerOptsFile   = fullfile(localSubDir,'conTrack',['ctrParams_',curTime,'.txt']);
% roisMaskFile      = fullfile(localSubDir,dt6Dir,'bin',['roisMask_',curTime,'.nii.gz']);
% xMaskFile         = fullfile(localSubDir,dt6Dir,'bin',['xMask_',curTime,'.nii.gz']);
