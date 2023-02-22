function [dt6_new, westinShapesbaryc]=dtiDegradeTensorShape(dt6_original, t, method, diffusionCoefficient, diffusion_t)
% Degrades a tensor shape toward a sphere; optionally equates amoutn off
% diffusivity
%
% OUTPUT: Returns the new tensor plus westin shapes in cartesian (from barycentric) coordinates -
% useful to visualize degradation. 
%
% INPUT: dt6_original is XxYxZx6; You can get it from the code below:
% dt=dtiLoadDt6('dt6.mat'); dt6_original=dt.dt6;
% The dt6 format is : [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz].
% t is degradation coef, 0...1 where 1 leads to a perfect sphere; 0 is no
% changes to the original ellipsoid
%
% Method: by default use the following definition of westin shapes (method='westinShapes_l1')
% cl=(l1-l2)/l1; 
% cp=(l2-l3)/l1;
% cs=l3/l1;
% An alternative definition: 
% westin shapes as those computed by dtiComputeWestinShapes(method='westinShapes_lsum')
% cl=(l1-l2)/(l1+l2+l3); 
% cp=(l2-l3)/(l1+l2+l3);
% cs=l3/(l1+l2+l3);
%
% Default: volume preserved. 
% Optional: If diffusionCoefficient supplied, degrades the volume of each tensor towards the value of
% diffusionCoefficient (amount of degradation: diffusion_t from [0...1]), equal across the tensors
%
% History:
% ER 12/2008: wrote it
% ER 01/2009: modified it to accomodate degradation rate not in linear space
% of eigenvalues, but in linear space of westin shapes instead (old and new: westinShapes_lsum, westinShapes_l1;
% new is recommended 
% ER 01/2009: added an option to equate the volumes to a given number
% DY 02/2009: function takes in and outputs XxYxZx6 dt6 matrices, rather than
% Nx6 (where N=X*Y*Z). added lines that reshape the dt6 matrix. Demos don't
% work anymore. 
%
% TODO: demo1 does not do well barycentric plots for westinShapes_lsum
% (though these add up to 1!) -- troubleshoot

% Reshapes the initial XxYxZx6 matrix into an Nx6 matrix, where N = X*Y*Z.
dt6=reshape(permute(dt6_original, [4 1 2 3]),6,[])';


if ~exist('method', 'var')
    method='westinShapes_l1';
end

[eigVec, eigVal] =dtiEig(dt6);

nonPD = find(any(eigVal<0));
if(~isempty(nonPD))
    fprintf('NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...',length(nonPD));
    eigVal(eigVal<0) = 0;
end

l1_e=eigVal(:, 1); l2_e=eigVal(:, 2); l3_e=eigVal(:, 3); 

%Axes of systematic degradation (method): linear change in eigenvalues; in
%westinShapes_l1 (those scaled by l1) and westinShapes_lsum (those
%scaled by the sum of the eigenvalues). Note that currently
%dtiComputeWestinShapes is using westinShapes_lsum while Westin et al. in later work, adopted a simpler normalization
% formulation (e.g., see Westin et. al. 2002 Med. Image Anal.; PMID: 12044998) where the constants are dropped and the denominator is simply
% lambda_1. 

switch method
    case 'eigenvalues'
%compute l1_s=l1_s=l1_s in a sphere given volume preservation assumption
l1_s=nthroot(l1_e.*l2_e.*l3_e, 3);
l2_s=l1_s; l3_s=l1_s; 

%compute new eigenvalues if changed linearly

l1=l1_e+t.*(l1_s-l1_e);
l2=l2_e+t.*(l2_s-l2_e);
l3=l3_e+t.*(l3_s-l3_e);

cl=(l1-l2)./l1;
cp=(l2-l3)./l1;
cs=l3./l1; %Never need this

    case 'westinShapes_l1'
[cl_e, cp_e, cs_e] = dtiComputeWestinShapes([l1_e l2_e l3_e], 'l1');

%Compute volume of the original tensor
vol_e=4/3*pi.*l1_e.*l2_e.*l3_e;

%compute new volume
if (exist('diffusion_t', 'var')&& exist('diffusionCoefficient', 'var'))
  vol=vol_e+diffusion_t*(diffusionCoefficient-vol_e);
else
    vol=vol_e;
end

%Compute the new cl, cp, and cs will be given degradation coefficient t;
cl=(1-t).*cl_e;
cp=(1-t).*cp_e;

%Compute eigenvalues corresponding to the new cl, cp and Volume; 
[l1, l2, l3]=dtiEigenvaluesFromWestinShapes(cl, cp, vol, 'westinShapes_l1');
cs=l3./(l1);

   
    case 'westinShapes_lsum'        
%Compute Westin shapes for ORIGINAL tensor
%[cl, cp, cs] = dtiComputeWestinShapes([l1 l2 l3]); %OLD METHOD
[cl_e, cp_e, cs_e] = dtiComputeWestinShapes([l1_e l2_e l3_e]);

%Compute volume of the original tensor
vol_e=4/3*pi.*l1_e.*l2_e.*l3_e;
epsilon=.0000001;
vol_e(vol_e==0)=epsilon; 

%compute new volume
if (exist('diffusion_t', 'var')&& exist('diffusionCoefficient', 'var'))
  vol=vol_e+diffusion_t*(diffusionCoefficient-vol_e);
else
    vol=vol_e;
end


%Compute the new cl, cp, and cs will be given degradation coefficient t;
cl=(1-t).*cl_e;
cp=(1-t).*cp_e;

%Compute eigenvalues corresponding to the new cl, cp and Volume; 
[l1, l2, l3]=dtiEigenvaluesFromWestinShapes(cl, cp, vol, 'westinShapes_lsum');
cs=3*l3./(l1+l2+l3);


end


%Reconstruct the tensor back from the new eigenvalues and the old
%eigenvectors

eigValDiag=zeros(3, 3, size(eigVal, 1));
%eigValDiag(1, 1, :)=eigVal(:, 1);
%eigValDiag(2, 2, :)=eigVal(:, 2);
%eigValDiag(3, 3, :)=eigVal(:, 3);

eigValDiag(1, 1, :)=l1;
eigValDiag(2, 2, :)=l2;
eigValDiag(3, 3, :)=l3;

dt33_back=zeros(size(eigVal, 1), 3, 3);
for i=1:size(eigVal, 1);
dt33_back(i, :, :)=permute(eigVec(i, :, :), [2 3 1])*eigValDiag(:, :, i)*(permute(eigVec(i, :, :), [3 2 1])); 
end

dt6_linear=dti33to6(dt33_back, 2);

% The dtiDegradeTensorShape function then returns a new set of degraded
% data. The output is Nx6, so we turn the degraded Nx6 matrix back into the
% desired XxYxZx6 matrix.
[X Y Z numDirs]=size(dt6_original);
dt6_new=permute(reshape(dt6_linear', [numDirs X Y Z]), [2 3 4 1]);

%Visualize westin shapes of the new coordinates in barycentric space.
triangframe=[0 0; 2 0; 1 sqrt(3)];
[cl cp cs];
westinShapesbaryc=barycentric2cartesian([cl, cp, cs], triangframe);


return; 






%end dtiDegradeTensorShape%

%Demo 1: 
%Demonstrate on typical elipsoid shapes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%DEMO
%Generate a  variety of ellipsoids to look at...
%Rows: 3 randomly sampled from a FG tensors.
%Columns: degrees of degradation. 
%cd('/biac3/wandell4/data/reading_longitude/dti_y1/ab040913/dti06rt');

cd('C:\PROJECTS\longitudinal_reading\data\ab040913\dti06rt\');
dt=dtiLoadDt6('dt6.mat');

load('fibers\Fibergroup5.mat'); 
%load('fibers/MoriGroups_10000.mat');

coords = horzcat(fg.fibers{:})';
[val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(dt.dt6, coords, inv(dt.xformToAcpc),'dt6','nearest');
dt6 = [val1,val2,val3,val4,val5,val6];

figure; 
ss=randsample(1:size(dt6, 1), 3);
dt6_ss=dt6(ss, :);

dt33 = dti6to33(dt6_ss, 2);
A_old=permute(dt33, [2 3 1]); 




for i=1:3
fprintf('Volume before')
vol=3/4*pi*det(diag(eig(A_old(:, :, i))))
plotn=0;    


    %t=0...1 (degradation degree)
    %6 steps, including original and final
    for t=0:.2:1
    plotn=plotn+1;
    [dt6_new, westinShapesbaryc]=dtiDegradeTensorShape(dt6_ss(i, :), t, 'westinShapes_l1');

    dt33_new = dti6to33(dt6_new, 2);
    A_new=permute(dt33_new, [2 3 1]); 
    
    %Visualize A
    [U D V] = svd(A_new);
    subplot(3, 7, (i-1)*7+plotn); 
    Ellipse_plot(A_new^(-2), [0; 0; 0]); 
    %See http://en.wikipedia.org/wiki/Ellipsoid

    %Visualize path to sphericity
    subplot(3, 7, (i-1)*7+7); hold on; plot(westinShapesbaryc(1), westinShapesbaryc(2) , 'ro');     
        xlabel(num2str(dt6_ss(2, :)));
    end

%Draw bacycentric coord triangle
subplot(3, 7, (i-1)*7+7);
triangframe=[0 0; 2 0; 1 sqrt(3)];
hold on; plot([triangframe(:, 1); triangframe(:, 1)], [triangframe(:, 2); triangframe(:, 2)]); 
text(triangframe(1, 1), triangframe(1, 2), 'CL'); text(triangframe(2, 1), triangframe(2, 2), 'CP'); text(triangframe(3, 1), triangframe(3, 2), 'CS'); 
     axis equal;
     axis([0 2 0 2]);
fprintf('Volume after')
vol=3/4*pi*det(diag(eig(A_new(:, :))))
end

%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEMO2: traveling in space of canonical shapes as a function of t:
%Exploration of special cases; E.g.: perhaps, you want to closely look at
%the degradation curve for one of the ellipsoid emerged from Demo1

figure; 
triangframe=[0 0; 2 0; 1 sqrt(3)];
plot([triangframe(:, 1); triangframe(:, 1)], [triangframe(:, 2); triangframe(:, 2)]); 

i=1;

dt6_ss=[1 2 .1 0 0 0]; 
%dt6_ss=[1 .2 .1 0 0 0];
%dt6_ss=[1 .1 .1 0 0 0]; %Linearity case
%dt6_ss=[1 1 .1 0 0 0]; %Planarity case
%dt6_ss=[.1 .1 .1 0 0 0]; %Sphericity case

    for t=0:.1:1
    [dt6_new, westinShapesbaryc]=dtiDegradeTensorShape(dt6_ss(i, :), t, 'westinShapes_l1');
    hold on;     plot(westinShapesbaryc(1), westinShapesbaryc(2) , 'ro');
    end
text(triangframe(1, 1), triangframe(1, 2), 'CL'); text(triangframe(2, 1), triangframe(2, 2), 'CP'); text(triangframe(3, 1), triangframe(3, 2), 'CS'); 
text(.5, .5, ['l1 l2 l3 = ' num2str(dt6_ss(1:3))]); 

axis off;

