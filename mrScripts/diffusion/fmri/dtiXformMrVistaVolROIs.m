function dtiXformMrVistaVolROIs(dt6file,roiList,vAnatomy,saveDir)

% USAGE: dtiXformMrVistaVolROIs(dt6file,roiList,[vAnatomy],[savedroisDir])
% SCRIPT: mrDiffusion/analysisScripts/dti_FFA_xformMrVistaVolRois.m
%
% This function is a scripted version of dtiXformRoiToMrVistaVolume and
% dtiXformVanatRoi. It transforms specified ROIs defined on the mrVista
% volume to mrDiffusion and saves them. 
%
% If there is no mrVista transform computed and saved to the dt6, a
% transform is computed from the vAnatomy file. Otherwise, the vAnatomy is
% optional. 
%
% DT6FILE: dt6.mat file name
% ROILIST: file names of ROIs to transform in a cell array, if multiple
% VANATOMY: vAnatomy.dat file name (optional if mrvista xform saved to dt6)
% SAVEDIR: location to save transformed ROIs (default to dti30/ROIs)
%
% By: DY 03/2008

% Check for and load dt6 file
if (~exist(dt6file,'file'))
    fprintf(1,'\nFAILURE: no dt6 file found\n');
    return
else
    dt6=load(dt6file);
end
         
% Check for dt6 XFORMVANATTOACPC field: this is a 4x4 matrix. If this field
% does not exist, check for vAnatomy and compute the xform.
if (~isfield(dt6,'xformVAnatToAcpc') || isempty(dt6.xformVAnatToAcpc))
    if (~exist('vAnatomy','var')||isempty(vAnatomy))
        fprintf(1,'\nFAILURE: no xform computed, and no vAnatomy found\n');
        return 
    else % compute the xform
        [vAnatomyData,vAnatMm] = readVolAnat(vAnatomy); % Get VAnatomy
        % Get t1.nii.gz info
        subjDir=fileparts(fileparts(dt6file));
        ni = niftiRead(fullfile(subjDir,dt6.files.t1));
        dtiAcpcXform = ni.qto_xyz;
        dtiT1 = double(ni.data);
        mmPerVox = ni.pixdim;
        % Compute xform
        [xformVAnatToAcpc] = dtiXformVanatCompute(dtiT1, dtiAcpcXform, vAnatomyData, vAnatMm);
        % Save xform to dt6 struct
        save(dt6file,'xformVAnatToAcpc','-APPEND');
        % Add xform field to current dt6 variable
        dt6.xformVAnatToAcpc=xformVAnatToAcpc;
    end
else
    fprintf(1,'\n mrVista XFORM found -- no need to compute new xform \n')
end

% Load ROIs, transform the coordinates, and save the ROIs to the subject's
% DTI ROIs directory. 
for ii=1:length(roiList)
    if(~exist(roiList{ii},'file'))
        fprintf(1,'\nROI %s does not exist, skipping\n',roiList{ii});
    else
        roi2xform=load(roiList{ii});
        coords=mrAnatXformCoords(dt6.xformVAnatToAcpc, roi2xform.ROI.coords);
        roi = dtiNewRoi(roi2xform.ROI.name, roi2xform.ROI.color, coords);
        % If SAVEDIR not specified in input arguments
        if (~exist('saveDir','var')||isempty(saveDir))
            saveDir=fullfile(fileparts(dt6file),'ROIs');
        end
        % Make the SAVEDIR if it doesn't exist
        if (~isdir(saveDir))
            mkdir(saveDir);
        end
        % Save the ROI in the way dtiFiberUI likes
        dtiWriteRoi(roi,[fullfile(saveDir,roi.name) '.mat']);
        [tmp roi]= fileparts(roiList{ii});
        disp(sprintf(['\nSaved ' roi '.mat to ' saveDir]));
    end
end
