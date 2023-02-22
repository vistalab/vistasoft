function mapVolROIs(datadr,sessions,volROIfiles)
%
% mapVolROIs(datadr,sessions,volROIs)
%
% maps ROIs from Volume to Inplane for each scanning session
%
% djh, 11/3/98
% wap, 11/16/99 - allowed volROIfiles to be a columnar cell array

global mrSESSION

for s = 1:length(sessions)
  session = sessions(s);
  disp(['session: ',session.subdir]);
  sessiondr = fullfile(datadr,session.subdir);
  eval(['load ',fullfile(sessiondr,'mrSESSION')]);
  
  hiddenInplane = initHiddenInplane;
  hiddenVolume = initHiddenVolume;
  
  for r=1:size(volROIfiles,1)
    if iscell(volROIfiles)
      ROIfile = volROIfiles{r};
    else
      ROIfile = volROIfiles(r,:);
    end
    hiddenVolume = loadROI(hiddenVolume,ROIfile,1);
    volROI = hiddenVolume.ROIs(hiddenVolume.selectedROI);
    ROI = vol2ipROI(volROI,hiddenVolume,hiddenInplane);
    ROI.viewType = 'inplane';
    % Save it
    subdir = hiddenInplane.subdir;
    pathStr = fullfile(sessiondr,subdir,'ROIs',ROIfile);
    saveStr=['save ',pathStr,' ROI'];
    eval(saveStr);
  end
end

return

% Debug
datadr = fullfile('e:','mri');
sessions(1).subdir = 'test';
volROIfiles=cell(2,1);
volROIfiles{1}='fovea';
volROIfiles{2}='fV1';
mapVolROIs(datadr,sessions,volROIfiles);
