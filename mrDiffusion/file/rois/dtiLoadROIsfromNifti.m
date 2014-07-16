function dtiLoadROIsfromNifti(hObject,handles)
%
% dtiLoadROIsfromNifti(hObject,handles)
%
% Author: DY
% Purpose: Allows you to turn a nifti file into an ROI viewable in
% mrDiffusion.
%
% The new ROI is in individual (same as dt6) space, and assumes that you
% have created the ROI on the same t1.nii.gz that you aligned the raw DTI
% data to in dtiRawPreprocess. For example, maybe you want to segment a
% particular anatomical structure in ITKGray. You would load 
%
% GUI stuff is hacked from dtiLoadManyRois.
% The code that translates the nii.gz is mostly borrowed from findMoriTracts.m 
% and dtiCreateRoiFromMniNifti.m. NIFTI image is treated as a mask (all the
% nonzero voxels will make it to the ROI). 
%
% DY 06/11/2008
% DY 06/18/2008: modified so it will (hopefully) load differently labeled
% volumes as distinct ROIs. We find all unique non-zero numbers in the
% data, and turn all voxels indexed by one number into the mask for one
% ROI, and voxels indexed by a different number into a different ROI. This
% will load but not save the ROIs. 
%
% TODO 06/18/2008: ROIs in correct coordinates! Use lines 37-40 from
% dtiCreateRoiFromMniNifti? But error using mrAnatRespliceSpm... 

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

d = dir(fullfile(p,'*.nii*')); % Changed this from .mat

if(isempty(d))
    error('No ROIs found');
    return;
end

for ii=1:length(d)
    str = char(d(ii).name);
    [path, str, ext] = fileparts(str); 
    fileList{ii} = str;
    extList{ii}=ext; 
end

[s,ok] = listdlg('PromptString','Select an ROI',...
    'SelectionMode','multiple',...
    'ListString',fileList, 'ListSize', [300 300]);

if ok
    for ii=1:length(s)
        % From dtiCreateRoiFromMniNifti, but without any of the stuff that
        % translates to/from MNI space.
        roiNii = niftiRead(fullfile(p, [char(fileList{s(ii)}) extList{s(ii)}]));
        % Find all unique, non-zero indices, each distinct index will be a
        % mask for a distinct ROI
        roisToMake=unique(roiNii.data);
        roisToMake=roisToMake(roisToMake~=0);
        
        % For each distinct index, create a distinct ROI
        for jj=1:length(roisToMake)
            thisRoi = find(roiNii.data==roisToMake(jj));
            [x1,y1,z1] = ind2sub(size(roiNii.data), thisRoi);
            roiMask = dtiNewRoi([char(fileList(s(ii))) '_' num2str(roisToMake(jj))], rand(1, 3));
            roiMask.coords = mrAnatXformCoords(roiNii.qto_xyz, [x1,y1,z1]);

            % Back to original code from dtiLoadManyRois
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
