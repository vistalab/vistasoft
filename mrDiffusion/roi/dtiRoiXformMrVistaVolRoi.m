function dtiRoiXformMrVistaVolRoi(dt6file,roiList,vAnatomy,saveDir,outType)
% 
% dtiRoiXformMrVistaVolRoi(dt6file,{roiList},[vAnatomy],[savedroisDir],[outType])
%  
% This function transforms specified ROIs defined on the mrVista volume to
% mrDiffusion and saves them.
%
% If there is no mrVista transform computed and saved to the dt6, a
% transform is computed from the volume Anatomy file (.dat or .nii.gz).
% Otherwise, the vAnatomy is optional.
% 
%
% INPUTS: 
%     DT6FILE: dt6.mat file name
%     ROILIST: file names of ROIs to transform in a CELL ARRAY!
%              MultiSelect=on
%    VANATOMY: vAnatomy file name (optional if xform already exists)
%     SAVEDIR: location to save transformed ROIs  
%     OUTTYPE: File type to save as  
%
% EXAMPLE USAGE:
%    dtiRoiXformMrVistaVolRoi('dt6.mat',{'roi.mat'},'vAnatomy.dat')
% 
% 
%  (C) Stanford University, VISTA Lab, 2012
% 


%% Check inputs

% Check for and load dt6 file
if notDefined('dt6file') ||  ~exist(dt6file,'file') 
    dt6file = mrvSelectFile('r','*.mat','Select dt6 file',pwd);
end


% If a list is not passed in, prompt the user to select ROI(s)
if notDefined('roiList')
    [f,p] = uigetfile({'*.mat','ROI files (*.mat)'; '*.*','All Files (*.*)'},'Select Volume ROI file(s) for this subject','MultiSelect','on');
    if(isnumeric(f)), error('user canceled.'); end
    if iscell(f)
        for ii=1:numel(f)
            roiList{ii} = fullfile(p,f{ii});
        end
    else
        roiList{1} = fullfile(p,f);
    end
end


% File type
if notDefined('outType')
    outType = questdlg('Which output File Type?','File Type','mat','nifti','mat');
end


% Load the dt6
dt6 = dtiLoadDt6(dt6file);


%% Compute the Xform - if it does not exist already

   % Check for dt6 XFORMVANATTOACPC field: this is a 4x4 matrix. If this
   % field does not exist, check for vAnatomy and compute the xform.
if  ~isfield(dt6,'xformVAnatToAcpc') || isempty(dt6.xformVAnatToAcpc)
    
    if  notDefined('vAnatomy')
        [f,p] = uigetfile({'*.dat','vAnatomy files (*.dat)';'*.nii.gz','Nifti Files (*.nii.gz)'; '*.*','All Files (*.*)'},'Select vAnatomy file for this subject');
        if(isnumeric(f)), error('user canceled.'); end
        vAnatomy = fullfile(p,f);
    end
    
    disp('Computing mrVista Xform');
    
    % compute the xform
    if strcmp(vAnatomy(end-6:end),'.nii.gz') 
        vAnatomy         = niftiRead(vAnatomy);
        xformVAnatToAcpc = vAnatomy.qto_xyz;
        
    else
        % Get VAnatomy
        [vAnatomyData,vAnatMm] = readVolAnat(vAnatomy);
        
        % Get t1.nii.gz info
        subjDir      = fileparts(fileparts(dt6file));
        ni           = niftiRead(fullfile(subjDir,dt6.files.t1));
        dtiAcpcXform = ni.qto_xyz;
        dtiT1        = double(ni.data);
        
        % Compute xform
        xformVAnatToAcpc = dtiXformVanatCompute(dtiT1, dtiAcpcXform, vAnatomyData, vAnatMm);
    end
    
    % Save xform to dt6 struct
    save(dt6file,'xformVAnatToAcpc','-APPEND');
    
    % Add xform field to current dt6 variable
    dt6.xformVAnatToAcpc = xformVAnatToAcpc;
    
else
    disp('mrVista XFORM found -- no need to compute new xform')
end


%% Load ROIs, transform the coordinates, and save the ROIs

for ii=1:length(roiList)
    
    if ~exist(roiList{ii},'file')
    
        fprintf('\nROI %s does not exist, skipping\n',roiList{ii});
    
    else
        roi2xform = load(roiList{ii});
        coords    = mrAnatXformCoords(dt6.xformVAnatToAcpc, roi2xform.ROI.coords);
        roi       = dtiNewRoi(roi2xform.ROI.name, roi2xform.ROI.color, coords);
        
        % If SAVEDIR not specified in input arguments
        if (~exist('saveDir','var')||isempty(saveDir))
            saveDir = fullfile(fileparts(dt6file),'ROIs');
        end
        
        % Make the SAVEDIR if it doesn't exist
        if (~isdir(saveDir)), makedir(saveDir); end
        
        switch outType
            case {'nifti', 'nii'}
               dtiRoiNiftiFromMat(roi,dt6.files.t1,fullfile(saveDir,roi.name),1)
            
            case {'mat'}

            % Save the ROI in the way dtiFiberUI likes
            dtiWriteRoi(roi,[fullfile(saveDir,roi.name) '.mat']);
        end
        
        [~, croi] = fileparts(roiList{ii});
        fprintf('Saved %s to %s.\n', croi, saveDir);
    end
end


return

