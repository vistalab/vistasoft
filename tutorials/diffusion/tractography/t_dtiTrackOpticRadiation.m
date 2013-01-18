function t_dtiTrackOpticRadiation(varargin)
% function t_dtiTrackOpticRadiation(varargin)
%
% This function shows how to identify the Optic Radiation (OR)
% using scripting and mrDiffisuion.
%
% It requires freesurfer and vistasoft.
%
% It assumes the biac file structure with the longitudinal dataset.
%
% The following are the analysis steps for each subject:
% (1) load freesurfer optic chiasm ROI
% (2) create a spherical (8mm) ROI around the center coordinates of the optic chiasm (OC).
% (3) trace fibers out of the shere (2) using a deterministic algorith (STT)
% (4) compute the median end-point for the resulting fiber group. --If the
%     tracing was good most of the fibers should end at around the LGN.
% (5) create a left and a right LGN ROI at the cordinates of the median
%     fibers endpoints (4).
% (6) load fressurfer calcarine ROI, expand the ROI and apply some
%     smoothing so to 'expand the ROI, which seem to be small and sometimes
%     missing the actual Calcarine sulcus). Save the left and right
%     calcarine ROIs.
% (7) use contrack to trace between left/right LGN ROIS and left/right Calcarine ROIs
% (8) score the fibers obtained for each ROI.
% (9) Open QUENCH this progrma will be used to prune the fibers manually in
%     eahc subjects.
%
% Example:
% t_dtiOpticRadiation;
%
% Copyright Stanford team, mrVista, 2011
% 
% 2011/08/24 FP

% the name give to this project
projectName = 'opticRadiationDCDC2';



% these is the information regarding the location fo the data for each subject
projectDir = '/biac3/wandell4/data/reading_longitude'; %'/indigo/scr1/data/francesca';
dataYear   = 'dti_y1';
dtiFile    =  'dti06trilinrt/dt6.mat';%'dti06trilin/dt6.mat';

% these are all the subjects we plan to process
% subjects    = {'ab040913','ad040522','mb041004','ada041018','ajs040629', ...
%                'am040925', 'an041018', 'ao041022','ar040522','at040918'};
% get the subjects folders
temp_subjects = dir(fullfile(projectDir,dataYear));
c = 0;
for i = 1:numel(temp_subjects)
 if regexp(temp_subjects(i).name,'\w\w\d\d\d\d\d\d', 'once')
  c = c + 1;
  subjects{c} = temp_subjects(i).name;
 end
end

% number fo fibers to score (contrack)
numPathsToScore = 50000;

% ROI names
maskRoi = 'OR_find_lgn_mask_roi.mat';
lgnAtlasRoi = '/biac3/wandell4/data/reading_longitude/lgn_coords_mni_atlas.mat';


% ------------------------- %
% Start creating the ROI for each subject
% the ROIs will be saved in each subjecs' respective ROI folder.
for iSubj=1 : 10%length(subjects)
 fprintf('\n[%s] creating ROIs for subject: %s\n',mfilename,subjects{iSubj});
 
 % compose the subject's ROI directory.
 roisDir = fullfile(projectDir,dataYear,subjects{iSubj},'ROIs',projectName);
 fibersDir = fullfile(projectDir,dataYear,subjects{iSubj},'fibers',projectName);
 
 % create the ROI and fiber folders if they do not exist yet
 if ~isdir(roisDir), mkdir(roisDir); end
 if ~isdir(fibersDir), mkdir(fibersDir); end
  
 % compose the subject's diffision file.
 dt6File = fullfile(projectDir,dataYear,subjects{iSubj},dtiFile);
  
 % set the freesurfer Optic Chiasm ROI
 chiasmROI.labelVal        = 85;
 % select the freesurfer segmentation file
 chiasmROI.segfile         = fullfile(projectDir,'freesurfer',subjects{iSubj},'mri/aparc_aseg.nii');
 % get the ROI name from the ROI label index
 chiasmROI.label           = fs_getROILabelNameFromLUT(chiasmROI.labelVal);
 % save the freesurfer ROI to a nifti file
 fileName2save = fullfile(roisDir,[chiasmROI.label,'_freesurfer']);
 % remove the file if it already exists
 if exist([fileName2save,'.nii'],'file') || exist([fileName2save,'.nii.gz'],'file')
  eval(sprintf('!rm -v %s',[fileName2save,'.nii*']))
 end
 chiasmROI.roiFreesurfer    = fs_labelToNiftiRoi(chiasmROI.segfile, chiasmROI.labelVal, fileName2save);

 % load the saved ROI into matlab
 chiasmROI.dtiRoiFreesurfer.name = 'optic_chiasm_fresurfer'; 
 % import the freesurfer OC ROI in matlab and save a file
 chiasmROI.dtiRoiFreesurfer      = dtiImportRoiFromNifti(chiasmROI.roiFreesurfer.fname, fileName2save);
 % save the ROI as a mat file
