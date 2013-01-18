function inplanes = rtGetInplanes(examNum,ipSeries,doCrop);
%
% inplanes = rtGetInplanes(examNum,inplaneSeriesNum,[doCrop]);
%
% For pseudo real-time, copy over the DICOM files
% from the scanner for the selected inplane
% anatomical series (to the session Raw/Inplane dir),
% then read them in as in InitAnatomy and save/return
% the anat struct.
%
% ras 04/05
if ieNotDefined('examNum')
    examNum = input('Enter exam #: ');
end
if ieNotDefined('ipSeries')
    ipSeries = input('Enter series for Inplanes: ');
end
if ieNotDefined('doCrop')
    doCrop = input('Crop Inplanes? [1 for yes, 0 for no]: ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run a unix command to ssh over to    %
% the control machine (lcmr3) and get  %
% the DICOM images:                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first, the command to be executed at lcmr3:
xferCmd = sprintf(['/export/home/sdc/bin/lx_ximg ',...
                   'E%iS%iIall -d /usr/g/mrraw'],...
                   examNum,ipSeries);
% now, the ssh command to call this remotely
cmd = sprintf('ssh sdc@lcmr3 %s',xferCmd);

% execute
unix(cmd)

% now, make sure there's a local Raw/Inplane dir:
if ~exist(fullfile(pwd,'Raw'),'dir')
    mkdir Raw
    disp('Made Raw')
end

if ~exist(fullfile(pwd,'Raw','Anatomy'),'dir')
    mkdir Raw Anatomy
    disp('Made Raw/Anatomy')
end

if ~exist(fullfile(pwd,'Raw','Anatomy','Inplane'),'dir')
    mkdir Raw/Anatomy Inplane
    disp('Made Raw/Anatomy/Inplane')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Xfer the files to the local Raw dir %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find the file names
pattern = sprintf('/lcmr3/mrraw/E%iS%i*.MR.dcm',examNum,ipSeries);
w = dir(pattern);
nFiles = length(w);
if nFiles==0
    error('No matching files found!')
end
for i = 1:nFiles
    srcFile = sprintf('E%iS%iI%i.MR.dcm',examNum,ipSeries,i);
    tgtFile = sprintf('Raw/Anatomy/Inplane/I%03d.dcm',i);
    cmd = sprintf('cp /lcmr3/mrraw/%s %s',srcFile,tgtFile);
    unix(cmd);
    fprintf('Got %s \n',tgtFile);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now get the inplanes for mrVista %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[anat, inplanes] = InitAnatomy(pwd,'Raw',doCrop);

if doCrop==0
    %%% GUM
    inplanes.crop = [1 1; inplanes.fullSize];
    inplanes.cropSize = [inplanes.fullSize];
else
    [anat, inplanes] = CropInplanes('Raw',anat,inplanes,[1 1]);
end

% save the anat image locally
if ~exist(fullfile(pwd,'Inplane'),'dir')
    disp('Making Inplane directory');
    mkdir Inplane
end
save('Inplane/anat','anat');
disp('Saved Inplane/anat.mat file.')

% update mrSESSION
if exist('mrSESSION.mat','file')
    load mrSESSION
    mrSESSION.inplanes = inplanes;
    save mrSESSION mrSESSION -append
end

return