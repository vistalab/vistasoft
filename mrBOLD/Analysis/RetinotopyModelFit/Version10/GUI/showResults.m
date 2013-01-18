function showResults(yOpt,filename)
% written by Jens Heyder, SAFIR-Group 2006
% 
% visualizes the results of simultaneous fMRI-image registration
%
% PARAMETERS:
% yOpt - deformation field as staggered grid (result of runMLIR)
% filename - filename of the file containing the image data (mostly safirData.mat)
% 
% yOpt is stored by runMLIR (by default in the file safirResult.mat)
% if you like to store results with other filenames feel free to use
% showResults with these instead of always using GUI.m

%% setup
% load the results file
alpha=[];beta=[];
load(filename)

Omega=[1 1];
m=[2^maxLevel 2^maxLevel];
h=Omega./m;
X=getGrid(Omega,m);

% before interpolation assure that yOpt is on cell-centered grid!
yOpt=stg2center(yOpt,m,'Py');

% set interpolation mode
% for periodic images use period parameter
% for interpolationMode 'linear' period is ignored
interpolation('set','MODE',interpolationMode,'period',2*pi);

% interpolate images
M1i=interpolation(RD1,Omega,X);
M2i=interpolation(RD2,Omega,X);
A1i=interpolation(TD1,Omega,X);
A2i=interpolation(TD2,Omega,X);
W1i=interpolation(WD1,Omega,X);
W2i=interpolation(WD2,Omega,X);

% get deformed atlases
dA1i=interpolation(TD1,Omega,yOpt);
dA2i=interpolation(TD2,Omega,yOpt);

% get deformed areas of interest
areasImg = areaNumTransform(areasImg);
OV=floor(interpolation(areasImg,Omega,yOpt));

%% convert to matrix form
M1m=ip2mat(M1i,m);
M2m=ip2mat(M2i,m);
A1m=ip2mat(A1i,m);
A2m=ip2mat(A2i,m);
W1m=ip2mat(W1i,m);
W2m=ip2mat(W2i,m);
dA1m=ip2mat(dA1i,m);
dA2m=ip2mat(dA2i,m);
OVm=ip2mat(OV,m);
OVm(isnan(OVm))=0;

% get edge image of areas of interest
Edges=double(edge(OVm, 'canny'));

% Edges = detectAreaBorders(OVm);
% calculate difference image
D1m=abs(M1m-dA1m);
D2m=abs(M2m-dA2m);

% deal with phase wraps
if strcmp(interpolationMode,'linear-periodic')
    D1m(D1m>pi)=D1m(D1m>pi)-pi;
    D2m(D2m>pi)=D2m(D2m>pi)-pi;
    maxD=pi;
else
    maxD=2*pi;
end



%% --- Eccentricity data with edges of fitted atlas
f(1) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(M1m,Edges,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Eccentricity data with edges of fitted atlas';
set(f,'name',title);



%% --- Original eccentricity atlas with deformation grid
f(2) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(A1m,0,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
% overlay grid
plotGrid(yOpt,Omega,m);
title='Original eccentricity atlas with deformation grid';
set(f,'name',title);



%% --- Deformed eccentricity atlas with edges
f(3) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(dA1m,Edges,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Deformed eccentricity atlas with edges';
set(f,'name',title);

% --- Eccentricity difference image |data-deformed atlas|
f(4) =figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(D1m,Edges,flipud(hot),maxD),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Eccentricity difference image |data-deformed atlas|';
set(f,'name',title);


%% --- Angle data with edges of fitted atlas
f(5) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(M2m,Edges,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Angle data with edges of fitted atlas';
set(f,'name',title);


%% --- Original angle atlas with deformation grid
f(6) =figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(A2m,0,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
plotGrid(yOpt,Omega,m);
title='Original angle atlas with deformation grid';
set(f,'name',title);


%% --- Deformed angle  with edges
f(7) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(dA2m,Edges,hsv,2*pi),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Deformed angle atlas with edges';
set(f,'name',title);


%% --- Angle difference image |data-deformed atlas|
f(8) = figure;

% this is necessary if grid is overlayed
I=flipdim(mergedImage(D2m,Edges,flipud(hot),maxD),1); 
image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
axis image; axis xy;axis off;
title='Angle difference image |data-deformed atlas|';
set(f,'name',title);

%% --- Save all the images
imageDir = fullfile(pwd, 'Images');
ensureDirExists(imageDir);

imPath = fullfile(imageDir, 'Atlas Fit Eccentricity Data.png');
saveas(f(1), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Original Eccentricity Atlas.png');
saveas(f(2), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Deformed Eccentricity Atlas.png');
saveas(f(3), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Eccentricity Difference Image.png');
saveas(f(4), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Angle Data.png');
saveas(f(5), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Original Angle Atlas.png');
saveas(f(6), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Deformed Angle Atlas.png');
saveas(f(7), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

imPath = fullfile(imageDir, 'Atlas Fit Angle Difference Image.png');
saveas(f(8), imPath);
fprintf('[%s]: Saved image %s.\t(%s)\n', mfilename, imPath,  datestr(now));

return
% /----------------------------------------------------------/ %




% /----------------------------------------------------------/ %
function A=ip2mat(B,m)
A=flipud(reshape(B,m)');
return
