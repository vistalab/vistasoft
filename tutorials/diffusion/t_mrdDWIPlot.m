%% t_mrdDWIPlot
%
% Illustrate  methods for plotting diffusion weighted imaging data.
% These go through the main routine dwiPlot.
%
% In addition to dwiPlot, there is dwiSpiralPlot (called from dwiPlot) and
% fePlot for fascicle evaluation in the LiFE folder.
%
% See also: t_mrdTensor, t_mrdTensorImage
%
% Brian (c) Stanford VISTASOFT Team, 2012

%% Load diffusion weighted imaging data

dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dwi     = dwiLoad(fullfile(dataDir,'raw','dwi.nii.gz'));
bvecs   = dwiGet(dwi,'diffusion bvecs');


%% Illustrate dwiPlot examples

% The bvals and bvecs
dwiPlot(dwi,'bvals');
dwiPlot(dwi,'bvecs');

%% The ADC at a point
% The vistadata diffusion sample data are 40-directions.  The directory
% contains the dwi data as well as the bvals and bvecs.
% 
% The points showing the ADC
% cCoords = [47 54 43];  % Circular
% dCoords = [44 54 43];  % Directional

coords = [44 54 43];  % Directional
ADC = dwiGet(dwi,'adc data image',coords);
dwiPlot(dwi,'adc',ADC);

%% The ADC along with a smooth shape (peanut)
Q   = dwiGet(dwi,'tensor image',coords);
dwiPlot(dwi,'adc',ADC,Q);

%% Old school plotting

%% Make a sphere
mrvNewGraphWin;
[X,Y,Z] = sphere(15);
[r,c] = size(X);

surf(X,Y,Z);
colormap(jet); set(gca,'Projection','Ortho'); axis equal
set(gca,'xtick',[-1 0 1],'ytick',[-1 0 1],'ztick',[-1 0 1])
grid off; axis off

%% 
s = 1.07;
hold on; plot3(s*bvecs(:,1),s*bvecs(:,2),s*bvecs(:,3),'ko','markerfacecolor','w','markersize',10)

%% Turn off the bottom half of the sphere
mrvNewGraphWin;
l = (Z < 0); X(l) = NaN; Y(l) = NaN; Z(l) = NaN;
surf(X,Y,Z);
colormap(jet); set(gca,'Projection','Ortho'); axis equal
set(gca,'xtick',[-1 0 1],'ytick',[-1 0 1],'ztick',[-1 0 1])
grid off; axis off

l = (bvecs(:,3) > 0);
hold on; plot3(s*bvecs(l,1),s*bvecs(l,2),s*bvecs(l,3),'ko','markerfacecolor','w','markersize',10)

%% End





