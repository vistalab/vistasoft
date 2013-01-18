function [PDc CoilG]=hlfBiasGridFit(t1,pd,xform,outDir)
% Grid fit for B1 bias correction
%
%   [PDc CoilG] = hlfBiasGridFit(t1,pd,xform,outDir)
%
% first i will try to get a clean area according to the procedure
% Noterdaeme O. Anderson M. Gleeson F Brady M. (2009) 'Intensity correction
% with a pair of spoiled gradient recalled echo images' Phys. Med. Biol.
% Vol 54 PP. 3473–3489
%
%   not like the article i'm not work on all brain but only on the WM. also
%   i will use step 1-8 only to define the ROI but the data that is used
%   for the gridfit are the data in the original gPDT2* and  not the smooth
%   data.

%% Check input arguments here


%% Algorithm begins 
%  Exclude voxels that: T1<0 (.2) T1>5000 (1000) ms
%  Exclude voxels that PD_0<0 PD_0 -the pd that come from t1 fit.
%  Exclude any voxel that is less then 5% from the mean
%
%    bm = dt.brainMask &  t1<2.0 & t1>0.3 & pd>mean(pd(:))*.05  &t1<1;
bm =  t1>0.3 & pd>mean(pd(:))*.05  &t1<1;

%% Reject from the ROI the isolate voxel after excluding presiders (1-3)
isolet = bwdist(bm);
bm     = bm & isolet<=1;
pd1    = zeros(size(pd));
pd1(bm)= pd(bm);

%% Small kernel median filter (radius 5)
[pd1] = ordfilt3D(pd1,5);

%% Large area which are differ significantly from the mean are scaled up
% or down. (i'm not scalling just exclude them from the mask. 

bm1 = find(pd1(:)~=0);

mask = zeros(size(pd1));
mask(bm1) = 1;
mask = mask & (pd1<(mean(pd1(bm1))-std(pd1(bm1))));% | pd1>(mean(pd1(bm1))+std(pd1(bm1))));
w = find(mask);
pd1(w)=0;

%% Normalize the map to run between [0 1]

%pd2(:)=pd2(:)./max(pd2(:)); % no reseson for that ?

% Again clear the isolet voxel
isolet = bwdist(pd1);
bm =  isolet>1;

pd1(bm) = 0;
pd2(find(pd1)) = pd(find(pd1)); %the pd values in the white mater mask


%% Apply the gridFit function (D'Errico) 
% select between 30-40 control point in
% x-y directions in the ROI . on regularly spread grid of control
% points PI.
% i find deside to use 100 contol point but this is abit arbitrary.
% also in teroy when can do the same on the GM ROI and get same kind of
% result
% We should try Brian ND gridfit (ffndgrid?)

PDc   = zeros(size(pd)); %the clean image
CoilG = zeros(size(pd)); %the gain bias image
[XI YI]=meshgrid(1:size(pd2,1),1:size(pd2,2));

for  i=1:size(pd2,3) %go over the slices

    tmp=pd2(:,:,i);
    wh=find(tmp);

    % grid fit is wrong when there aren't enough points, or when they
    % aren't spred in along the slice. the 100 treshold is just a guess.
    % (3D willgridfit help solve this problem)  
    if  length(find(tmp))>100; 
        
        [x,y] = ind2sub(size(tmp),wh);
        z=double(tmp(wh));

        % z,y,z are the location of the pd values. to be sure that we
        % define a real structre as bias we use a smooth grid fitting 
        [zg,xg,yg] = gridfit(x,y,z,1:2:size(tmp,1),1:2:size(tmp,2),'smoothness',10); 
        % Make the grid points to an 2D image
        ZI = griddata(xg,yg,zg,XI,YI,[],{'Qt','Qbb','Qc','Qz'}); 

        %ZI = griddata(xg,yg,zg,XI,YI);
        ZI = rot90(ZI);
        ZI = flipdim(ZI,1);
        CoilG(:,:,i)=ZI;
        %
        PDc(:,:,i)=pd(:,:,i)./ZI;
        clear ZI tmp
    end;

end;

%we need to adjust this for each scan! until i find a way to it.
%some time the lower or the uper slice are fitted badly (not enough
%points) and then the images in does silces are totly off.

PDc(:,:,1:31)=0;  CoilG(:,:,1:31)=0;

%% Save the fited data and the fitted Coil bias (gain)

dtiWriteNiftiWrapper(single(PDc), xform, fullfile(outDir,'PDc.nii.gz'));
dtiWriteNiftiWrapper(single(CoilG), xform, fullfile(outDir,'CoilG.nii.gz'));

return