%  dtiWriteRoi(chiasmROI.dtiRoiFreesurfer,fullfile(roisDir, chiasmROI.dtiRoiFreesurfer.name));
 
 % compute the center of the Opti Chiasm ROI
 chiasmROI.centerOfMass    = dtiRoiGetCenterOfMassCoord(chiasmROI.dtiRoiFreesurfer);
 % drop a spherical ROI at that location
 chiasmROI.dtiRoiSphere.name   = 'optic_chiasm_sphere';
 chiasmROI.dtiRoiSphere        = dtiNewRoi(chiasmROI.dtiRoiSphere.name);
 chiasmROI.sphereDiameter      = 6; % mm
 chiasmROI.dtiRoiSphere.coords = dtiBuildSphereCoords(chiasmROI.centerOfMass, chiasmROI.sphereDiameter);
 % save the ROI as a mat file
 dtiWriteRoi(chiasmROI.dtiRoiSphere,fullfile(roisDir, chiasmROI.dtiRoiSphere.name));
 
 % ---------------------------------------------------------------------- %
 if exist(dt6File,'file')
  % load the diffusion file
  dt    = dtiLoadDt6(dt6File);
  
  % ---------------------------------------------------------------------- %
  % Get the LGN ROI Atlas computed as mean MNI coordinates on the subjects
  % in the database
  % ---------------------------------------------------------------------- %
  % load the LGN ROI computed as average MNI coordinates across subjects
  load(lgnAtlasRoi);
  
  % transoformthis subject's dti data into MNI space
  % get the transformation to MNI space
  [sn, def] = dtiComputeDtToMNItransform(dt);
  
  % transform ROI to subjects space (this is a warp).
  coordsSub = mrAnatXformCoords(sn, lgn.left.coords.median);
  
  % transform ROI to ac-pc (this is a linear transformation)
  coordsSubAcPc = mrAnatXformCoords(dt.xformToAcpc, coordsSub);
  
  % open a spherical ROI at the lgn location in subject's coordinates
  lgn.left.dtiRoiSphere.name   = 'lgn_left_sphere_from_atlas';
  lgn.left.dtiRoiSphere        = dtiNewRoi(lgn.left.dtiRoiSphere.name);
  lgn.left.sphereDiameter      = 7; % mm
  lgn.left.dtiRoiSphere.coords = dtiBuildSphereCoords(coordsSubAcPc, lgn.left.sphereDiameter);
  
  % save the ROI as a mat file
  dtiWriteRoi(lgn.left.dtiRoiSphere,fullfile(roisDir, lgn.left.dtiRoiSphere.name));
  
  % transform ROI to subjects space (this is a warp).
  coordsSub = mrAnatXformCoords(sn, lgn.right.coords.median);
  
  % transform ROI to ac-pc (this is a linear transformation)
  coordsSubAcPc = mrAnatXformCoords(dt.xformToAcpc, coordsSub);
  
  % open a spherical ROI at the lgn location in subject's coordinates
  lgn.right.dtiRoiSphere.name   = 'lgn_right_sphere_from_atlas';
  lgn.right.dtiRoiSphere        = dtiNewRoi(lgn.right.dtiRoiSphere.name);
  lgn.right.sphereDiameter      = 7; % mm
  lgn.right.dtiRoiSphere.coords = dtiBuildSphereCoords(coordsSubAcPc, lgn.right.sphereDiameter);
  
  % save the ROI as a mat file
  dtiWriteRoi(lgn.right.dtiRoiSphere,fullfile(roisDir, lgn.right.dtiRoiSphere.name));
  

  %FPF
  % --------------------------------------------------------------------------------- %
  % ---- track everywhere in the brain using a deterministic algorithm
  % --------------------------------------------------------------------------------- %
  % -- the seeds are the coordinates fo the spherical ROI
  %    created on top of the center of the optic chiasm
  fiberGroup.seeds  = chiasmROI.dtiRoiSphere.coords;
  fiberGroup.name   = 'whole_brain_fibers';%'optic_chiasm_all_fibers';
  
  % create a group of fibers by tracing from the seeds (the coordinates of the OC ROI)
  fiberGroup.voxelSize = dt.mmPerVoxel;      % get te voxel size for this dataset
  fiberGroup.xform     = dt.xformToAcpc;     % get the AC-PC trasformation
  fiberGroup.options   = dtiFiberTrackOpts; % get default tracign options
  fiberGroup.options.seedVoxelOffsets = .5;
  fiberGroup.options.offsetJitter     = [.75];
  
  % track the fibers 
  
  fiberGroup = dtiFiberTrackWholeBrain(dt6File, fiberGroup.options, fiberGroup.name, 'both','mat',1);
