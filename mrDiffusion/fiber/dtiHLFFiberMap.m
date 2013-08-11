%% Load quantitative maps
% hlf_am=niftiRead('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/amlin_2mms1/HLF_F.nii.gz');
% T1_am=niftiRead('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/amlin_2mms1/T1_LFit_F.nii.gz');
% hWf_am=niftiRead('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/amlin_2mms1/T1fh_F.nii.gz');
% PD_am=niftiRead('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/amlin_2mms1/PDcorected_F.nii.gz');
% %load dt6
dt=dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt/dt6')
% %load white matter mask
% mask_am=niftiRead('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/am1_5lin_2mms/T1_class2mm.nii.gz');

path='/biac3/wandell5/data/relaxometry/100405HLF3T/anal/am1_5lin_2mms/';

hlf_am=niftiRead([path 'HLF_F.nii.gz']);
T1_am=niftiRead([path 'T1_LFit_F.nii.gz']);
hWf_am=niftiRead([path 'T1fh_F.nii.gz']);
PD_am=niftiRead([path 'Wf_F.nii.gz']);
mask_am=niftiRead([path 'T1_class2mm.nii.gz']);

%% Resample to dti resolution
maskR= mrAnatResliceSpm(double(mask_am.data),inv(mask_am.qto_xyz),dt.bb,dt.mmPerVoxel,1);
mask=find(maskR==3 | maskR==4);
mask1=find(mask_am.data==3 | mask_am.data==4);
%make fa map
faIm=dtiComputeFA(dt.dt6);
%compute means andsd's for each measure within white matter mask
fa_std=std(faIm(mask(~isnan(faIm(mask)))))
hlf_std=std(hlf_am.data(mask1(~isnan(hlf_am.data(mask1)))))
pd_std=std(PD_am.data(mask1(~isnan(PD_am.data(mask1)))))
t1_std=std(T1_am.data(mask1(~isnan(T1_am.data(mask1)))))
hwf_std=std(hWf_am.data(mask1(~isnan(hWf_am.data(mask1)))))
fa_mean=mean(faIm(mask(~isnan(faIm(mask)))))
hlf_mean=mean(hlf_am.data(mask1(~isnan(hlf_am.data(mask1)))))
pd_mean=mean(PD_am.data(mask1(~isnan(PD_am.data(mask1)))))
t1_mean=mean(T1_am.data(mask1(~isnan(T1_am.data(mask1)))))
hwf_mean=mean(hWf_am.data(mask1(~isnan(hWf_am.data(mask1)))))
%load morigroups and rois
%fg will contain all mori groups
fg=dtiReadFibers('/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt/fibers/MoriGroups')
roiDir='/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt/ROIs';
fgName(3)={'Left Cortico-Spinal'};
roi1{3}=dtiReadRoi(fullfile(roiDir,'CST_roi1_L'));
roi2{3}=dtiReadRoi(fullfile(roiDir,'CST_roi2_L'));
%we are going to shift this 'ROI 20 mm superior to capture region of
%crossing fibers
roi2{3}=dtiRoiMakePlane([-60,50,round(mean(roi2{3}.coords(:,3)))+20; 0,-60,round(mean(roi2{3}.coords(:,3)))+20], 'CST_roi2__L', 'c');
fgName(4)={'Right Cortico-Spinal'};
roi1{4}=dtiReadRoi(fullfile(roiDir,'CST_roi1_R'));
roi2{4}=dtiReadRoi(fullfile(roiDir,'CST_roi2_R'));
%we are going to shift this 'ROI 20 mm superior to capture region of
%crossing fibers
roi2{4}=dtiRoiMakePlane([-60,50,round(mean(roi2{4}.coords(:,3)))+20; 0,-60,round(mean(roi2{4}.coords(:,3)))+20], 'CST_roi2_R', 'c');
fgName(11)={'Left Inferior Fronto-Occ'};
roi1{11}=dtiReadRoi(fullfile(roiDir,'IFO_roi1_L'));
roi2{11}=dtiReadRoi(fullfile(roiDir,'IFO_roi2_L'));
fgName(12)={'Right Inferior Frontal-Occ'};
roi1{12}=dtiReadRoi(fullfile(roiDir,'IFO_roi1_R'));
roi2{12}=dtiReadRoi(fullfile(roiDir,'IFO_roi2_R'));
fgName(13)={'Left Inferior Longitude'};
roi1{13}=dtiReadRoi(fullfile(roiDir,'ILF_roi1_L'));
roi2{13}=dtiReadRoi(fullfile(roiDir,'ILF_roi2_L'));
fgName(14)={'Right Inferior Longitude'};
roi1{14}=dtiReadRoi(fullfile(roiDir,'ILF_roi1_R'));
roi2{14}=dtiReadRoi(fullfile(roiDir,'ILF_roi2_R'))
fgName(19)={'Left Arcuate'};
roi1{19}=dtiReadRoi(fullfile(roiDir,'SLF_roi1_L'));
roi2{19}=dtiReadRoi(fullfile(roiDir,'SLFt_roi2_L'));
fgName(20)={'Right Arcuate'};
roi1{20}=dtiReadRoi(fullfile(roiDir,'SLF_roi1_R'));
roi2{20}=dtiReadRoi(fullfile(roiDir,'SLFt_roi2_R'));
%compute properties on tract trajectory for the specific fiber goups of
%interest
groups=[3  11  13  19 4 12 14 20]
for ii=groups;
    %compute fa and md along the trajectory of the fiber group as a
    %weighted average of fa and md at each fiber
    [fa md]=dtiComputeDiffusionPropertiesAlongFG(fg(ii), dt, roi1{ii}, roi2{ii}, 30);
    %clip fiber group between 2 rois to obtain core segment
    fgClipped = dtiClipFiberGroupToROIs(fg(ii),roi1{ii},roi2{ii});
    %compute quantitative measures along trajectory of fiber group
    [hlf, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, hlf_am, 30,'image');
    [pd, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, PD_am, 30,'image');
    [t1, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, T1_am, 30,'image');
    [hwf, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, hWf_am, 30,'image');
    %Standardize measures based on variance within white matter mask
    faZ=((fa-fa_mean)./fa_std);
    hlfZ=(hlf-hlf_mean)./hlf_std;
    hwfZ=(hwf-hwf_mean)./hwf_std;
    t1Z=(t1-t1_mean)./t1_std;
    pdZ=(pd-pd_mean)./pd_std;
    %Make plot for fiber group ii
    subplot(2,4,find(groups==ii));plot(horzcat(faZ,hlfZ,hwfZ,t1Z,pdZ),'LineWidth',2);axis([0 30 -2 2]);title(fgName{ii})
    if find(groups==ii)==1 | find(groups==ii)==5
        legend('fa', 'hlf', 'hwf', 't1', 'pd'); ylabel('Z Score');
    end

end


