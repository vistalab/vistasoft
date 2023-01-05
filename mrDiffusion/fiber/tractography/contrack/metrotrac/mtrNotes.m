% This appears to be a script containing notes someone (Sherbondy?) made
% of matlab commands that were deemed useful.
%


% Getting gui data
h = guidata(gcf);

% Setting gui data
guidata(gcf,h);

% Setting size from ui
sizeVec = get(gcf,'Position');
set(gcf,'Postion',sizeVec);

% Look at a 2d image for sanity
figure;imagesc(image2d); axis image; colorbar
% Or add montage
figure; imagesc(makeMontage(errImg)); axis image; colormap gray; colorbar
ni2
% Overlay montage (background = b0, overlay = errImg)
im=mrAnatOverlayMontage(errImg,eye(4),b0,eye(4),cm,[.1 1],[1:50]);

% Getting a filec
if( notDefined('filename') )
    [f,p] = uigetfile({'*.ext';'*.*'},'Select a file for input...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    filename = fullfile(p,f); 
    % or for base name
    %filename = fullfile(p,f(1:end-3));
end

% Putting a file
if( notDefined('filename') )
  outPathName = pwd;
  [f,p] = uiputfile('*.ext', 'Select output file...', outPathName);
  if(isnumeric(f)) error('User cancelled.'); end
  filename = fullfile(p,f);
end


% Move files of one extension to another extension, but leave rest of name
% Example moving all paths*.txt to paths*.dat
filepattern_in = 'paths*.txt';
ext_out = 'dat';
%dir_name = 'c:\cygwin\home\sherbond\images\md040714\bin\metrotrac\params_search';
dir_name = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis\bin\metrotrac\tendon_small';
filepattern_in = fullfile(dir_name,filepattern_in);

files = dir(filepattern_in);
for ff = 1:length(files)
    [pathstr, name, ext, versn] = fileparts(files(ff).name);
    filename_out = sprintf('%s.%s',name,ext_out);
    filename_out = fullfile(dir_name,filename_out);
    filename_in  = fullfile(dir_name,files(ff).name);
    %sprintf(cmd,'mv %s %s', filename_in, filename_out);
    %system(cmd);
    cmd = ['mv ' filename_in ' ' filename_out];
    disp(cmd); disp('...')
    system(cmd,'-echo');
end

% Calculating local curvature along entire path
stepsize = 2;
dt6 = load('dti3_dt6.mat');
fg = dtiReadFibers('fibers\GM_allFG.mat', dt6.t1NormParams);
fibervec = [];
for ff = 1:length(fg.fibers)
    fiber = fg.fibers(ff);
    fibervec = [fibervec zeros(3,1) zeros(3,1) fiber{:}];
end
shift_fibervec = circshift(fibervec,[0,2]);
angle = acos((2*stepsize^2 - (sum((fibervec-shift_fibervec).^2,1)).^2)/(2*stepsize^2)); 
valid1 = sum(fibervec,1);
valid2 = sum(shift_fibervec,1);
angle = angle(valid1 ~= 0 & valid2 ~= 0);


% Calculating on fiber density image offline
dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
dt6File = fullfile(dataDir,'dti3_dt6.mat');
fgDir = 'fibers';
fgFilename = fullfile(dataDir,fgDir,'stt_end_voi_small_tendon.mat');
img_filename = 'stt_end_voi_small_tendon_fd_image.nii.gz';
img_filename = fullfile(dataDir,fgDir,img_filename);

dt6 = load(dt6File);
fg = dtiReadFibers(fgFilename, dt6.t1NormParams);

%bb = dtiGet(h,'boundingBox');
%imSize = diff(bb)+1;
imSize = size(dt6.anat.img);imSize = imSize(1:3);
% TO DO: this should be based on the actual fiber step size, rather than
% assuming that it's 1mm.
mmPerVoxel = [2 2 2];
xformImgToAcpc = dt6.anat.xformToAcPc/diag([dt6.anat.mmPerVox 1]);

fdImg = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);
dtiWriteNiftiWrapper(fdImg, dt6.anat.xformToAcPc, img_filename);

% Clip fibers by intersection with ROI
%sil
dataDir = 'c:\cygwin\home\sherbond\images\sil_nov05\dti3_ser7\analysis';
%fgName = 'stt_tendon_plate_end_voi.mat';
%roiNames = {'tendon_plate','end_voi'};

% Clip fibers by some transverse plane
%tony
dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
fgName = 'stt_end_tendon_sub_slice.mat';
roiNames = {'tendon_sub_slice','end_VOI'};

%thor
% dataDir = 'c:\cygwin\home\sherbond\images\thor_nov05\dti4_ser11\analysis';
% fgName = 'stt_gastroc_tendon_end_cleaned.mat';

roi1File = fullfile(dataDir,'ROIs',roiNames{1});
roi2File = fullfile(dataDir,'ROIs',roiNames{2});
roi1 = dtiReadRoi(roi1File);
roi2 = dtiReadRoi(roi2File);