%   fiberGroup  = dtiFiberTrack(dt.dt6, fiberGroup.seeds,     ...
%   fiberGroup.voxelSize, ...
%   fiberGroup.xform,     ...
%   fiberGroup.name,      ...
%   fiberGroup.options);
  
 % save the fibers
  dtiWriteFiberGroup(fiberGroup,fullfile(fibersDir,fiberGroup.name));
  
%   % orient the slices front-to-back
%   for ifib = 1:length(fiberGroup.fibers)
%    % orient all the fibers so that they are going anterior-2-posterior
%    if fiberGroup.fibers{ifib}(1,2) > fiberGroup.fibers{ifib}(end,2)
%     fiberGroup.fibers{ifib} = flipud(fiberGroup.fibers{ifib});
%    end
%   end
  
  % Split fibers into left and right hemisphere:
%   maxZ = -15;
%   [temp, fgRemains, fgLeft, fgRight] = dtiSplitInterhemisphericFibers(fiberGroup, dt, maxZ);
%   
%   dtiWriteFiberGroup(fgLeft,fullfile(fibersDir,fgLeft.name));
%   dtiWriteFiberGroup(fgRight,fullfile(fibersDir,fgRight.name));
  
  % ---------------------------------------------------------------------- %
  % INCLUDE only the fibers that intersect with the LGN rois:
%   [fgLeftAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[],lgn.left.dtiRoiSphere, fgLeft);
%   [fgRightAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[],lgn.right.dtiRoiSphere, fgRight);
%[fgLeftAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[],lgn.left.dtiRoiSphere, fiberGroup);
%[fgRightAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[],lgn.right.dtiRoiSphere, fiberGroup);
[fgOpticChiasm,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[], chiasmROI.dtiRoiSphere,fiberGroup);
[fgLeftAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[], lgn.left.dtiRoiSphere,fgOpticChiasm);
[fgRightAtLgn,contentiousFibers, keep] = dtiIntersectFibersWithRoi([], {'AND'},[], lgn.right.dtiRoiSphere,fgOpticChiasm);

  dtiWriteFiberGroup(fgLeftAtLgn,fullfile(fibersDir,fgLeftAtLgn.name));
  dtiWriteFiberGroup(fgRightAtLgn,fullfile(fibersDir,fgRightAtLgn.name));
  
 % keyboard
  
  if numel(fgLeftAtLgn.fibers) > 1 && numel(fgRightAtLgn.fibers) > 1
   % take the median location fo the left/right fiber coordinates that is a
   % good guess for the location of the LGN
   for i = 1:numel(fgLeftAtLgn.fibers)
    lgnROI.left.coords(1:3,i)  =  (fgLeftAtLgn.fibers{i}(:,end)); % this is wrong
   end
   lgnROI.left.medianCoords = median(lgnROI.left.coords,2);
   
   for i = 1:numel(fgRightAtLgn)
    lgnROI.right.coords(1:3,i) = (fgRightAtLgn.fibers{i}(:,end)); % this is wrong
   end
   lgnROI.right.medianCoords = median(lgnROI.right.coords,2);
   
   % make a spherical ROI at the Left/Right LGN locations
   lgnROI.left.dtiRoi.name         = 'lgn_left_sphere';
   lgnROI.left.dtiRoiSphere        = dtiNewRoi(lgnROI.left.dtiRoi.name);
   lgnROI.left.sphereDiameter      = 8; % mm
   lgnROI.left.dtiRoiSphere.coords = dtiBuildSphereCoords(lgnROI.left.medianCoords, lgnROI.left.sphereDiameter);
   % save the ROI as a mat file
   dtiWriteRoi(lgnROI.left.dtiRoiSphere,fullfile(roisDir, lgnROI.left.dtiRoiSphere.name));
   
   % make a spherical ROI at the Left/Right LGN locations
   lgnROI.right.dtiRoi.name         = 'lgn_right_sphere';
   lgnROI.right.dtiRoiSphere        = dtiNewRoi(lgnROI.right.dtiRoi.name);
   lgnROI.right.sphereDiameter      = 8; % mm
   lgnROI.right.dtiRoiSphere.coords = dtiBuildSphereCoords(lgnROI.right.medianCoords, lgnROI.right.sphereDiameter);
   % save the ROI as a mat file
   dtiWriteRoi(lgnROI.right.dtiRoiSphere, fullfile(roisDir, lgnROI.right.dtiRoiSphere.name));
   
   % set the freesurfer ROI information.
   % left-calcarine ROI freesurfer name and code
   calROI.left.dtiRoi.name   = 'calcarine_left_freesurfer';
   calROI.left.labelVal      = 1021;
   % select the freesurfer segmentation file
   calROI.left.segfile       = fullfile(projectDir,'freesurfer',subjects{iSubj},'mri/aparc_aseg.nii');
   
   % get the ROI name from the ROI label index
   calROI.left.label         = fs_getROILabelNameFromLUT(calROI.left.labelVal);
   
   fileName2save = fullfile(roisDir,[calROI.left.label]);
   % remove the file if it already exists
   if  exist([fileName2save,'.nii'],'file') || exist([fileName2save,'.nii.gz'],'file')
    eval(sprintf('!rm -v %s',[fileName2save,'.nii*']))
   end
   
   % save the freesurfer ROI to a nifti file
   calROI.left.roiFreesurfer           = fs_labelToNiftiRoi(calROI.left.segfile, calROI.left.labelVal, fileName2save);
  
   % load the saved ROI into matlab and save it
   calROI.left.dtiRoiFreesurfer        = dtiImportRoiFromNifti(fileName2save,fullfile(roisDir, calROI.left.dtiRoi.name));
   % save the ROI as a mat file
