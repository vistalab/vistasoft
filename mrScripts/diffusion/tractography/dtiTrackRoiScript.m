function dtiTrackRoiScript(dt6File, roiFile, trackOpts)
%
% dtiTrackRoiScript(dt6File, roiFile, trackOpts)
%roi must be in native dt (acpc) space

%??? wrote it???
%04/29/08: ER fixed a little

if(~exist('dt6File','var') | isempty(dt6File))
  [f,p] = uigetfile('*.mat', 'Load the dt6 file');
  dt6File = fullfile(p,f);
end
if(~exist('roiFile','var') | isempty(roiFile))
  [f,p] = uigetfile('*.mat', 'Load the ROI file');
  roiFile = fullfile(p,f);
end
if(exist(fullfile(fileparts(dt6File),'fibers'),'dir')) 
  fiberPath = fullfile(fileparts(dt6File),'fibers');
else 
  fiberPath = fileparts(dt6File); 
end

if(~exist('trackOpts','var'))
    trackOpts = [];
end

dt = dtiLoadDt6(dt6File);
dt.dt6(isnan(dt.dt6)) = 0;


roi = dtiReadRoi(roiFile, dt.xformToAcpc);
fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVoxel, dt.xformToAcpc, [roi.name 'FG'], trackOpts);
if(isfield(trackOpts,'fgFileName'))
    fgFile = trackOpts.fgFileName;
else
    fgFile = fullfile(fiberPath, [fg.name '.mat']);
end
if(exist(fgFile,'file'))
  [f,p] = uiputfile('*.mat','Save fibers',fgFile);
  if(isnumeric(f)) error('user canceled.'); end
  fgFile = fullfile(p,f);
end
disp(['Saving ' fgFile '...']);
dtiWriteFiberGroup(fg, fgFile, 1, 'acpc');
return;
