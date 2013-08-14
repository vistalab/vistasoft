function dtiLoadROIsfromMniNifti(hObject,handles)
%
% dtiLoadROIsfromMniNifti(hObject,handles)
%
% Allows you to turn a nifti file which is known to be in MNI
% space into an ROI viewable in mrDiffusion. You want this image to have
% only a few discrete integer values (e.g., a mask of ones, or of 1, 2,
% 3...N if want to load N rois).
%
% The code is based on dtiLoadROIsfromNifti(hObject,handles) which assumes
% that the NIFTI ROI was created in the on the same t1.nii.gz that you
% aligned the raw DTI data to in dtiRawPreprocess. Current function,
% however, adds a step of computing bo-to-MNI_EPI alignment. This
% transformation is applied to the loaded NIFTI so that it is now in dt6
% space.
%
% The intended use is, for example, if you have atlas-based ROIs (usually in
% MNI space) of a particular, say, anatomical structure, and you want to
% grow fibers from "that structure".
%
% GUI stuff is hacked from dtiLoadManyRois.
% The code that translates the nii.gz is mostly borrowed from findMoriTracts.m
% and dtiCreateRoiFromMniNifti.m. NIFTI image is treated as a mask (all the
% nonzero voxels will make it to the ROI).
%
% Based on dtiLoadROIsfromNifti, this function will (hopefully) load
% differently labeled volumes as distinct ROIs. We find all unique non-zero
% numbers in the data, and turn all voxels indexed by one number into the
% mask for one ROI, and voxels indexed by a different number into a
% different ROI. This will load but not save the ROIs.
%
% TODO: What if the image is not a mask? Too many unique values to deal
% with.
%
% Author: ER 07/21/2008

% From dtiLoadManyRois.m
persistent defaultPath;
if(isempty(defaultPath))
    fn = handles.defaultPath;
    if(exist(fullfile(fn, 'ROIs'),'dir')) fn = fullfile(fn, 'ROIs', filesep); end
else
    fn = defaultPath;
end
p = uigetdir(fn, 'ROI directory');
if isnumeric(p), disp('Load ROIs ... canceled.'), return; end

d = dir(fullfile(p,'*.nii.gz')); % Changed this from .mat

if(isempty(d))
    error('No ROIs found');
    return;
end

for ii=1:length(d)
    str = char(d(ii).name);
    str = str(1:findstr(str,'.nii.gz')-1); % Changed this from .mat
    fileList{ii} = str;
end

[s,ok] = listdlg('PromptString','Select an ROI',...
    'SelectionMode','multiple',...
    'ListString',fileList, 'ListSize', [300 300]);

if ok
    
    %Figure out MNI<->dt6 normalization
    [b0, mmPerVoxel, xformToAcpc, valRange] = dtiGetNamedImage(handles.bg, 'b0');
    % Spatially normalize it with the MNI (ICBM) template
    tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
    template = fullfile(tdir,'MNI_EPI.nii.gz');
    [sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(b0, xformToAcpc, template);
    
    % check the normalization
    mm = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
    bb = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim(1:3)]);
    b0 = mrAnatHistogramClip(double(b0),0.3,0.99);
    b0_sn = mrAnatResliceSpm(b0, sn, bb, mm, [1 1 1 0 0 0], 0);
    tedge = bwperim(Vtemplate.dat>50&Vtemplate.dat<170);
    im = uint8(round(b0_sn*255));
    im(tedge) = 255;
    showMontage(im);
    
    for ii=1:length(s)
        %         % From dtiCreateRoiFromMniNifti, but without any of the stuff that
        %         % translates to/from MNI space.
        roiNii = niftiRead(fullfile(p, [char(fileList(s(ii))),'.nii.gz']));
        %         % Find all unique, non-zero indices, each distinct index will be a
        %         % mask for a distinct ROI
        roisToMake=unique(roiNii.data);
        roisToMake=roisToMake(find(roisToMake~=0));
        %
        % If you wanted to inverse-normalize the maps to this subject's brain:
        invDef.outMat = roiNii.qto_ijk;
        bb = mrAnatXformCoords(xformToAcpc,[1 1 1; size(b0)]);
        ROIdata = mrAnatResliceSpm(roiNii.data, invDef, bb, mmPerVoxel, [1 1 1 0 0 0]);
        ROIdata(isnan(ROIdata))=0;
        
        
        %         % For each distinct index, create a distinct ROI
        for jj=1:length(roisToMake)
            thisRoi = find(ROIdata==roisToMake(jj));
            [x1,y1,z1] = ind2sub(size(ROIdata), thisRoi);
            roiMask = dtiNewRoi([char(fileList(s(ii))) '_' num2str(roisToMake(jj))]);
            roiMask.coords = mrAnatXformCoords(xformToAcpc, [x1,y1,z1]);
            %
            %             % Back to original code from dtiLoadManyRois
            handles = dtiAddROI(roiMask,handles);
            clear x1 y1 z1 roiMask;
        end
        
        
        
    end
    handles = dtiRefreshFigure(handles, 0);
    guidata(hObject, handles);
else
    disp('Load ROIs ... canceled.');
end

return;