%    dtiWriteRoi(calROI.left.dtiRoiFreesurfer,fullfile(roisDir, calROI.left.dtiRoiFreesurfer.name));
   
   % right-calcarine ROI freesurfer name and code
   calROI.right.dtiRoi.name  = 'calcarine_right_freesurfer';
   calROI.right.labelVal     = 2021;
   % select the freesurfer segmentation file
   calROI.right.segfile      = fullfile(projectDir,'freesurfer',subjects{iSubj},'mri/aparc_aseg.nii');
   
   % get the ROI name from the ROI label index
   calROI.right.label        = fs_getROILabelNameFromLUT(calROI.right.labelVal);
   
   fileName2save = fullfile(roisDir,[calROI.right.label]);
   % remove the file if it already exists
   if  exist([fileName2save,'.nii'],'file') || exist([fileName2save,'.nii.gz'],'file')
    eval(sprintf('!rm -v %s',[fileName2save,'.nii*']))
   end
   
   % save the freesurfer ROI to a nifti file
   calROI.right.roiFreesurfer          = fs_labelToNiftiRoi(calROI.right.segfile, calROI.right.labelVal, fileName2save);
   
   % load the saved ROI into matlab and save it
   calROI.right.dtiRoiFreesurfer        = dtiImportRoiFromNifti(fileName2save, fullfile(roisDir,calROI.right.dtiRoi.name));
   % save the ROI as a mat file
%    dtiWriteRoi( calROI.right.dtiRoiFreesurfer,fullfile(roisDir, calROI.right.dtiRoiFreesurfer.name));
   
  else
   fprintf('\n[%s] Could trace fibers between the chiasm and the LGn for subject <%s>, skipping this subject...\n',mfilename, subjects{iSubj})
  end
 else
  fprintf('\n[%s] Could not fine the DT6 file for subject <%s>, skipping this subject...\n',mfilename, subjects{iSubj})
 end
end
keyboard

%% ConTrack
% these next lines will run after all the rois for all the subjects have
% been created and saved

% Initialize the ctrBatch structure with ctrInitBatchParams
ctrParams = ctrInitBatchParams;
ctrParams.projectName = 'optic_raditation_dcdc2'; % e.g. optic radiation inside the base directory                                   
ctrParams.logName     = 'optic_raditation_dcdc2_test'; % 
ctrParams.baseDir     = projectDir;                      
ctrParams.dtDir       = dtiFile;
ctrParams.roiDir      = 'BOOOOM';
ctrParams.nSamples    = 10000;

ctrParams.subs = subjects;
ctrParams.roi1 = {'lgn_left_sphere','lgn_right_sphere'};    
ctrParams.roi2 = {'calcarine_left_freesurfer', 'calcarine_right_freesurfer'};

[shellCmd logFile]  = ctrInitBatch(ctrParams);

% does tracking
unix(shellCmd);

% score fibers
scoreCmd = ctrBatchScore(logFile);

% does scoring
unix(scoreCmd);

% done!
return




