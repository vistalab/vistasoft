function [wm, gm, csf] = mrAnatSpmSegment(vol, xformVol2Physical, templateFileName)
% SPM segmenter applied to volume data
%
% [wm, gm, csf] = mrAnatSpmSepment(vol, xformVol2Physical, templateFileName)
%
% Volume data (vol), such as vAnatomy.dat, are segmented using SPM2.  The
% process involves two steps. First the data are transformed to match a
% template.  This template file is either sent in (templateFileName) or the
% user selects the file. The default is the MNI T1.mnc template.
%
% The parameter xformVol2Physical converts the vol coordinates into the coordinates of
% the template space.  These templates are described in physical units (mm,
% with origins). This transform is used by the SPM segmenter, but not
% internally to this code.
%
% The SPM segmenter returns three volumes defining the locations of the
% gray matter (gm), white matter (wm) and cerebrospinal fluid (csf).  These
% are returned.  We only use the wm variable.  This variable initiates the
% process of growing gray matter using the mrGray set of tools.
%
% eg.
% [f,p] = uigetfile('*.nii*','Select a NIFTI t1 volume...');
% ni = niftiRead(fullfile(p,f));
% [wm, gm, csf] = mrAnatSpmSegment(ni.data,ni.qto_xyz,'MNIT1');
% dots = strfind(f,'.'); fn = f(1:dots(1)-1);
% dtiWriteNiftiWrapper(wm,ni.qto_xyz,fullfile(p,[fn '_wm']),1,'wm probability');
%
% HISTORY:
% 2005.02.15 RFD: wrote it.

if(~exist('templateFileName','var') || isempty(templateFileName))
    spmDir = fileparts(which('spm_defaults'));
    d = dir(fullfile(spmDir, 'templates', 'T1.*'));
    templateFileName = fullfile(spmDir, 'templates', d(1).name);
    [f,p] = uigetfile({'*.nii*','NIFTI files';'*.mnc','MINC files';'*.img','Analyze files';'*.*','All files'}, ...
        'Select realignment template', templateFileName);
    if(isnumeric(f)) disp('User cancelled.'); return; end
    templateFileName = fullfile(p,f);
end
if(~exist(templateFileName,'file'))
    % try to guess
    spmDir = fileparts(which('spm_defaults'));
    if(strcmpi(templateFileName,'mnit1'))
        templateFileName = fullfile(spmDir, 'templates', 'T1.');
    elseif(strcmpi(templateFileName,'mnit2'))
        templateFileName = fullfile(spmDir, 'templates', 'T2.');
    elseif(strcmpi(templateFileName,'mnipd'))
        templateFileName = fullfile(spmDir, 'templates', 'PD.');
    elseif(strcmpi(templateFileName,'mniepi'))
        templateFileName = fullfile(spmDir, 'templates', 'EPI.');
    else
        error('Couldn''t guess template.');
    end
    if(strcmpi(spm('ver'),'SPM2')) templateFileName = [templateFileName 'mnc']; 
    elseif(strcmpi(spm('ver'),'SPM5')) templateFileName = [templateFileName 'nii'];
    else templateFileName = [templateFileName 'img']; end
    if(~exist(templateFileName,'file'))
        error('Couldn''t guess template.');
    end
end


% Make sure spm defaults are set.
spm_defaults; global defaults; 

% Set up the SPM parameters 
defaults.segment.write.wrt_cor = 0;
Vtemplate = spm_vol(templateFileName);
if(~strcmp(class(vol),'uint8'))
  vol = double(vol);
  vol = vol-min(vol(:));
  vol = uint8(vol./max(vol(:))*255);
end
if(strcmp(spm('Ver'),'SPM5'))
    Vin.dim = [size(vol)];
    Vin.dt = spm_type(class(vol));
else
    Vin.dim = [size(vol) spm_type(class(vol))];
end
Vin.dat = vol;
Vin.mat = xformVol2Physical; 
Vin.pinfo = [1 0]';
Vin.fname = [tempname '.img'];

% Run the segmenter
tc = spm_segment(Vin, Vtemplate, defaults.segment);

% Return the variables
gm = tc(1).dat;
wm = tc(2).dat;
csf = tc(3).dat;

return;
