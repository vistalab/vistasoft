function dtiInitCtr(dwParams,dwDir)
% 
%  function dtiInitCtr(dwParams,dwDir);
% 
% Initialize the conTrack directory stucture for dtiInit. This function
% will setup the conTrack directory and options file if it doesn't exist or
% we need to clobber
%
% INPUTS
%   dwParams - structure created from within dtiInit containing the relevant
%              directory information.
%   dwDir    - structure created from within dtiInit containing the relevant
%              directory information. 
%
% RETURNS
%   None.
% 
% Web Resources
%   mrvBrowseSVN('dtiInitCtr');
%
% Example:
%   dtiInitCtr(dwParams,dwDir);
%
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%% Setup conTrack directory 
% 
    % fibers/conTrack directory now inside the dti* folder
    % If it does not exist we create it here.
fiberDir = fullfile(dwParams.dt6BaseName,'fibers');
    if(~exist(fiberDir,'dir')); mkdir(fiberDir); end;
conTrackDir = fullfile(fiberDir,'conTrack');
    if(~exist(conTrackDir,'dir')); mkdir(conTrackDir); end;
paramsName = fullfile(conTrackDir,'met_params.txt');
    % Create ROIs directory in the subjects dir
roiDir = fullfile(dwDir.subjectDir,'ROIs');
    if ~exist(roiDir,'dir'); mkdir(roiDir); end


%% Create conTrack options file if it doesn't exist or we need to clobber
bWriteParams = 0;
if( dwParams.clobber == 1 || ~exist(paramsName,'file') )
    bWriteParams = 1;
else
    if( dwParams.clobber == 0 && exist(paramsName,'file') )
        resp = questdlg([paramsName ' exists- would you like to overwrite it?'],...
            'Clobber conTrack params', 'Overwrite','Use Existing File','Abort',...
            'Use Existing File');
        if(strcmpi(resp,'Abort')); error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            bWriteParams = 1;
        end
    end
end
if( bWriteParams )
    mtr = mtrCreate();
    mtr = mtrSet(mtr, 'tensors_filename', fullfile(dwDir.subjectDir,'bin','tensors.nii.gz'));
    mtr = mtrSet(mtr, 'fa_filename',      fullfile(dwDir.subjectDir,'bin','wmMask.nii.gz'));
    mtr = mtrSet(mtr, 'pdf_filename',     fullfile(dwDir.subjectDir,'bin','pddDispersion.nii.gz'));
    mtrSave(mtr,paramsName);
end

return

