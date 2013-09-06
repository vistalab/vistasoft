dtDirs = {'/biac3/wandell4/data/reading_longitude/dti_adults/ak090724/dti40trilin/'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt/'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/rfd080930/dti06trilinrt/'};

BPFDirs = {'/biac3/wandell5/data/relaxometry/ak090721/trilin_ak_2mms'...
    '/biac3/wandell5/data/relaxometry/am_090126/trilin2mml'...
    '/biac3/wandell5/data/relaxometry/rb_090716/trilin_rb_2mms'};

sub={'ak' 'am' 'rfd'}

for j=1:1%2 %1.5T or 3T anatomy
    for i=2:2%length(sub),
        name3T=sub{i};
        name15T=[sub{i} '1_5'];
        path3=['/biac3/wandell5/data/relaxometry/100405HLF3T/anal/' name3T 'lin_2mms1/'];
        path15=['/biac3/wandell5/data/relaxometry/100405HLF3T/anal/' name15T 'lin_2mms'];%Nbs1

        if j==1,
            path=path15;
        elseif j==2
            path=path3;
        end;
        %%% load maps  %%%
        hlf=niftiRead([path '/HLF_F.nii.gz']);
        t1=niftiRead([path '/T1_LFit_F.nii.gz']);
        T1hWf=niftiRead([path '/T1fh_F.nii.gz']);
        wf=niftiRead([path '/Wf_F.nii.gz']);
        dt = dtiLoadDt6(fullfile(dtDirs{i},'dt6'));
        bpf=niftiRead(fullfile(BPFDirs{i},'f.nii.gz'));
       Class=niftiRead([path15 '/T1_class2mm.nii.gz']);
       
%        t1=t1.data;
%        hlf=hlf.data;
%        wf=wf.data;
%        T1hWf=T1hWf.data;
%        bpf=bpf.data;
%        
      [eigVec,eigVal] = dtiEig(dt.dt6);
    [fa,md,rd] = dtiComputeFA(eigVal);
    [cl, cp, cs] = dtiComputeWestinShapes(eigVal);

%       we will make wm masks for the maps

maskAnat=find(Class.data==3 | Class.data==4);

if(~all(dt.xformToAcpc(:)==Class.qto_xyz(:)))
    maskR= mrAnatResliceSpm(double(Class.data),inv(Class.qto_xyz),dt.bb,dt.mmPerVoxel,1);
    maskDif=find(maskR==3 | maskR==4);
    clear maskR;

else
    maskDif=maskAnat;
end;

%compute means andsd's for each measure within white matter mask
fa_std=std(fa(maskDif(~isnan(fa(maskDif)))));
rd_std=std(rd(maskDif(~isnan(rd(maskDif)))));
md_std=std(md(maskDif(~isnan(md(maskDif)))));
cl_std=std(cl(maskDif(~isnan(cl(maskDif)))));

hlf_std=std(hlf.data(maskAnat(~isnan(hlf.data(maskAnat)))));
wf_std=std(wf.data(maskAnat(~isnan(wf.data(maskAnat)))));
t1_std=std(t1.data(maskAnat(~isnan(t1.data(maskAnat)))));
T1hWf_std=std(T1hWf.data(maskAnat(~isnan(T1hWf.data(maskAnat)))));
bpf_std=std(bpf.data(maskAnat(~isnan(bpf.data(maskAnat)))));

fa_mean=mean(fa(maskDif(~isnan(fa(maskDif)))));
rd_mean=mean(rd(maskDif(~isnan(rd(maskDif)))));
md_mean=mean(md(maskDif(~isnan(md(maskDif)))));
cl_mean=mean(fa(maskDif(~isnan(cl(maskDif)))));


hlf_mean=mean(hlf.data(maskAnat(~isnan(hlf.data(maskAnat)))));
wf_mean=mean(wf.data(maskAnat(~isnan(wf.data(maskAnat)))));
t1_mean=mean(t1.data(maskAnat(~isnan(t1.data(maskAnat)))));
T1hWf_mean=mean(T1hWf.data(maskAnat(~isnan(T1hWf.data(maskAnat)))));
bpf_mean=mean(bpf.data(maskAnat(~isnan(bpf.data(maskAnat)))));





%load morigroups and rois
%fg will contain all mori groups
fbDir=[dtDirs{i} 'fibers/MoriGroups'];

fg=dtiReadFibers(fbDir)

roiDir=[dtDirs{i} 'ROIs'];

fgName(3)={'Left Cortico-Spinal'};
roi1{3}=dtiReadRoi(fullfile(roiDir,'CST_roi1_L'));
roi2{3}=dtiReadRoi(fullfile(roiDir,'CST_roi2_L'));
fgName(4)={'Right Cortico-Spinal'};
roi1{4}=dtiReadRoi(fullfile(roiDir,'CST_roi1_R'));
roi2{4}=dtiReadRoi(fullfile(roiDir,'CST_roi2_R'));
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

groups=[3  11  13  19 4 12 14 20];
for ii=groups;
    %compute fa and md along the trajectory of the fiber group as a
    %weighted average of fa and md at each fiber
    [fa_ md_ rd_ d cl_]=dtiComputeDiffusionPropertiesAlongFG(fg(ii), dt, roi1{ii}, roi2{ii}, 30);
    %clip fiber group between 2 rois to obtain core segment
    fgClipped = dtiClipFiberGroupToROIs(fg(ii),roi1{ii},roi2{ii});
    %compute quantitative measures along trajectory of fiber group
    [hlf_, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, hlf, 30,'image');
    [wf_, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, wf, 30,'image');
    [t1_, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, t1, 30,'image');
    [T1hWf_, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, T1hWf, 30,'image');
    [bpf_, SuperFiber, weightsNormalized] =dtiFiberGroupPropertyWeightedAverage(fgClipped, bpf, 30,'image');
    

   
    %Standardize measures based on variance within white matter mask
    faZ=((fa_-fa_mean)./fa_std);
    rdZ=((rd_-rd_mean)./rd_std);
    mdZ=((md_-md_mean)./md_std);
    clZ=((cl_-cl_mean)./cl_std);


    hlfZ=(hlf_-hlf_mean)./hlf_std;
    T1hWfZ=(T1hWf_-T1hWf_mean)./T1hWf_std;
    t1Z=(t1_-t1_mean)./t1_std;
    wfZ=(wf_-wf_mean)./wf_std;
    bpfZ=(bpf_-bpf_mean)./bpf_std;

    %Make plot for fiber group ii
    figure(ii);
     subplot(2,4,find(groups==ii));
    
       subplot(2,1,1);
   plot(horzcat(faZ,rdZ,mdZ,clZ),'LineWidth',2);axis([0 30 -2 2]);title([sub{i} 'Dif' fgName{ii}])
         legend('fa', 'rd', 'md', 'cl');ylabel('Z Score');
   subplot(2,1,2);
    plot(horzcat(hlfZ,T1hWfZ,t1Z,wfZ,bpfZ),'LineWidth',2);axis([0 30 -2 2]);title([sub{i} 'Anat' fgName{ii}])
   %if find(groups==ii)==1 | find(groups==ii)==5
        legend( 'hlf', 'T1hWf', 't1', 'wf' ,'bpf'); ylabel('Z Score');
   % end

end






    end
    
    
end;