fg = dtiReadFibers(fullfile(dataDir,'fibers',fgName), 'junk');
for ff = 1:length(fg.fibers)
    fiber = fg.fibers{ff};
    % Intersect fiber
    [indices, bestSqDist] = nearpoints(fiber, roi1.coords');
    [foo, index1] = min(bestSqDist);
    [indices, bestSqDist] = nearpoints(fiber, roi2.coords');
    [foo, index2] = min(bestSqDist);
    fiber = fiber(:,min([index1 index2]):max([index1 index2]));
    fg.fibers{ff} = fiber;
end
outputname = 'stt_tendon_plate_end_voi_clipped';
fg.name = outputname;
dtiWriteFiberGroup(fg, fullfile(dataDir,'fibers',[outputname '.mat']));

% Take mean of separate pennation measurements
% dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
% fgDir = 'bin\metrotrac\tendon_small';
dataDir = 'c:\cygwin\home\sherbond\images\thor_nov05\dti4_ser11\analysis';
fgDir = 'fibers\gastroc';
num_rois = 32;
penn_angles = [];
for rr = 1:num_rois
    statsfile = sprintf('fg_analysis_%d.mat',rr);
    statsfile = fullfile(dataDir,fgDir,statsfile);
    stats = load(statsfile);
    if(stats.mean_penn < 0)
        penn_angles = [penn_angles; -stats.penn_angles(:)];
    else
        penn_angles = [penn_angles; stats.penn_angles(:)];
    end
end
mean_penn = mean(penn_angles*180/pi);
std_penn = std(penn_angles*180/pi);
figure; hist(penn_angles*180/pi);
disp(['Mean: ' num2str(mean_penn)]);
disp(['Std: ' num2str(std_penn)]);

% Plotting distribution on the sphere
% ran sph_dist -k1 -500 -k2 -0.1 -ns 5000 > test.Bdouble
cd c:\cygwin\home\sherbond\src\sph_dist\
%cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
%cmd = 'c:\cygwin\home\sherbond\installs\camino\bin\sphsample -k1 -2000 -k2 -0.1 -ns 5000 > test.Bdouble';
%cmd = 'java -Xmx512 SphPDF_Sample -k1 -2000 -k2 -0.1 -ns 5000 -outputfile test.Bdouble';
% disp(cmd);
% [s, ret_info] = system(cmd,'-echo');
% disp(ret_info);
fid = fopen('test.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,5000);
sub_vecs = vecs(:,vecs(3,:)>0);
mean(sub_vecs,2)
figure; plot3(vecs(1,:), vecs(2,:), vecs(3,:), '.')
hold on
sphere
alpha(0.3)
axis equal
axis vis3d
xlabel('x');
ylabel('y');
zlabel('z');
fid = fopen('test2.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,5000);
sub_vecs = vecs(:,vecs(3,:)>0);
mean(sub_vecs,2)
plot3(vecs(1,:), vecs(2,:), vecs(3,:), 'gx')
hold off

% Plotting distribution on the sphere for Behrens Data
wDir = 'c:\cygwin\home\sherbond\data\bg040719\dti06\bin';
ni = niftiRead(fullfile(wDir,'merged_thsamples.nii.gz')); % Switch theta and phi
phVec = squeeze(ni.data(26,31,38,:));
ni = niftiRead(fullfile(wDir,'merged_phsamples.nii.gz'));
thVec = squeeze(ni.data(26,31,38,:));
vecs = [cos(thVec).*sin(phVec), sin(thVec).*sin(phVec), cos(phVec)]';
S = zeros(3,3);
for vv=1:size(vecs,2)
    x=vecs(:,vv);
    S = S + x*x';
end
S = S/size(vecs,2);
lambdas = eig(S);
bDisp = asin(sqrt(1 - max(lambdas)))*180/pi;
figure; plot3(vecs(1,:), vecs(2,:), vecs(3,:), '.')
hold on
sphere
alpha(0.3)
axis equal
axis vis3d
xlabel('x');
ylabel('y');
zlabel('z');
% Get my direction distribution based on fibers chosen
ni = niftiRead(fullfile(wDir,'pdf.nii.gz'));
pdfData = squeeze(ni.data(26,31,38,:));
Cl = pdfData(12);
l2 = pdfData(13);
l3 = pdfData(14);
delta = 100 / (1+exp(-(0.175-Cl)/0.015));
sig3 = l3/(l2+l3) * delta;
sig2 = l2/(l2+l3) * delta;
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,5000);
sub_vecs = vecs(:,vecs(3,:)>0);
mean(sub_vecs,2)
plot3(vecs(1,:), vecs(2,:), vecs(3,:), 'gx')
hold off

% Load tensor and draw as ellipsoid
figure;
ni = niftiRead(fullfile(wDir,'tensors.nii.gz'));
%tensor = squeeze(ni.data(26,31,38,1,:));
tensor = squeeze(ni.data(41,45,41,1,:));
D = [tensor(1), tensor(2), tensor(4);
     tensor(2), tensor(3), tensor(5);
     tensor(4), tensor(5), tensor(6); ];
Dinv = inv(sqrtm(D));
%coef_inv = tensor([1,3,6,2,4,5]);
coef_inv = [Dinv(1,1) Dinv(2,2) Dinv(3,3) Dinv(1,2) Dinv(1,3) Dinv(2,3)];
[xmesh, ymesh, zmesh] = meshgrid(-3:0.1:3,-3:0.1:3,-3:0.1:3);
vmesh = coef_inv(1)*xmesh.^2 + coef_inv(2)*ymesh.^2 + coef_inv(3)*zmesh.^2 + coef_inv(4)*2*xmesh.*ymesh + coef_inv(5)*2*xmesh.*zmesh + coef_inv(6)*2*ymesh.*zmesh;
p = patch(isosurface(xmesh,ymesh,zmesh,vmesh,1));
isonormals(xmesh,ymesh,zmesh,vmesh,p)
set(p,'FaceColor','yellow','EdgeColor','black','EdgeAlpha',0.1);
daspect([1 1 1])
view(3);
%light('Position',[1 0 0],'Style','infinite'); 
camlight;
lighting gouraud
cmap = [autumn(255); [.25 .25 .25]];
axis equal vis3d; colormap(cmap); alpha 1;
xlabel('x');ylabel('y');zlabel('z');


% ran sph_dist -k1 -500 -k2 -0.1 -ns 5000 > test.Bdouble
cd c:\cygwin\home\sherbond\src\sph_dist\
%cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
%cmd = 'c:\cygwin\home\sherbond\installs\camino\bin\sphsample -k1 -2000 -k2 -0.1 -ns 5000 > test.Bdouble';
%cmd = 'java -Xmx512 SphPDF_Sample -k1 -2000 -k2 -0.1 -ns 5000 -outputfile test.Bdouble';
% disp(cmd);
% [s, ret_info] = system(cmd,'-echo');
% disp(ret_info);
fid = fopen('test.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,5000);
sub_vecs = vecs(:,vecs(3,:)>0);
mean(sub_vecs,2)
figure; plot3(vecs(1,:), vecs(2,:), vecs(3,:), '.')
hold on
sphere
alpha(0.3)
axis equal
axis vis3d
xlabel('x');
ylabel('y');
zlabel('z');
fid = fopen('test2.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,5000);
sub_vecs = vecs(:,vecs(3,:)>0);
mean(sub_vecs,2)
plot3(vecs(1,:), vecs(2,:), vecs(3,:), 'gx')
hold off


% Extract specific voxels for bootstrap and fit distributions
% low and high FA point found with fslview on the fa image
point_lowfa = [61,79,37]; % fa ~= 0.23
point_highfa = [67,74,25]; % fa ~= 0.84
% Extract points from raw-eddy-corrected image on teal
cd /teal/scr1/dti/dtiBootstrap/tony_scr
fid = fopen('ec.Bfloat','rb','b');
d = fread(fid,'float'); fclose(fid);
img_ec = reshape(d,130,128,128,50);
ec_highlow = [img_ec(:,67,74,25) img_ec(:,61,79,37)];
fid = fopen('ec_hl.Bfloat','wb','b');
fwrite(fid,ec_highlow,'float');
% Now on lappy lets fit the data and everything
% Sanity check FA
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
%cmd = 'dtfit ec_hl.Bfloat mho.scheme | fa | double2txt';
fid = fopen('dtboot_hl.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
% Lets look at the Bingham fit to the high fa voxel
%cmd = 'cat dtboot_hl.Bdouble | shredder 0 24000 24000 > dtboot_h.Bdouble';
%cmd = 'cat dtboot_h.Bdouble | axialdistfit -pdf bingham | double2txt';
% Lets look at the Bingham fit to the low fa voxel
%cmd = 'cat dtboot_hl.Bdouble | shredder 24000 24000 24000 > dtboot_l.Bdouble';
%cmd = 'cat dtboot_l.Bdouble | axialdistfit -pdf bingham | double2txt';

% read in camino data and write out nifti image
fid = fopen('meanB0.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
%img = shiftdim(reshape(d,[12 128 128 50]),1);
img = reshape(d,[128 128 50]);
dtiWriteNiftiWrapper(img,M,'meanB0_2.nii.gz');

% read in nifti image and write out camino data
fileRootName = 'meanB0';
datatype = 'double'; %float or double
ni = niftiRead([fileRootName '.nii.gz']);
% put the 4th dimension in front if its there if scalar
% volume this does nothing
d = shiftdim(ni.data,3);
fid = fopen([fileRootName '.B' datatype],'wb','b');
fwrite(fid,d(:),datatype); fclose(fid);


% Calculating the thermal noise standard deviation
% First lets get all the raw B0 values together

% THIS ONE IS DEFINITELY BROKE BECAUSE OF THE FIRST IMAGE

%cmd = 'cat mho_dti_ec.Bfloat| shredder 0 4 48 > ec_b0.Bfloat';
% Get average B0 in matlab
% cd c:\cygwin\home\sherbond\experiments\dtiBootstrap 
% fid = fopen('ec_b0.Bfloat','rb','b');
% d = fread(fid,'float'); fclose(fid);
% img_b0 = reshape(d,[10 128 128 50]);
% img_meanb0 = squeeze(geomean(img_b0));
% M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
% img_meanb0( img_meanb0 < 1 ) = 1;
% img_meanb0 = log( img_meanb0 );
% dtiWriteNiftiWrapper(img_meanb0,M,'meanB0.nii.gz');
% % Can find standard deviation of thermal noise from mean of the b0 in air
% %img_bg_meanb0 = img_meanb0(8:28,26:46,26);
% img_bg_meanb0 = exp(img_meanb0(9:33,12:54,26));
% sigma = std(img_bg_meanb0(:))/0.655; % sigma = 4334

% This method seems to work better, why??
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
ni = niftiRead('lns0.nii.gz');
img_lns0 = ni.data;
img_subs0 = exp(img_lns0(9:33,12:54,26));
sigma = std(img_subs0(:))/0.655 % sigma = 62
img_subs0 = exp(img_lns0(46:55,78:83,31));
snr = mean(img_subs0(:)) / sigma % snr = 13

% Running the constrained sampling for the low FA voxel
cmd = 'cat ec_l.Bfloat | sphsample -pdf dt_constrained -dt 6.9 0.89e-9 0.06e-9 0.12e-9 0.68e-9 0.06e-9 0.76e-9 -sigma 62 -psFilename olaDirs2600.txt -schemefile mho.scheme -ns 5000 | axialdistfit -pdf bingham |double2txt';
cmd = 'sphsample -pdf bingham -k1 -79 -k2 -59 -ns 5000 > samples_l.Bdouble';

% Running the constrained sampling for the high FA voxel
cmd = 'cat ec_h.Bfloat | sphsample -pdf dt_constrained -dt 6.6 1.4e-9 0.5e-9 0.2e-9 0.5e-9 0.1e-9 0.3e-9 -sigma 62 -psFilename olaDirs2600.txt -schemefile mho.scheme -ns 5000 | axialdistfit -pdf bingham |double2txt';
cmd = 'sphsample -pdf bingham -k1 -1111 -k2 -727 -ns 5000 > samples_h.Bdouble';


% Splitting voxel array into subdivisions for parallel processing
NN = 16; % compute nodes
NV = 819200;  % voxels
NC = 130; % components per voxel
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
fid = fopen('bet_mask.Bshort','rb','b');
d = fread(fid,'short'); fclose(fid); 
bIndex = 1;
for nn = 1:NN
    eIndex = length(d)/NN + bIndex - 1;
    filename = sprintf('mask_s%d.Bshort',nn);
    fid = fopen(filename,'wb','b');
    fwrite(fid,d(bIndex:eIndex),'short'); fclose(fid);
    bIndex = eIndex+1;
end

% Create script for parallel processing dtconstrained fit on deep-lumens
NN = 16; % compute nodes
NV = 819200;  % voxels
NC = 130; % components per voxel
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
fid = fopen('dtfit_par.sh','wt');
fprintf(fid,'#!/bin/bash\n');
bIndex = 1;
for nn = 1:NN
    inFilename = sprintf('~/experiments/dtiBootstrap/ec_s%d.Bfloat',nn);
    maskFilename = sprintf('~/experiments/dtiBootstrap/mask_s%d.Bshort',nn);
    outFilename = sprintf('~/experiments/dtiBootstrap/dtconst_s%d.Bdouble',nn);
    mach_num = floor((nn-1)/2) + 1;
    fprintf(fid,'echo ''Compute deep-lumen%d''\n',mach_num);
    fprintf(fid,'ssh deep-lumen%d modelfitconstrained -inputfile %s -sigma 62 -psFilename ~/experiments/dtiBootstrap/olaDirs2600.txt -schemefile ~/experiments/dtiBootstrap/mho.scheme -bgmask %s -outputfile %s &\n',mach_num,inFilename,maskFilename,outFilename);
    %fprintf(fid,'ssh deep-lumen%d modelfit -inputfile %s -inversion 1 -schemefile ~/experiments/dtiBootstrap/mho.scheme -bgmask %s -outputfile %s &\n',mach_num,inFilename,maskFilename,outFilename);
end
fclose(fid);

% Combine subdivisions of voxel array into one array and then the 4d image
% the numumber of components per voxel to write can be different than the
% number read
NN = 16; % compute nodes
NV = 819200;  % voxels
NCr = 20; % components per voxel to read
NCw = 20; % components per voxel to write
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
bIndex = 1;
d_comb = zeros(NV*NCw,1);
for nn = 1:NN
    filename = sprintf('dtconst_s%d.Bdouble',nn);
    %filename = sprintf('mask_s%d.Bshort',nn);
    %filename = sprintf('parallel_proc/ec_s%d.Bfloat',nn);
    disp(['Loading ' filename ' ...']);
    fid = fopen(filename,'rb','b');
    d = fread(fid,'double'); fclose(fid); 
    fi = repmat([ones(NCw,1); zeros(NCr-NCw,1)],NV/NN,1);
    sub_d = d(find(fi));    
    d_comb(bIndex:length(sub_d)+bIndex-1) = sub_d(1:end);
    bIndex = length(sub_d) + bIndex;
end
%fid = fopen('ec_comb.Bfloat','wb','b');
%fwrite(fid,d_comb,'float'); fclose(fid);
img_d = shiftdim(reshape(d_comb,[NCw 128 128 50]),1);
%img_d = reshape(d_comb,[128 128 50]);
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
dtiWriteNiftiWrapper(img_d,M,'dtconst_temp.nii.gz');

% Strip the PDF data out of the fit
ni = niftiRead('dtconst_temp.nii.gz');
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
NCr = size(ni.data,4);
NCw = 12;
dtiWriteNiftiWrapper(ni.data(:,:,:,NCr-NCw+1:end),M,'pdf_const.nii.gz');

% Fitting non-PD tensors
ni = niftiRead('mho_dti_ec.nii.gz');
S = squeeze(ni.data(65,86,16,:));
clear ni;
scheme = load('mho.scheme');
tau = scheme(1);
g = reshape(scheme(3:end),3,130);
% Remove all the b0 measurements
g0Index = (g(1,:) == 0 & g(2,:) == 0 & g(3,:) == 0);
S0 = geomean(S(g0Index));
Si = S(~g0Index);
gi = g(:,~g0Index);
X = -tau* [gi(1,:)'.*gi(1,:)', gi(2,:)'.*gi(2,:)', gi(3,:)'.*gi(3,:)', 2*gi(1,:)'.*gi(2,:)', 2*gi(2,:)'.*gi(3,:)', 2*gi(1,:)'.*gi(3,:)'];
D = X\log(Si/S0);
Dmat = [D(1) D(4) D(6); D(4) D(2) D(5); D(6) D(5) D(3)];
[vec, val] = eig(Dmat);
R0 = sqrt(D(1));
R5 = D(6)/R0;
R3 = D(4)/R0;
R1 = sqrt( D(2)-R3^2 );
R4 = ( D(5)-R3*R5 ) / R1;
R2 = sqrt(D(3) - R4^2 - R5^2);
Rmat = [ R0 R3 R5; 0 R1 R4; 0 0 R2];
DCmat = Rmat.'*Rmat;
[vecC, valC] = eig(DCmat);

D(1) - R0^2
D(6) - R0*R5
D(4) - R0*R3
D(2) - (R3^2+R1^2)
D(5) - (R3*R5 + R1*R4)
D(3) - (R2^2 + R4^2 + R5^2)
Dr = [R0^2; R3^2+R1^2; R2^2 + R4^2 + R5^2; R0*R3; R3*R5 + R1*R4; R0*R5];

% Reading tracts from camino
% The  raw  streamline  format  is 32 bit float. For each streamline, the
%        program outputs the number of points N in the streamline, the index  of
%        the  seed  point,  followed  by the (x,y,z) coordinates (in mm) of each
%        point: [<N>, <seed point index>, <x_1>, <y_1>, <z_1>,...,<x_numPoints>,
%        <y_N>, <z_N>, <N>,...,<z_N>], where the <seed point index> is the point
%        on the streamline where tracking began. The  voxels  format  is  16-bit
%        signed  integer, and lists the integer indices of all M voxels that the
%        streamline passes through, in the  format  [<M>,  <seed  point  index>,
%        <vx_1>,  <vy_1>, <vz_1>,...,<vx_M>, <vy_M>, <vz_M>, M,...,<vz_M>].  The
%        OOGL format outputs a LIST of OOGL VECT objects in  ASCII  format.  The
%        colour  at each point on the streamline is an RGB vector that describes
%        the local orientation as a combination of red (x), green (y)  and  blue
%        (z).
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap
fid = fopen('camino_lgn\tractsraw_way1.Bfloat','rb','b');
d = fread(fid,'float'); fclose(fid);
% Organize the tracts
fg = dtiNewFiberGroup;
fg.name = ['lgn'];
fg.colorRgb = [20 20 240];
dd = 1;
ff = 1;
head_offset = 2;
while dd <= length(d)
    % Pull a tract off the data stack
    path_len = d(dd);
    off = dd+head_offset;
    pathway = d(dd+2:dd+2+(3*path_len)-1);
    % Put the tract into the right format
    fg.fibers{ff} = reshape(pathway,3,path_len);
    % Update the data stack pointer and fiber data pointer
    dd = dd+2+(3*path_len);
    ff = ff+1;
end
mtrExportFiberGroupToMetrotrac('camino_lgn\tractsraw_way1.dat',fg,'',[2 2 2],M,[128 128 50]);

%Add directory with subdirectories to java dynamic path
dir_root = 'c:\cygwin\home\sherbond\installs\camino\';
dirs = dir(dir_root);
for ff = 1:length(dirs)
    full_dirname = [dir_root dirs(ff).name];
    if(isdir( full_dirname ) && ~strcmp(dirs(ff).name,'..') && ~strcmp(dirs(ff).name,'.'))
        javaaddpath(full_dirname);
    end
end

% Make mask image from ROI file
cd c:\cygwin\home\sherbond\images\as050307\
%cd c:\cygwin\home\sherbond\images\me050126\
roiFile = 'LLgn_FA.mat';
roiMaskFile = 'LLgnMask.nii.gz';
roiOtherMaskFile = 'LCalcarineMask.nii.gz';
bothMaskFile = 'LBothMask.nii.gz';
dtFile = 'as050307_dt6.mat';
paramsFile = 'LOR_met_params.txt';
fathresh = 2;
%roi = dtiReadRoi('ROIs\LCalcarineRect.mat');
roi = dtiReadRoi(fullfile('ROIs',roiFile));
dt = load(dtFile,'xformToAcPc');
roi.coords = mrAnatXformCoords(inv(dt.xformToAcPc), roi.coords);
ni = niftiRead('bin\backgrounds\fa.nii.gz');
img_mask = zeros(size(ni.data));
for ii = 1:size(roi.coords,1)
    if(ni.data(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) <= fathresh)
        img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 1;
    end
end
dtiWriteNiftiWrapper(img_mask,dt.xformToAcPc,fullfile('bin\metrotrac\', roiMaskFile));
% and update the met params with the new ROI
mtr = mtrLoad(fullfile('bin\metrotrac\',paramsFile),dt.xformToAcPc);
roi.coords = mrAnatXformCoords(dt.xformToAcPc, roi.coords);
mtr = mtrSet(mtr,'roi',roi.coords,1,'coords');
mtrSave(mtr,fullfile('bin\metrotrac\',paramsFile),dt.xformToAcPc);
% and update the mask image that contains both ROIs
ni = niftiRead(fullfile('bin\metrotrac\',roiMaskFile));
img_one = ni.data;
ni = niftiRead(fullfile('bin\metrotrac\',roiOtherMaskFile));
img_two = ni.data;
img_both = img_one | img_two;
dtiWriteNiftiWrapper(uint8(img_both),dt.xformToAcPc,fullfile('bin\metrotrac\',bothMaskFile));

% Create script for parallel processing of pathway tracing on DLs
NN = 16; % compute nodes
%cd c:\cygwin\home\sherbond\images\me050126\bin\metrotrac
cd c:\cygwin\home\sherbond\images\as050307\bin\metrotrac
fid = fopen('track_parallel_ROR.sh','wt');
fprintf(fid,'#!/bin/bash\n');
offset = 0;
for nn = 1:NN
    mach_num = floor((nn-1)/2) + 1;
    sub_n = 2 - mod(nn,2);
    %paramsFilename = '/radlab_share/home/tony/images/me050126/bin/metrotrac/LOR_met_params.txt';
    paramsFilename = '/radlab_share/home/tony/images/as050307/bin/metrotrac/ROR_met_params.txt';
    %pathsFilename = sprintf('/radlab_share/home/tony/images/me050126/bin/metrotrac/paths_LOR_%d.dat',nn+offset);
    pathsFilename = sprintf('/radlab_share/home/tony/images/as050307/bin/metrotrac/paths_ROR_%d.dat',nn+offset);
    exeFilename = '/radlab_share/home/tony/src/dtivis/DTIPrecomputeApp/dtiprecompute_met';
    fprintf(fid,'echo ''Compute deep-lumen%d''\n',mach_num);
    fprintf(fid,'ssh deep-lumen%d %s -i %s -p %s &\n',mach_num,exeFilename,paramsFilename,pathsFilename);
    fprintf(fid,'sleep 2\n');
    %fprintf(fid,'ssh deep-lumen%d modelfit -inputfile %s -inversion 1 -schemefile ~/experiments/dtiBootstrap/mho.scheme -bgmask %s -outputfile %s &\n',mach_num,inFilename,maskFilename,outFilename);
end
fclose(fid);


% Calculate westin shapes from eigenvalue image
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap\
ni = niftiRead('eigcnls.nii.gz');
img_eig = ni.data(:,:,:,1:4:end);
img_ishape = zeros(size(img_eig(:,:,:,1:2)));
for z = 1:size(img_eig,3)
    for y = 1:size(img_eig,2)
        for x = 1:size(img_eig,1)
            img_ishape(x,y,z,1) = (img_eig(x,y,z,1) - img_eig(x,y,z,2)) / sum(img_eig(x,y,z,:));
            img_ishape(x,y,z,2) = 2*(img_eig(x,y,z,2) - img_eig(x,y,z,3)) / sum(img_eig(x,y,z,:));
        end
    end
end
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
dtiWriteNiftiWrapper(img_ishape,M,'shapes.nii.gz');

% Add shape indices to pdf image, remove log_A
cd c:\cygwin\home\sherbond\experiments\dtiBootstrap\
ni = niftiRead('pdf.nii.gz');
img_pdf = ni.data;
ni = niftiRead('shapes.nii.gz');
img_shapes = ni.data;
img_pdf(:,:,:,12:13) = img_shapes;
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2;
dtiWriteNiftiWrapper(img_pdf,M,'pdfshapes.nii.gz');

% Lets examine distributions based on shapes
%cd c:\cygwin\home\sherbond\images\me050126\
ni = niftiRead(fullfile('bin','pdf.nii.gz'));
img_k1 = ni.data(:,:,:,10);
img_k2 = ni.data(:,:,:,11);
img_cl = ni.data(:,:,:,12);
img_cp = ni.data(:,:,:,13);
img_cs = 1 - (img_cl + img_cp);
ni = niftiRead(fullfile('bin','backgrounds','fa.nii.gz'));
img_fa = ni.data;
% Making a white matter mask
ni = niftiRead(fullfile('bin','wmMask.nii.gz'));
img_wm = ni.data;
ind_throwaway = ~img_wm | -img_k2 < 1;
favec = img_fa(~ind_throwaway);
kwvec = -img_k2(~ind_throwaway);
clvec = img_cl(~ind_throwaway);
cpvec = img_cp(~ind_throwaway);
csvec = 1 - (cpvec+clvec);
angle_disp = 1./sqrt(kwvec) * 180 / pi;
corrcoef(angle_disp,clvec)
p = polyfit(favec,angle_disp,1);
line_x = [0:0.1:1];
line_y = polyval(p,line_x);
figure
%plot(csvec,kwvec,'.',line_x,line_y);
plot(csvec,angle_disp,'.')

% Bin according to fa and draw mean of dispersion angle
hold on;
delta = 0.025;
edges = [0:delta:0.8];
[n,bin] = histc(csvec,edges);
points = zeros(length(n)-1,2);
for bb = 1:(length(n)-1)
    points(bb,1) = median(angle_disp(bin == bb ));
    points(bb,2) = std(angle_disp(bin == bb ));
end
pSamples = edges(2:end)-0.5*delta;
%errorbar(faSamples,points(:,1),points(:,2),'g'); 
plot(pSamples,points(:,1),'-og','LineWidth',2); 

% Find asymptote median curve for dispersion angle to be about 4 degrees
kAsymptote = (1/(10 * pi/180))^2

% Make tensor from westin shape indices
Cl = 0.6;
Cp = 0.26;
Cs = 1 - (Cl+Cp);
sum_eig = 1;
eigvalue = [0 0 0];
eigvalue(3) = Cs * sum_eig / 3;
eigvalue(2) = Cp * sum_eig / 2 + eigvalue(3);
eigvalue(1) = Cl * sum_eig + eigvalue(2);

% Drawing a tensor as an ellipsoid
%[U S V] = svd(D);
figure;
U = [0 0 1; 0 1 0; 1 0 0]';
%S = [10 10 1];
S =  eigvalue;
S = S / norm(S);
Dinv = U*diag(1./sqrt(S))*U';
coef_inv = [Dinv(1,1) Dinv(2,2) Dinv(3,3) Dinv(1,2) Dinv(1,3) Dinv(2,3)];
[xmesh, ymesh, zmesh] = meshgrid(-3:0.1:3,-3:0.1:3,-3:0.1:3);
vmesh = coef_inv(1)*xmesh.^2 + coef_inv(2)*ymesh.^2 + coef_inv(3)*zmesh.^2 + coef_inv(4)*2*xmesh.*ymesh + coef_inv(5)*2*xmesh.*zmesh + coef_inv(6)*2*ymesh.*zmesh;
p = patch(isosurface(xmesh,ymesh,zmesh,vmesh,1));
isonormals(xmesh,ymesh,zmesh,vmesh,p)
set(p,'FaceColor','yellow','EdgeColor','none','EdgeAlpha',0.1);
daspect([1 1 1])
view(3);
camlight 
lighting gouraud
cmap = [autumn(255); [.25 .25 .25]];
axis equal vis3d; colormap(cmap); alpha 1;
xlabel('x');ylabel('y');zlabel('z');

% Read in camino dt data and write out out tensor format
cd c:\cygwin\home\sherbond\images\as050307\
fid = fopen('dt.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
img_d = shiftdim(reshape(d,[8 81 106 76]),1);
img_d2 = zeros(size(img_d(:,:,:,3:end)));
img_d2(:,:,:,1) = img_d(:,:,:,3);
img_d2(:,:,:,2) = img_d(:,:,:,6);
img_d2(:,:,:,3) = img_d(:,:,:,8);
img_d2(:,:,:,4) = img_d(:,:,:,4);
img_d2(:,:,:,5) = img_d(:,:,:,5);
img_d2(:,:,:,6) = img_d(:,:,:,7);
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2; M(1:3,4) = [-81;-121;-61];
dtiWriteNiftiWrapper(img_d2,M,'tensors.nii.gz');

% Split bootstrap fit into tensor file and pdf file
cd c:\cygwin\home\sherbond\images\me050126\
fid = fopen('dtboot.Bdouble','rb','b');
d = fread(fid,'double'); fclose(fid);
img_d = shiftdim(reshape(d,[21 81 106 76]),1);
img_d2 = zeros(size(img_d(:,:,:,3:8)));
img_d2(:,:,:,1) = img_d(:,:,:,3);
img_d2(:,:,:,2) = img_d(:,:,:,6);
img_d2(:,:,:,3) = img_d(:,:,:,8);
img_d2(:,:,:,4) = img_d(:,:,:,4);
img_d2(:,:,:,5) = img_d(:,:,:,5);
img_d2(:,:,:,6) = img_d(:,:,:,7);
M = eye(4); M(1,1)=2; M(2,2)=2;M(3,3)=2; M(1:3,4) = [-81;-121;-61];
dtiWriteNiftiWrapper(img_d2,M,'tensors.nii.gz');
dtiWriteNiftiWrapper(img_d(:,:,:,9:end),M,'pdf.nii.gz');

% Making a white matter mask
cd c:\cygwin\home\sherbond\images\as050307\
ni = niftiRead('bin\backgrounds\fa.nii.gz');
img_fa = ni.data;
ni = niftiRead('bin\backgrounds\b0.nii.gz');
img_b0 = ni.data;
M = ni.qto_xyz;
clear ni;
img_b0 = mrAnatHistogramClip(img_b0,0.4,0.99);
img_wm = dtiCleanImageMask(img_fa>0.15 & img_b0 > 0.4*max(img_b0(:)));
dtiWriteNiftiWrapper(uint8(img_wm),M,'bin\wmMask.nii.gz');

% Adjusting scanner noise estimate with dispersion from shape of tensor
Cl = [0:0.01:1];
scanner_s = 20; % degrees
scanner_k = 1 / (scanner_s*pi/180)^2;
uniform_s = 60; % degrees
shift_s = 4;
shape_ds = (uniform_s-shift_s) ./ (1+exp(-(0.175-Cl)*5/0.075)) + shift_s;
shape_dk = 1 ./ (shape_ds*pi/180).^2;
comp_k = scanner_k*shape_dk ./ (shape_dk + scanner_k + 2*sqrt(scanner_k*shape_dk));
comp_s = 1 ./ sqrt(comp_k) * 180 / pi;
figure;
plot(Cl,comp_s);

% Plot statistics along paths
cd c:\cygwin\home\sherbond\images\me050126\
fgFile = 'bin\metrotrac\paths_sub_good.dat';
pdfFile = 'bin\pdf.nii.gz';

% Load pdf data
ni = niftiRead(pdfFile);

% Import the resulting fiber group
fg = dtiLoadMetrotracPaths(fgFile,ni.qto_xyz);

% Draw each path according to a stat
colorVec = {'b' 'k' 'r' 'y'};
statSel = [2:4];
postSum = zeros(length(fg.pathwayInfo),1);
for ss = statSel
    figure;
    for pp = 1:length(fg.pathwayInfo)
        plot((fg.pathwayInfo(pp).point_stat_array(ss,:)),colorVec{mod(pp,length(colorVec))});
        hold on;
        if(ss == 4)
            postSum(pp) = sum(fg.pathwayInfo(pp).point_stat_array(ss,:));
        end
    end
    xlabel('Pathway ID')
    ylabel(char(fg.statHeader(ss).local_name)');
end

disp(postSum);

% Rename raw* files to rawDti*
src_files = dir('raw*');
for ff = 1:length(src_files)
    out_files(ff).name = ['rawDti' src_files(ff).name(4:end)];
end

% Evaluating cross correlation of STT with conTrack
Dirs = {'c:\cygwin\home\sherbond\images\mho040625\conTrack\resamp_LDOCC',
        'c:\cygwin\home\sherbond\images\mho040625\conTrack\resamp_RDOCC',
        'c:\cygwin\home\sherbond\images\md040714\conTrack\resamp_LDOCC',
        'c:\cygwin\home\sherbond\images\md040714\conTrack\resamp_RDOCC',
        'c:\cygwin\home\sherbond\images\bg040719\conTrack\resamp_LDOCC',
        'c:\cygwin\home\sherbond\images\bg040719\conTrack\resamp_RDOCC'};
numShow = 3;
paramOff = 20;
endOff = 16;

for dd = 1:length(Dirs)
    disp(['cd ' Dirs{dd}]);
    cd(Dirs{dd});
    cc = load('cc');
    [foo, ISort] = sort(cc.ccMatrix,'descend');
    for ss = 1:numShow
        disp(['CC: ' num2str(cc.ccMatrix(ISort(ss))) ' Params: ' cc.paramData(ISort(ss)).name(paramOff:end-endOff)]);        
    end
end

% Plot histogram of importance densities
cd c:\cygwin\home\sherbond\images\bg040719
dt6 = load('dt6');
fg = mtrImportFibers('conTrack\paths.dat', dt6.xformToAcPc);
length = fg.params{1}.stat;
score = fg.params{4}.stat;
importance = fg.params{5}.stat;
importance = importance - log(sum(exp(importance)));
prob = fg.params{4}.stat - fg.params{5}.stat;
% score = score;
% prob = prob;
figure;
scatter(score,prob)
ylabel('ln Probability');
xlabel('ln Score');
[foo, iScoreSort] = sort(score,'descend');
[foo, iImpSort] = sort(importance,'descend');
hold on; scatter(score(iScoreSort(1:500)),prob(iScoreSort(1:500)),'or'); hold off;
hold on; scatter(score(iImpSort(1:500)),prob(iImpSort(1:500)),'og'); hold off;

fg_stt = mtrImportFibers('fibers\paths_LDOCC_stt.dat', dt6.xformToAcPc);
lengthSTT = fg_stt.params{1}.stat;
scoreSTT = fg_stt.params{4}.stat;
importanceSTT = fg_stt.params{5}.stat;
importanceSTT = importance - log(sum(exp(importance)));
probSTT = fg_stt.params{4}.stat - fg_stt.params{5}.stat;
[foo, iScoreSTTSort] = sort(scoreSTT,'descend');

%hold on; vline(max(scoreSTT),'-b','Max STT'); hold off;
%axis([ min([min(scoreSTT) min(score)]) max([max(scoreSTT) max(score)]) 0 200 ]);
figure; hist(scoreSTT(iScoreSTTSort(1:end*(0.9))),100); hold on;
h = findobj(gca,'Type','patch');
set(h,'FaceColor','r')
hist(score,100); hold off;
title('Histograms for conTrack scores (blue) and STT scores (red) for RV3AB7d to CC');
ylabel('Count');
xlabel('ln(score)');
axis([ min([min(scoreSTT) min(score)]) max([max(scoreSTT) max(score)]) 0 200 ]);

sttThresh = max(scoreSTT) - min(scoreSTT);
disp(['STT Proposed Thresh: ' num2str(sttThresh)]);
disp(['STT Max: ' num2str(max(scoreSTT))]);
disp(['STT Min: ' num2str(min(scoreSTT))]);


% IS for list vector of iid gaussians
% Bringing the weight to a power < 1 brings the posterior pdf closer to the
% initial pdf, not flattening out the score by itself
vecsize = 2;
sig1 = 1;
sig2 = 0.15;
mean1 = 0;
mean2 = 1;
power = 0.2;

points = randn(vecsize,10000);
score = prod(normpdf(points,mean2,sig2).^power,1);
probgen = prod(normpdf(points,mean1,sig1),1);
weight = score ./ probgen;
[sortScore, sortI] = sort(score,'descend');
[sortScore, sortI] = sort(weight/sum(weight),'descend');
figure;plot(cumsum(weight/sum(weight)));

weight = weight / sum(weight);
t = linspace(-10,10,1000);
[f,xi] = ksdensity(points(1,:),t,'width',0.1,'weights',weight);
% Normalize
%f = f / sum(f);
plot(xi,f);
hold on; plot(xi,normpdf(xi,mean2,sig2).^power,'g'); hold off;
figure; scatter(score,probgen);
xlabel('ln Score');
ylabel('ln Prob');
hold on; scatter(score(sortI(1:200)),probgen(sortI(1:200)),'r'); hold off;

% Check sagittal intersection of fibers
for ff = 1:size(fg_stt.fibers,1)
    pos = fg_stt.fibers{ff}; 
    pos = mrAnatXformCoords(inv(dt6.xformToAcPc), pos')';
    intX(ff) = pos(1,1);    
end
max(intX)
min(intX)

% Toy example to see how long it would take to sample the highest score
% Assume length 70 vector which is average of highest score for RDOCC in
% mho subject
vecsize = 70;
sig1 = 0.1;
sig2 = 0.1;
mean1 = 0;
mean2 = 0;

points = randn(vecsize,100000)*sig1;
score = exp(sum(log(normpdf(points,mean2,sig2)),1));
idealMaxScore = exp(log(normpdf(mean2,mean2,sig2))*vecsize);
% Draw pdf for individual point
figure; hist(points(:),100);
xlabel('Xi');
ylabel('Count');
title('Histogram for one variable');
figure; hist(log(score),100);
hold on; vline(log(idealMaxScore),'g','Max ln(score)'); hold off;
xlabel('ln(score)');
ylabel('Count');
title(['Histogram on score for vector of length ' num2str(vecsize)]);
disp(['Estimated Max: ' num2str(log(max(score)))]);
disp(['Ideal Max: ' num2str(log(idealMaxScore))]);
% CLT predicts 70 length sequence to be normally distributed with mean 62
% and std 6, now lets see how many samples we will need to have a 99%
% chance of seeing a sequence with a score log(score) at most 5 lower than
% the maximum
log(0.01)/log(1-diff(normcdf([log(idealMaxScore)-5 log(idealMaxScore)],62,6)));

% Setting up parameters files for a subject based on ROIs
subjID = 'mod070307';
%localSubjDir = ['/teal/scr1/dti/sisr/' subjID];
localSubjDir = ['/biac2/wandell2/data/reading_longitude/dti_adults/' subjID];
dlhSubjDir = ['/radlab_share/home/tony/images/' subjID];
lappySubjDir = ['c:/cygwin/home/sherbond/images/' subjID];
machineListL = {'deep-lumen1','deep-lumen2','deep-lumen4'};
machineListR = {'deep-lumen5','deep-lumen6','deep-lumen8'};
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params.txt', 'paths.dat', 'ldoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params.txt', 'paths.dat', 'rdoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params.txt', 'paths.dat', 'ldoccRoisMask.nii.gz', 'track_LDOCC.sh', dlhSubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params.txt', 'paths.dat', 'rdoccRoisMask.nii.gz', 'track_RDOCC.sh', dlhSubjDir, machineListR);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params.txt', 'paths.dat', 'ldoccRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params.txt', 'paths.dat', 'rdoccRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListR);


% Plot correlation with regards to length 
cd c:\cygwin\home\sherbond\images\ss040804\conTrack\resamp_LDOCC
threshVec = [2000 1000 500];
strThreshVec = {};
for tt = 1:length(threshVec)
    cc = load(['cc_STT_thresh_' num2str(threshVec(tt)) '.mat']);
    ccGrid = mtrCCMatrix2Grid(cc.ccMatrix,cc.paramData);
    subLenGrid = ccGrid(ccGrid(:,2) == 18 & ccGrid(:,3) == 0.175,:);
    [foo, sortI] = sort(subLenGrid(:,1));
    lenVecs(:,tt) = subLenGrid(sortI(:),1);
    corrVecs(:,tt) = subLenGrid(sortI(:),4);
    strThreshVec{tt} = num2str(threshVec(tt));
end
figure; plot(lenVecs,corrVecs);
legend(strThreshVec);

subjects = {'aab050307','db061209','dla050311','gm050308','me050126','pp050208','rd040630','sp050303'};
left_dist_vec = zeros(length(subjects),1);
right_dist_vec = left_dist_vec;
for ss = 1:length(subjects)
    prev_dir = pwd;
    cd(subjects{ss});
    disp(subjects{ss});
    load('landmarks.mat');
    
    % Get left hemisphere distance
    fg = dtiReadFibers('fibers\LOR_cleaned.mat');
    fibers = [fg.fibers{:}];
    [Y,I] = max(fibers(2,:));
    a = fibers(:,I)';
    left_temporal_dist(ss) = norm(a-left_temporal_pole);
    left_occipital_dist(ss) = norm(a-left_occipital_pole);
    %disp(['left: ' num2str(left_dist_vec(ss))]);
    
    % Right hemisphere distance
    fg = dtiReadFibers('fibers\ROR_cleaned.mat');
    fibers = [fg.fibers{:}];
    [Y,I] = max(fibers(2,:));
    a = fibers(:,I)';
    right_temporal_dist(ss) = norm(a-right_temporal_pole);
    right_occipital_dist(ss) = norm(a-right_occipital_pole);
    %disp(['right: ' num2str(right_dist_vec(ss))]);
    cd(prev_dir);
end

disp('Temporal Distance Analysis');
disp(['mean: ' num2str(mean([left_temporal_dist(:); right_temporal_dist(:)]))]);
disp(['std: ' num2str(std([left_temporal_dist(:); right_temporal_dist(:)]))]);
disp(['max: ' num2str(max([left_temporal_dist(:); right_temporal_dist(:)]))]);
disp(['min: ' num2str(min([left_temporal_dist(:); right_temporal_dist(:)]))]);

disp('Occipital distance Analysis');
disp(['mean: ' num2str(mean([left_occipital_dist(:); right_occipital_dist(:)]))]);
disp(['std: ' num2str(std([left_occipital_dist(:); right_occipital_dist(:)]))]);
disp(['max: ' num2str(max([left_occipital_dist(:); right_occipital_dist(:)]))]);
disp(['min: ' num2str(min([left_occipital_dist(:); right_occipital_dist(:)]))]);



% % Write out anatomy image in a format that SurfRelax can read
% cd ../../t1/;
% ni = niftiRead('rfd_t1anat.nii.gz');
% % ni.qform_code=0;
% % ni.fname = 'anat_forSR.nii.gz';
% % writeFileNifti(ni);
% hdr.voxelsize = ni.pixdim;
% hdr.origin = [-ni.qoffset_x, -ni.qoffset_y, -ni.qoffset_z];
% tfiWriteAnalyze('rfd_t1anat', hdr, ni.data,'float');
% 
% % Xform the surface coordinates into the image space for SurfRelax
% [vAnatomy, vAnatMm, foo, foo] = readVolAnat('/teal/scr1/dti/cortexModelling/rfd040630/anatomy/vAnatomy.dat');
% xformVAnatToAcpc = dtiXformVanatCompute(ni.data, ni.qto_xyz, vAnatomy, vAnatMm);
% cd(fullfile(subjDir, 'anatomy', 'left'));
% msh = mrmLoadOffFile('left.off');
% msh.vertices = mrAnatXformCoords(xformVAnatToAcpc,msh.vertices)';
% mrmSaveOffFile(msh,'leftSR.off');

% View surface with volume viewer and save a genus 0 version of surface

% Run surface optimization code to get all layers of the cortex

% Save separate version of folded cortex in ACPC space



% Inflate and unfold the W/G interface surface




% Labeling mesh vertices



% Convert mesh coordinates into SurfRelax format.
cd(fullfile(subjDir, 'anatomy', 'left'));
msh = meshBuildFromClass('left.class');
msh = meshSmooth(msh);
volfile = fullfile(subjDir,'t1.hdr');
header=tfiReadAnalyzeHeader( volfile );
volumeSize=header.datasize;
volumeAspect=header.voxelsize;
volumeOrigin=header.origin;
coords = msh.vertices;
coords = coords'-1; % 1-offset
%coords = [coords(:,3) volumeSize(2)-1-coords(:,2) volumeSize(3)-1-coords(:,1)];
coords = [coords(:,3) coords(:,2) coords(:,1)];
coords = coords .* repmat( volumeAspect, size(coords,1), 1 );
coords = coords -  repmat( volumeOrigin, size(coords,1), 1 );
msh.vertices = coords';
mrmSaveOffFile(msh,fullfile(subjDir, 'anatomy', 'left','test.off'));


% To get AAL and MNI labels
mni = niftiRead('/home/sherbond/src/VISTASOFT/mrDiffusion/templates/MNI_T1.nii.gz');
t1 = niftiRead('/teal/scr1/dti/cortexModelling/rfd040630/t1/t1.nii.gz');
% Compute the spatial normalization (maps template voxels to image voxels)
sn = mrAnatComputeSpmSpatialNorm(double(t1.data), t1.qto_xyz, mni);
% Invert the spatial norm to map image voxels to template voxels
[defX, defY, defZ] = mrAnatInvertSn(sn);
% Convert the image-to-template defomration to a compact look-up table.
% NOTE: to save space and time, we use int16.
defX(isnan(defX)) = 0; defY(isnan(defY)) = 0; defZ(isnan(defZ)) = 0;
coordLUT = int16(round(cat(4,defX,defY,defZ)));
intentCode = 1006;   % NIFTI_INTENT_DISPVECT=1006
intentName = 'ToMNI';
% NIFTI format requires that the 4th dim is always time, so we put the
% deformation vector [x,y,z] in the 5th dimension.
tmp = reshape(coordLUT,[size(defX) 1 3]);
lutFile = '/teal/scr1/dti/cortexModelling/rfd040630/MNI_coordLUT.nii.gz';
dtiWriteNiftiWrapper(tmp,sn.VF.mat,lutFile,1,'',intentName,intentCode);

% To use the transform:
ni = niftiRead(lutFile);
xform.coordLUT = ni.data;
xform.inMat = ni.qto_ijk;
t1AcpcCoords = [-15.0, -41.0, 52.0]; 
% to use native image-space coords: 
% t1AcpcCoords = mrAnatXformCoords(t1.qto_xyz,[86 31 57]);
mniCoords = mrAnatXformCoords(xform, t1AcpcCoords);
dtiGetBrainLabel(mniCoords, 'MNI_AAL')

% Create ROI of cortex mesh
subjDir = 'c:\cygwin\home\sherbond\data\rfd040630';
cgFile = 'connGraph20070821';
cg = load(fullfile(subjDir,'anatomy',cgFile));
xform = cg.xformVAnatToAcpc;

roiCoords = cg.leftConnGraph.mshFolded.initVertices([2,1,3],:);
roiFile = 'leftCortex';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

roiCoords = cg.rightConnGraph.mshFolded.initVertices([2,1,3],:);
roiFile = 'rightCortex';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

roiCoords = cg.leftSGM.Vertices([2,1,3],:);
roiFile = 'leftSGM';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

roiCoords = cg.rightSGM.Vertices([2,1,3],:);
roiFile = 'rightSGM';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

% Create ROI of left calcarine
roiCoords = cg.leftConnGraph.mshFolded.initVertices([2,1,3],(cg.leftConnGraph.aLabels==43));
roiFile = 'leftCortexCalc';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

% Create ROI from fiber endpoints that are close to leftSGM
pos1Mask = cg.leftSGM.fiberEndInds(1,:)>-1;
pos2Mask = cg.leftSGM.fiberEndInds(2,:)>-1;
roiCoords = [cg.fiberPos1([2,1,3],pos1Mask) cg.fiberPos2([2,1,3],pos2Mask)];
roiFile = 'leftSGMFiberEnds';
roiCoords = mrAnatXformCoords(xform,roiCoords);
roi = dtiNewRoi(roiFile, 'r', roiCoords);
dtiWriteRoi(roi,fullfile(subjDir,'ROIs',roiFile));

% Create image of fiber intersections per left cortex vertex for only
% fibers that intersect leftSGM and left cortex
subjDir = 'c:\cygwin\home\sherbond\data\rfd040630';
cgFile = 'connGraph20070821';
cg = load(fullfile(subjDir,'anatomy',cgFile));
xform = cg.xformVAnatToAcpc;
% Create empty image for output
ni = niftiRead(fullfile(subjDir,'t1','t1.nii.gz'));




% Flip x-axis on nifti image
fname = 'lor_fdt_paths.nii.gz';
ni = niftiRead(fname);
if length(size(ni.data)) == 3
    ni.data = ni.data(end:-1:1,:,:);
elseif length(size(ni.data)) == 4
    ni.data = ni.data(end:-1:1,:,:,:);
else
    error('Not 4d or 3d image file!');
end
writeFileNifti(ni);

% Convert FDT directory data to camino
%fdtDir = 'c:\cygwin\home\sherbond\data\md040714\fdt';
%caminoDir = 'c:\cygwin\home\sherbond\data\md040714\camino';
fdtDir = '/teal/scr1/dti/probtrack_compare/md040714/fdt';
caminoDir = '/teal/scr1/dti/probtrack_compare/md040714/camino';
schemeFile = fullfile(caminoDir,'camino.scheme');
dataFile = fullfile(fdtDir,'data.nii.gz');
dataVoxelFormatFile = fullfile(caminoDir,'data.Bfloat');
bvecsFile = fullfile(fdtDir,'bvecs.camino');
bvalsFile = fullfile(fdtDir,'bvals.camino');
diffusionTime = 0.04;
cmd = sprintf('fsl2scheme -bvalfile %s -bvecfile %s -diffusiontime %g -outputfile %s', bvalsFile, bvecsFile, diffusionTime, schemeFile);
disp(cmd);
[s, ret_info] = system(cmd,'-echo');

disp('Generating voxel format file ...');
data = mtrNiftiToCamino(dataFile,'float', dataVoxelFormatFile);


% Fix dt6 file
baseDir = '/biac2/wandell/data/visualPathway/nv';
baseDir = 'c:\cygwin\home\sherbond\data';
subjDirs = {'aab050307', 'db061209', 'gm050308', 'me050126', 'pp050208', 'sp050303'};
ogDir = pwd;
for dd=1:length(subjDirs)
    disp(['Fixing dt6 for subject: ' subjDirs{dd} ' ...']);
    dirName = fullfile(baseDir,subjDirs{dd},'dti06');
    cd(dirName);
    dt6 = load('dt6');
    if isfield(dt6.files,'homeDir'); dt6.files = rmfield(dt6.files,'homeDir'); end
    if isfield(dt6.files,'binDir'); dt6.files = rmfield(dt6.files,'binDir'); end
    fieldList = fieldnames(dt6.files);
    for ff=1:length(fieldList)
        [p,f,ext] = fileparts(getfield(dt6.files,fieldList{ff}));
        fileName = [f ext];
        dt6.files = setfield(dt6.files,fieldList{ff},fullfile('dti06','bin',fileName));
    end
    dt6.files.t1 = 't1/t1.nii.gz';
    save dt6.mat -struct dt6;
end
cd(ogDir);

% Create a directory for each voxel for separate FDT runs
%bedpostDir = 'c:\cygwin\home\sherbond\data\md040714\fdt.bedpost';
bedpostDir = '/teal/scr1/dti/probtrack_compare/md040714/fdt.bedpost';
fdtpathsFile = fullfile(bedpostDir,'rmt-cc-hemBound','fdt_paths.nii.gz');
xNum = 41;
ni = niftiRead(fdtpathsFile);
slice = squeeze(ni.data(xNum,:,:));
[y,z] = ind2sub(size(slice),find(slice>10));
x = ones(size(y))*xNum;
coords = [x y z]-1;
% Additional coordinates from RMT
coords(end+1:end+5,:) = [ 56 32 33;
                          56 29 35;
                          56 30 35;
                          56 29 36;
                          56 30 36 ];
% Make script
fid = fopen(fullfile(bedpostDir,'splSimple.sh'),'wt');
fprintf(fid,'#!/bin/bash\n');
for cc = 14:size(coords,1)
    outDir = ['splSimple' num2str(cc)];
    mkdir(fullfile(bedpostDir,outDir));
    dlmwrite(fullfile(bedpostDir,outDir,'coordinates.txt'),coords(cc,:),'delimiter',' ');
    fprintf(fid,'echo ''Computing seed %g''\n',cc);
    tealDir = '/teal/scr1/dti/probtrack_compare/md040714/fdt.bedpost/';
    outFile = fullfile(tealDir,outDir,outDir);
    brainMaskFile = fullfile(tealDir,'nodif_brain_mask');
    dataFile = fullfile(tealDir,'merged');
    fprintf(fid,'probtrack --mode=simple -x %s/coordinates.txt --forcedir -s %s -m %s -V 2 -l -c 0.2 -S 2000 --steplength=0.5 -P 5000 -o %s &\n',outDir,dataFile,brainMaskFile,outFile);
end
fclose(fid);

% Collect multiple FDT run fibers into one fiber group
%partParentDir = 'C:\cygwin\home\sherbond\data\md040714\fdt.bedpost';
partParentDir = '/teal/scr1/dti/probtrack_compare/md040714/fdt.bedpost';
outFile = fullfile('splSimple','splSimple2.mat');
ni = niftiRead(fullfile(partParentDir,'mean_fsamples.nii.gz'));
xform = ni.qto_xyz;
partDirs = dir(fullfile(partParentDir,'particle*'));
fg = [];
for pp=14:length(partDirs)
    if(isempty(fg))
        fg = dtiLoadFDTPaths(fullfile(partParentDir,partDirs(pp).name),xform); 
    else
        fgtemp = dtiLoadFDTPaths(fullfile(partParentDir,partDirs(pp).name),xform); 
        fg.fibers = {fg.fibers{:} fgtemp.fibers{:}}';
    end
end
dtiWriteFiberGroup(fg,fullfile(partParentDir,outFile));

% Rip out extra newlines from file
outDir = 'c:\cygwin\home\sherbond\src\connGraphTemp';
inDir = 'c:\cygwin\home\sherbond\src\connGraph';
inFiles = dir(inDir);
for ff = 1:length(inFiles)
    if ( ~isdir(fullfile(inDir,inFiles(ff).name)) )
        fileName = fullfile(inDir,inFiles(ff).name);
        fid = fopen(fileName,'r');
        text = {};
        while 1
            tline = fgetl(fid);
            if ~ischar(tline),   break,   end
            text{end+1} = tline;
        end
        fclose(fid);

        fileName = fullfile(outDir,inFiles(ff).name);
        fid = fopen(fileName,'w');
        for ll = 1:3:length(text)
            fprintf(fid,'%s\n',text{ll});
        end
        fclose(fid);
    end
end

% Create exclusion mask from fiber group
subjDir = 'c:\cygwin\home\sherbond\data\DL070825_anatomy';
binDir = fullfile(subjDir,'dti60','bin');
fiberDir = fullfile(subjDir,'fibers','conTrack');
xFile = 'lorX1Mask.nii.gz';
countThresh = 20;
fg = mtrImportFibers(fullfile(fiberDir,'resampL_kSmooth_18_kLength_0_kMidSD_0.175.pdb'),eye(4));
niWay = niftiRead(fullfile(binDir,'lorWayMask.nii.gz'));
fdImg = dtiComputeFiberDensityNoGUI(fg, niWay.qto_xyz, size(niWay.data), 1, 0, 0);
fdImg(fdImg<countThresh) = 0;
fdImg(fdImg>0) = 1;
fdImg(niWay.data == 0) = 0;
dtiWriteNiftiWrapper(uint8(fdImg),ni.qto_xyz,fullfile(binDir,xFile));

% Plot Score vs. Length for fiber group
fgName = 'allL_kSmooth_18_kLength_-2_kMidSD_0.175.pdb';
hold on;
fgName = 'resampLCC_kSmooth_18_kLength_-2_kMidSD_0.175.pdb';
fgName = 'resampLG_kSmooth_18_kLength_-2_kMidSD_0.175.pdb';
fg = mtrImportFibers(fgName,eye(4));
len = zeros(length(fg.fibers),1);
for ff=1:length(fg.fibers)
    len(ff) = length(fg.fibers{ff})-1;
end
figure; scatter(len,fg.params{1}.stat,'g');

legend('1','2','3');

% Combine left/right CC fiber estimates
distThresh = 3;
%subjDir = 'C:\cygwin\home\sherbond\data\rfd040630';
subjDir = '/teal/scr1/dti/cortexModelling/rfd040630';
leftFGName = 'lCCPaths.mat';
rightFGName = 'rCCPaths.mat';
leftFG = dtiReadFibers(fullfile(subjDir,'fibers',leftFGName));
rightFG = dtiReadFibers(fullfile(subjDir,'fibers',rightFGName));
combFG = dtiNewFiberGroup();
combFG.name = 'combCC';
combFG.colorRgb = [200 200 100];
for ff1=1:length(leftFG.fibers)
    lPathway = leftFG.fibers{ff1};
    lP = lPathway(:,end);
    for ff2=1:length(rightFG.fibers)
        rPathway = rightFG.fibers{ff2};
        rP = rPathway(:,end);
        % Create pathway joining hemispheres if distance on YZ plane is
        % small enough
        if norm(rP(2:3)-lP(2:3)) < distThresh
            combFG.fibers{end+1} = [lPathway(:,1) rPathway(:,1)];
        end
    end
end
dtiWriteFiberGroup(combFG,fullfile(subjDir,'fibers',[combFG.name '.mat']));


% Generate Brodmann maps and save as SMAT
subjDir = 'C:\cygwin\home\sherbond\data\rfd040630';
cg = load(fullfile(subjDir,'anatomy','connGraph20070911.mat'));
BrodMap = cgGetBLabelMap(cg);
smatFileName = fullfile(subjDir,'anatomy','fiberTBMap.smat');
cgLabelMap2SMAT(BrodMap,smatFileName);

% Generate partition and permutation vectors for visualization of matrices
permFileName = fullfile(subjDir,'anatomy','lobeTPermute.vec');
partFileName = fullfile(subjDir,'anatomy','lobeTPartition.vec');
cgGenBrodPermPart(permFileName,partFileName);

% Load camino tracks and save them as mrDiffusion FG (only endpoints and
% length of the path though)
subjDir = 'C:\cygwin\home\sherbond\data\rfd040630';
niT1 = niftiRead(fullfile(subjDir,'t1','t1.nii.gz'));
fgRoot = 'lHem10IConnected1';
camFile = fullfile(subjDir,'camino','tracks',[fgRoot '.Bfloat']);
fg = mtrImportFibers(camFile,inv(niT1.qto_xyz),0);
fgFile = fullfile(subjDir,'fibers',[fgRoot '.mat']);
dtiWriteFiberGroup(fg,fgFile);

% Compute OR stats
subjs = {'aab','as','ah','db','dla','gm','jy','me'};
lTempP = [19,21,23,28,24,18,21,19];
rTempP = [20,19,25,27,21,19,25,17];
lOccP = -[96,100,107,103,107,106,103,100];
rOccP = -[96,99,107,102,109,104,101,100];
lLVTH = [-8,-15,-10,-8,-10,-15,-5,-13];
rLVTH = [-5,-13,-7,-7,-9,-11,-4,-12];
lORK = [-6,-9,-6,-6,-7,-7,-3,-11];
rORK = [-4,-10,1,-2,-10,-7,-4,-10];

% Temp Pole to OR Knee
lTOd = abs(lTempP - lORK);
rTOd = abs(rTempP - rORK);
TOd = [lTOd rTOd];
avgTOd = mean(TOd)
stdTOd = std(TOd)
maxTOd = max(TOd)
minTOd = min(TOd)
% Occ. Pole to OR Knee
lOOd = abs(lOccP - lORK);
rOOd = abs(rOccP - rORK);
OOd = [lOOd rOOd];
avgOOd = mean(OOd)
stdOOd = std(OOd)
maxOOd = max(OOd)
minOOd = min(OOd)
% Temp Pole to Lat. Vent. Temp. Horn
lTLd = abs(lTempP - lLVTH);
rTLd = abs(rTempP - rLVTH);
TLd = [lTLd rTLd];
avgTLd = mean(TLd)
stdTLd = std(TLd)
maxTLd = max(TLd)
minTLd = min(TLd)
% OR Knee to Lat. Vent. Temp. Horn
lOLd = lORK - lLVTH;
rOLd = rORK - rLVTH;
OLd = [lOLd rOLd];
avgOLd = mean(OLd)
stdOLd = std(OLd)
maxOLd = max(OLd)
minOLd = min(OLd)

% See how the OR paths cluster
% 1. Load up all the fiber groups into one fiber group
subjDir = 'C:\cygwin\home\sherbond\data\jy060309';
%fgNames = {'LOR_meyer', 'Lbad_AntThal', 'Lbad_CC', 'Lbad_InfMisc', 'LOR_direct', 'Lbad_Par'};
fgNames = {'LOR_meyer', 'Lbad_AntThal', 'Lbad_CC', 'Lbad_InfMisc'};

fg = dtiNewFiberGroup;
grpSizes = [];
fg.fibers={};
for ii=1:length(fgNames)
    fgTemp = mtrImportFibers(fullfile(subjDir,'fibers','conTrack',[fgNames{ii} '.pdb']), eye(4));
    grpSizes(ii) = length(fgTemp.fibers); %#ok<AGROW>
    fg.fibers(end+1:end+grpSizes(ii)) = fgTemp.fibers;
end

% 2. Compute Housdorff distance matrices for all fibers
[meanDistMatrix, maxDistMatrix] = mtrComputeFiberDistMatrix(fg);

% 3. Use MDS to see if we have good separation between these groups
[Ymean] = mdscale(meanDistMatrix,3);
[Ymax] = mdscale(maxDistMatrix,3);

% 4. Do nystrom cuts
D=maxDistMatrix;
labels=ndTony(D,5,round(0.2*length(D)),length(fgNames)+2,100,0.0);

% 5. Plot the MDS results
Y = Ymax;
figure;
scatter3(Y(:,1),Y(:,2),Y(:,3),10,labels);

figure;
for gg=1:length(fgNames)
    if gg==1
        start_off = 0;
    else
        start_off = grpSizes(gg-1);
    end
    FIDs = start_off+1:start_off+grpSizes(gg);
    scatter3(Y(FIDs,1),Y(FIDs,2),Y(FIDs,3),10);
    hold on;
end
hold off;


% Find total time to some number of paths per vertex
%subjDir = 'C:\cygwin\home\sherbond\data\me05012';
subjDir = '/teal/scr1/dti/or/me050126';
pathsDir = 'fibers/conTrack/bg';
imgDir = 'dti06/bin';
pathsRoot = fullfile(subjDir,pathsDir,'paths_rbb_*.Bfloat');
startVoxelMaskFile = fullfile(subjDir,imgDir,'allGM_CC_allstart.nii.gz');
outFile = fullfile(subjDir,imgDir,'allGM_CC_allstart_lengthyMaskR.nii.gz');
conMaskLengthyStartVoxels(outFile,startVoxelMaskFile,pathsRoot);

% Segment OR
% Iterate over all subjects
wDir = 'C:\cygwin\home\sherbond\data';
%subjDirs = {'aab050307', 'ah051003', 'as050307', 'db061209', 'dla050311', 'gm050308', 'jy060309', 'me050126'};
subjDirs = {'aab050307', 'ah051003', 'as050307'};
%pathFiles = {'LOR.Bfloat','ROR.Bfloat'};
meyerOffset = 4;
centralOffset = 2;
nEarlyCentralSteps = 15;
nEarlyAntSteps = 20;
for ss = 3:length(subjDirs)
    curDir = fullfile(wDir,subjDirs{ss});
    % Load some diffusion data
    niWMProb = niftiRead(fullfile(curDir,'dti06','bin','wmProb.nii.gz'));
    xformToAcpcDTI = niWMProb.qto_xyz;
    %niT1 = niftiRead(fullfile(curDir,'t1','t1.nii.gz'));
    xformFromMmToAcpc = xformToAcpcDTI;
    xformFromMmToAcpc(1,1)=1; xformFromMmToAcpc(2,2)=1; xformFromMmToAcpc(3,3)=1;
    % For left (hh==1) and right (hh==2)
    for hh = 1:2       
        if hh==1
            prefixROI = 'LOR';
            % Load parameters file
            paramsFile = fullfile(curDir,'fibers','conTrack','met_params_llgn.txt');
            display(['Processing ' subjDirs{ss} ' LOR.Bfloat ...']);
        else
            prefixROI = 'ROR';
            % Load parameters file
            paramsFile = fullfile(curDir,'fibers','conTrack','met_params_rlgn.txt');
            display(['Processing ' subjDirs{ss} ' ROR.Bfloat ...']);
        end        
%         if(ss==3 && hh==2)
%             centralOffset = 4;
%         else
%             centralOffset = origCentralOffset;
%         end
        ctParams = mtrLoad(paramsFile,xformToAcpcDTI);
        % Get LGN ROI
        lgnROI = mtrGet(ctParams,'roi',1,'coords');
        % Load all pathways of the OR
        maxLength = mtrGet(ctParams,'max_nodes');
        [pathways pathLengthVec statsVec] = dtiLoadCaminoPathsMatrix(fullfile(curDir,'fibers','conTrack','or_clean',[prefixROI '.Bfloat']),xformFromMmToAcpc,maxLength);
        statsNames = {'Length','log(Q)', 'Avg. log(Q)'};
        % Because we trace symmetrically, we need to see if we have to flip
        % any paths
        startAP = squeeze(pathways(2,1,:));
        endAP = squeeze(pathways(2,end,:));
        diffAP = startAP - endAP;
        pathways(:,:,diffAP<0) = pathways(:,end:-1:1,diffAP<0);
        
        % Apply score threshold
        % Find Meyer's Loop bundle
        earlyAntSteps = squeeze(pathways(2,1:min([pathLengthVec'; nEarlyAntSteps]),:));
        % Meyer loop is anything 6mm more anterior than the lgnROI
        %meyerCheck = any(earlyAntSteps > max(lgnROI(:,2))+meyerOffset,1);
        meyerCheck = (squeeze(max(pathways(2,:,:))) > max(lgnROI(:,2))+meyerOffset);
        % Find central bundle
        earlyLatSteps = squeeze(pathways(1,1:min([pathLengthVec'; nEarlyCentralSteps]),:));
        % Central loop is anything 8mm more lateral than the lgnROI, but
        % not Meyer's loop
        pointsAntWithLGN = squeeze(pathways(2,:,:) < max(lgnROI(:,2)) & pathways(2,:,:) > min(lgnROI(:,2)));
        latPositions = squeeze(pathways(1,:,:));
        if hh==1
            %centralCheck = any(earlyLatSteps < min(lgnROI(:,1)-centralOffset),1);
            latPositions(~pointsAntWithLGN) = max(latPositions(:)); 
            centralCheck = squeeze(min(latPositions)) <= min(lgnROI(:,1))-centralOffset;
        else
            %centralCheck = any(earlyLatSteps > max(lgnROI(:,1)+centralOffset),1);
            latPositions(~pointsAntWithLGN) = min(latPositions(:)); 
            centralCheck = squeeze(max(latPositions)) >= max(lgnROI(:,1))+centralOffset;
        end
        centralCheck = centralCheck(:) & ~meyerCheck(:);
        % Find direct bundle
        directCheck = ~centralCheck(:) & ~meyerCheck(:);
        
        % Save out separate pathways with different color for each bundle
        disp(['Saving ' num2str(sum(meyerCheck)) ' in Meyer bundle.']);
        outFileName = fullfile(curDir,'fibers','conTrack','or_clean',[prefixROI '_meyer_final.pdb']);
        mtrExportFibersFromMatrix(pathways(:,:,meyerCheck), pathLengthVec(meyerCheck), statsVec(2:3,meyerCheck), statsNames(2:3), outFileName, eye(4));
        
        disp(['Saving ' num2str(sum(centralCheck)) ' in central bundle.']);
        outFileName = fullfile(curDir,'fibers','conTrack','or_clean',[prefixROI '_central_final.pdb']);
        mtrExportFibersFromMatrix(pathways(:,:,centralCheck), pathLengthVec(centralCheck), statsVec(2:3,centralCheck), statsNames(2:3), outFileName, eye(4));
        
        disp(['Saving ' num2str(sum(directCheck)) ' in direct bundle.']);
        outFileName = fullfile(curDir,'fibers','conTrack','or_clean',[prefixROI '_direct_final.pdb']);
        mtrExportFibersFromMatrix(pathways(:,:,directCheck), pathLengthVec(directCheck), statsVec(2:3,directCheck), statsNames(2:3), outFileName, eye(4));
    end
end

% Look at tensor properties of voxels with high linearity across all subjects
clThresh = 0.25;
wDir = 'C:\cygwin\home\sherbond\data';
evStatsFile = 'evStats.mat';
evStats = load(fullfile(wDir,evStatsFile));
subjDirs = evStats.subjDirs;
ldPool = [];
rdPool = [];
clPool = [];
for ss=1:length(subjDirs)
    curDir = fullfile(wDir,subjDirs{ss});
    fiberDir = fullfile(curDir,'fibers','conTrack','or_clean');
    dt = dtiLoadDt6(fullfile(curDir,'dti06','dt6.mat'));
    [eigVec, eigVal] = dtiEig(dt.dt6);
    disp(['Computing eigen values for ' subjDirs{ss} ' ...']);
    [cl, cp, cs] = dtiComputeWestinShapes(eigVal);
    eigValPool=[];
    for ii=1:3
        temp = eigVal(:,:,:,ii);
        eigValPool(:,ii) = temp(cl>clThresh);
    end
    [fa,md,rd] = dtiComputeFA(eigValPool);
    ld = eigValPool(:,1);
    clPool(end+1:end+length(cl(cl>clThresh))) = cl(cl>clThresh);
    ldPool(end+1:end+length(ld)) = ld;
    rdPool(end+1:end+length(rd)) = rd;
end

%Plot diffusivity parameters vs. clThresh
ldMeans = [];
ldStds = [];
rdMeans = [];
rdStds = [];
clList = [];
clSizes = [];
for cc=0.25:0.05:1
    clPass = clPool(clPool>cc);
    if length(clPass) < 10
        break;
    end
    ldMeans(end+1) = mean(ldPool(clPool>cc));
    ldStds(end+1) = std(ldPool(clPool>cc));
    rdMeans(end+1) = mean(rdPool(clPool>cc));
    rdStds(end+1) = std(rdPool(clPool>cc));
    clList(end+1) = cc;
    clSizes(end+1) = length(clPass);
end

figure;
subplot(2,2,1); plot(clList,ldMeans); 
subplot(2,2,2); plot(clList,ldStds,'r');
subplot(2,2,3); plot(clList,rdMeans); 
subplot(2,2,4); plot(clList,rdStds,'r');
figure; plot(clList,clSizes);
disp(['All voxels: '  num2str(ldMeans(4)) ', ' num2str(rdMeans(4))]);

% Generate colorbar for linearity values in DTIQuery
greenRGB = [77/255, 175/255, 74/255];
greenHSV = rgb2hsv(greenRGB);
gCMAP = repmat(greenHSV,[length(0:0.01:1) 1]);
gCMAP(:,3) = 0:0.01:1;
gCMAP = hsv2rgb(gCMAP);
mrUtilMakeColorbar(gCMAP,{'0','0.3','0.6'});
title('Linearity');

% Generate colorbar for density images
mrUtilMakeColorbar(hot,{'0','1x','2x','3x','4x','5x','6x','7x','8x','9x','10x','11x','12x'});
mrUtilMakeColorbar(hot,{'0','1x','2x','3x','4x','5x'});

% Generate gaussian surfaces to go with axial distribution figures
[X,Y] = meshgrid(-3:.125:3);
S = [1 0; 0 4];
Z = 1./((2*pi)*det(S)^0.5).* exp(-( (X.^2)/S(1) + (Y.^2)/S(4))/2 );
%Z = peaks(X,Y);
h = surf(X,Y,Z);
%colormap([60/255 120/255 12/255]);
colormap hot;
%shading faceted;
%set(h,'FaceLighting','phong','FaceColor','interp','AmbientStrength',0.5);
%light('Position',[1 0 0],'Style','infinite');
caxis([0 0.14]);
grid off
set(gca,'XTick',[])
set(gca,'YTick',[])
set(gca,'ZTick',[])
axis([-3 3 -3 3 0 0.2])

% Display OR measurements vs dissection and STT
methodsL = {'Dissection','ConTrack','STT (2007)','STT (2005)'};
tps = [27, 28, 44, 37];
tpsE =[3.5,3,4.9,2.5];
ops = [98,96,0,82];
opsE =[6.2,5.5,0,3];
vhs = [5,3,-15,-4];
vhsE = [3.2,2.6,4,0.2];
figure;
subplot(3,1,1);
bar(1:4,tps,0.5);
hold on;
errorbar(1:4,tps, tpsE,'.r');
set(gca,'XTickLabel',methodsL)
yLabel('Dist. to Temp. Pole (mm)');
ylim([20 60]);

subplot(3,1,2);
bar(1:4,ops,0.5);
hold on;
errorbar(1:4,ops, opsE,'.r');
set(gca,'XTickLabel',methodsL)
yLabel('Dist. to Occ. Pole (mm)');
ylim([70 110]);

subplot(3,1,3);
bar(1:4,vhs,0.5);
hold on;
errorbar(1:4,vhs, vhsE,'.r');
set(gca,'XTickLabel',methodsL)
yLabel('Loc. to Temp. Horn (mm)');
ylim([-20 20]);

tenfile1 = 'tensors.nii.gz';
tenfile2 = 'tensorsFlip.nii.gz';
ni = niftiRead(tenfile1);
% We convert from the 5d, lower-tri row order NIFTI tensor format
% (Dxx Dxy Dyy Dxz Dyz Dzz) to our 4d tensor format
% (Dxx Dyy Dzz Dxy Dxz Dyz).
dt6 = double(squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])));

[eigVec, eigVal] = dtiSplitTensor(dt6);
eigVec(:,:,:,2,:) = -eigVec(:,:,:,2,:);
dt6 = dtiRebuildTensor(eigVec, eigVal);
% Now convert back to file format
ni.data(:,:,:,1,:) = dt6(:,:,:,[1 4 2 5 6 3]);
ni.fname = tenfile2;
writeFileNifti(ni);

% Avg the raw file down to independent parts
ni = niftiRead('dti_g13_b800_aligned.nii.gz');
bvals = load('dti_g13_b800_aligned.bvals','-ascii');
bvecs = load('dti_g13_b800_aligned.bvecs','-ascii');
ni.fname = 'dti_g13_b800_aligned_avg.nii.gz';
nD = 13;
avg_bvals = bvals(1:nD);
avg_bvecs = bvecs(:,1:nD);
ndata = ni.data(:,:,:,1:nD);
for ii=1:nD
    avg_bvecs(:,ii) = mean(bvecs(:,ii:nD:end),2);
    ndata(:,:,:,ii) = mean(ni.data(:,:,:,ii:nD:end),4);
end
ni.data = ndata;
writeFileNifti(ni);
fid = fopen('dti_g13_b800_aligned_avg.bvals','wt');
fprintf(fid, '%1.3f ', avg_bvals); fclose(fid);
fid = fopen('dti_g13_b800_aligned_avg.bvecs','wt');
fprintf(fid, '%1.3f ', avg_bvecs(1,:)); fprintf(fid, '\n'); 
fprintf(fid, '%1.3f ', avg_bvecs(2,:)); fprintf(fid, '\n');
fprintf(fid, '%1.3f ', avg_bvecs(3,:)); fclose(fid);


% Setup cross-validation files
cvdir = 'cv_train40';
fileRoot = 'dti_g86_b900_aligned';
nD = 43;
ni = niftiRead([fileRoot '.nii.gz']);
raw = ni.data;
bvals = load([fileRoot '.bvals'],'-ascii');
bvecs = load([fileRoot '.bvecs'],'-ascii');
%ni.fname = 'dti_g13_b800_aligned_avg.nii.gz';
if round(length(bvals)/nD) ~= length(bvals)/nD error('Number of directions is wrong!'); end

nRepeats = length(bvals)/nD;
cd(cvdir);
for ii = 1:nRepeats        
    disp(['Setting up ' num2str(ii) ' of ' num2str(nRepeats) '...']);
    ni.fname = ['loo' num2str(ii) '.nii.gz'];
    off1 = (ii-1)*nD; off2 = off1+nD+1;
    ni.data = cat(4,raw(:,:,:,1:off1),raw(:,:,:,off2:end)); 
    loobvecs = cat(2,bvecs(:,1:off1),bvecs(:,off2:end));
    loobvals = [bvals(:,1:off1), bvals(:,off2:end)];
    writeFileNifti(ni);
    fid = fopen(['loo' num2str(ii) '.bvals'],'wt');
    fprintf(fid, '%1.3f ', loobvals); fclose(fid);
    fid = fopen(['loo' num2str(ii) '.bvecs'],'wt');
    fprintf(fid, '%1.3f ', loobvecs(1,:)); fprintf(fid, '\n'); 
    fprintf(fid, '%1.3f ', loobvecs(2,:)); fprintf(fid, '\n');
    fprintf(fid, '%1.3f ', loobvecs(3,:)); fclose(fid);
end
cd('..');

% Write out 2:7 raw and predicted images for figure
figDir = '/Users/sherbond/Documents/Mine/HBM2009';
rawDir = '/Users/sherbond/data/mho070519/raw';
pDir = '/Users/sherbond/data/mho070519/dti06/fibers/pids_modelLHnewvol2_d0.2';
binDir = '/Users/sherbond/data/mho070519/dti06/bin';

vol = niftiRead(fullfile(binDir,'b0.nii.gz'));
raw = niftiRead(fullfile(rawDir,'dti_g13_b800_aligned_avg.nii.gz'));
p = niftiRead(fullfile(pDir,'p.nii.gz'));

X = 24;
for ll=2:2:13
    sr = squeeze(raw.data(X,:,:,ll))';
    sp = squeeze(p.data(X,:,:,ll))';
    figure; imagesc(sr(end-1:-1:1,:)); colormap gray; caxis([0 1000])
    mrUtilPrintFigure(fullfile(figDir,['r' num2str(ll) '.png']), gcf, 300);
    figure; imagesc(sp(end-1:-1:1,:)); colormap gray; caxis([0 1000])
    mrUtilPrintFigure(fullfile(figDir,['p' num2str(ll) '.png']), gcf, 300);
end
close all;



% Interesting voxels for lh7233 paths through mho07
vox = [380890 389396 389477 397902 397983 414913 440510 449016 457521];
alg = 'T7233';
w = 0;
d = 0.1;
cd(['pids_lh' alg '_w' num2str(w) '_d' num2str(d)]);
e = niftiRead('e.nii.gz');
f = niftiRead('f.nii.gz');
d = niftiRead('d.nii.gz');
mean(f.data(vox))
mean(e.data(vox))
cd('..');

% Create WM mask and GM mask from ROI file for FascTrack
wmFile = 'roiLeftTP.nii.gz';
gmFile = 'gmLeftTP.nii.gz';
niWM = niftiRead(wmFile);
niGM = niWM;
niGM.fname = gmFile;
niGM.data = zeros(size(niGM.data));
sP = []; eP = [];
sP(1) = find(squeeze(max(max(niWM.data,[],2),[],3))>0,1,'first');
sP(2) = find(squeeze(max(max(niWM.data,[],1),[],3))>0,1,'first');
sP(3) = find(squeeze(max(max(niWM.data,[],1),[],2))>0,1,'first');
eP(1) = find(squeeze(max(max(niWM.data,[],2),[],3))>0,1,'last');
eP(2) = find(squeeze(max(max(niWM.data,[],1),[],3))>0,1,'last');
eP(3) = find(squeeze(max(max(niWM.data,[],1),[],2))>0,1,'last');
niGM.data(sP(1):eP(1),sP(2):eP(2),sP(3))=1;
niGM.data(sP(1):eP(1),sP(2):eP(2),eP(3))=1;
niGM.data(sP(1):eP(1),sP(2),sP(3):eP(3))=1;
niGM.data(sP(1):eP(1),eP(2),sP(3):eP(3))=1;
niGM.data(sP(1),sP(2):eP(2),sP(3):eP(3))=1;
niGM.data(eP(1),sP(2):eP(2),sP(3):eP(3))=1;
writeFileNifti(niGM);

% Text parsing
fid = fopen('UltraVX_charge.txt');
vCharges = zeros(1,10000);
tline = fgetl(fid);
count = 0;
while tline ~= -1
%while count < 9
    % Skip two more
    count = count+1;
    if(count == 10)
        fgetl(fid);
        tline = fgetl(fid);
        d = sscanf(tline,'%*s %*s $%f %*c');
    else
        fgetl(fid); fgetl(fid);
        tline = fgetl(fid);
        d = sscanf(tline,'%*s %*s %*s $%f %*c');
    end
    
    vCharges(count) = d;
    tline = fgetl(fid);
end
fclose(fid);

% Total payments
vPay = [1200 1100 400 600 200];
sum(vPay)

% Total fees
vFee = [4.04 15.42 2.91 10.59 6.95 6.95 6.95];
sum(vFee)

% Convert bvals and bvecs into trackvis grad table and get b=0 measurements
% in front of data.
rootFilename = 'dwi_noisy';
bvals = load([rootFilename '.bvals'],'-ascii');
bvecs = load([rootFilename '.bvecs'],'-ascii');
data = niftiRead([rootFilename '.nii.gz']);

% Get b0 to the front of the data
bvecs = cat(2, bvecs(:,bvals==0), bvecs(:,bvals~=0));
data.data = cat(4, data.data(:,:,:,bvals==0), data.data(:,:,:,bvals~=0));
bvals = [bvals(bvals==0) bvals(bvals~=0)];

% Write out trackvis grad table file and data
numb0 = sum(bvals==0);
dlmwrite([rootFilename '_trackvis_grad.txt'],bvecs(:,numb0+1:end)', ',');
data.fname = [rootFilename '_trackvis.nii.gz'];
writeFileNifti(data);

% Upsample imgs
imgFilenameRoot = 'recon_out_file_max';
imgFilenameIn = [imgFilenameRoot '.nii'];
imgFilenameOut = [imgFilenameRoot '_2up.nii'];
upFactor = 2;
img = niftiRead(imgFilenameIn);
img.fname = imgFilenameOut;
m = img.qto_xyz;
m(1:3,1:3) = m(1:3,1:3)/upFactor;
img = niftiSetQto(img,m);
newdata = zeros([[size(img.data,1), size(img.data,2), size(img.data,3)]*upFactor size(img.data,4)]);

for kk=1:size(newdata,3)
    for jj=1:size(newdata,2)
        for ii=1:size(newdata,1)
            cii = ceil(ii/upFactor);
            cjj = ceil(jj/upFactor);
            ckk = ceil(kk/upFactor);
            newdata(ii,jj,kk,:) = img.data(cii,cjj,ckk,:);
        end
    end
end
img.data = newdata;
writeFileNifti(img);

% Read one image ROI into the format of another
niIn = niftiRead('t1_class.nii.gz');
niOut = niftiRead('../dti30/bin/b0.nii.gz');
niOut.fname = 'b0_locc.nii.gz';
niIn.data(niIn.data~=3) = 0;
niIn.data(niIn.data>0) = 1;

% Get the ROI 
[I,J,K] = ind2sub(size(niIn.data),find(niIn.data));
t1Coords = [I J K];
t12ACPC = niIn.qto_xyz;
t12ACPC(1:3,1:3) = abs(t12ACPC(1:3,1:3));
acpcCoords = mrAnatXformCoords(t12ACPC, t1Coords);

% Put the ROI in the given size image
b0Coords = round(mrAnatXformCoords(niOut.qto_ijk, acpcCoords));
b0Coords = unique(b0Coords,'rows');
%obInds = any(b0Coords<1,2);
%b0Coords = b0Coords(~obInds);

niOut.data(:) = 0;
niOut.data(sub2ind(size(niOut.data),b0Coords(:,1),b0Coords(:,2),b0Coords(:,3))) = 1;
writeFileNifti(niOut);


loccROI = dtiReadRoi('locc.mat');
b0 = niftiRead('../bin/b0.nii.gz');
imgCoords = mrAnatXformCoords(b0.qto_ijk, loccROI.coords);
b0.fname = 'locc.nii.gz';
b0.data(:) = 0;
b0.data(imgCoords) = 1;


% Convert NFG grad file to ours
grad = load('grad_directions.txt','-ascii');
bvals = grad(:,4);
bvecs = grad(:,1:3)';
% Write out bvals
fid = fopen('grad.bvals','wt');
fprintf(fid, '%1.3f ', bvals); fclose(fid);
fid = fopen('grad.bvecs','wt');
fprintf(fid, '%1.4f ', bvecs(1,:)); fprintf(fid, '\n'); 
fprintf(fid, '%1.4f ', bvecs(2,:)); fprintf(fid, '\n');
fprintf(fid, '%1.4f ', bvecs(3,:)); fclose(fid);

% Label points on sphere surface as GM for NFG phantom
vol = niftiRead('b0.nii.gz');
gm = vol; gm.fname = 'gm.nii.gz';
wm = vol; wm.fname = 'wm.nii.gz';
gm.data(:) = 0;
wm.data(:) = 0;
for kk=1:size(wm.data,3)
    for jj=1:size(wm.data,2)
        for ii=1:size(wm.data,1)
            v = [ii,jj,kk]/(size(gm.data,1)/2) - 1 ;
            if norm(v) <= 1
                wm.data(ii,jj,kk) = 1;
                if norm(v) > 0.85
                    gm.data(ii,jj,kk) = 1;
                end
            end
        end
    end
end
writeFileNifti(wm);
writeFileNifti(gm);

% Create left and right Occ masks for jw
seg = niftiRead('seg.nii.gz');
seg.data(:,28:end,:)=0;
seg.data(:,28,:) = 2;
lgm = seg;
lwm = seg;
rgm = seg;
rwm = seg;
lgm.fname = 'lOccGM.nii.gz';
lwm.fname = 'lOccWM.nii.gz';
rwm.fname = 'rOccWM.nii.gz';
rgm.fname = 'rOccGM.nii.gz';
lwm.data(40:end,:,:) = 0;
lgm.data(40:end,:,:) = 0;
lgm.data(lgm.data==1) = 0;
lwm.data(lwm.data>0) = 1;
lgm.data(lgm.data>0) = 1;
rwm.data(1:40,:,:) = 0;
rgm.data(1:40,:,:) = 0;
rgm.data(rgm.data==1) = 0;
rwm.data(rwm.data>0) = 1;
rgm.data(rgm.data>0) = 1;
writeFileNifti(lgm);
writeFileNifti(lwm);
writeFileNifti(rgm);
writeFileNifti(rwm);

seg = niftiRead('seg.nii.gz');
seg.data(:,31:end,:)=0;
seg.data(seg.data>0)=1;
lwmTrk = seg;
rwmTrk = seg;
lwmTrk.data(40:end,:,:)=0;
rwmTrk.data(1:40,:,:)=0;
lwmTrk.fname = 'lOccWMTrk.nii.gz';
rwmTrk.fname = 'rOccWMTrk.nii.gz';
writeFileNifti(lwmTrk);
writeFileNifti(rwmTrk);

figure;
bar(mwe);
xlabel('Bundle ID');
ylabel('Bundle Volume Percent of Total');
title('Normalized Fiber Volume');
legend(['Gold', projType(:)']);

% XXX I had to look at the image to manually find the x,y translation magic
% numbers!!
% Fix ITKGRAY OFFSET
t1 = niftiRead('t1.nii.gz');
t1_wm = niftiRead('t1_mtl.nii.gz');
t1_wm = niftiSetQto(t1_wm,t1.qto_xyz,true);
t1_wm.fname = 't1_mtl.nii.gz';
t1_wm.data = circshift(t1_wm.data,[5 -1 0]);
writeFileNifti(t1_wm);

t1_wm = niftiRead('t1_mtl.nii.gz');
%origin = (size(t1_wm.data)+1)/2;
%xform = inv([diag(1./mmPerVox), origin'; [0 0 0 1]]);

mrAnatResliceSpm(t1_wm.data, xform, [boundingBox]);

% Get xform to T1 header space
% M = t1_wm.qto_xyz;
% M(1:2,4) = t1.dim(1:2)' + M(1:2,4); 
% M = t1.qto_ijk * M
% % Get coords for all points
% [I J K] = ndgrid(1:t1.dim(1),1:t1.dim(2),1:t1.dim(3));
% t1wmCoords = [I(:) J(:) K(:)]';
% t1Coords = mrAnatXformCoords(M, t1wmCoords(:,1:5));

sclrs = [122 154 158; 122 103 48; 117 24 96; 212 105 174]/255;

% Help Aviv open a raw file
fid = fopen('E4220S1I8.MR','rb','b');
skip = fread(fid,8432,'int8');
d = fread(fid,256*256,'int16'); 
d = reshape(d,256,256);
fclose(fid);

% Password generator
N = 8;
asciiTable = [48:57, 65:90, 97:122];
rDraw = ceil(length(asciiTable)*rand(8,1));
char(asciiTable(rDraw))
