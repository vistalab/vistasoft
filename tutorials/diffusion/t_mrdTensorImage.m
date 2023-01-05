%% t_mrdTensorImage
%
% Shows examples of methods for plotting dwi data 
%
% Most of the methods shown here use the features of dwiGet and dwiPlot.
%
% The script loads sample dwi data.  It then uses different ways to
% visualize the dwi data in multiple directions.
%
% See also:  t_mrdTensor, dwiPlot, dwiSpiralPlot, dwiGet, sphere2flat
%
% (c) Stanford VISTA Team

%% Load diffusion weighted imaging data

% The vistadata diffusion sample data are 40-directions.  The directory
% contains the dwi data as well as the bvals and bvecs.
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dwi = dwiLoad(fullfile(dataDir,'raw','dwi.nii.gz'));
cCoords = [47 54 43];  % Circular
dCoords = [44 54 43];  % Directional

% The dwiPlot routine enables visualization of simple objects
% dwiPlot(dwi,'bvecs');
% dwiPlot(dwi,'bvals');
% ADC = dwiGet(dwi,'adc data image',cCoords); 
% dwiPlot(dwi,'adc',ADC);

%% ADC measured and predicted by tensor
ADC = dwiGet(dwi,'adc data image',dCoords); 
Q   = dwiGet(dwi,'tensor image',dCoords);
dwiPlot(dwi,'adc',ADC,Q);

%% Estimated diffusion distance and predicted by tensor
dDist = dwiGet(dwi,'diffusion distance image',dCoords);
dwiPlot(dwi,'dDist',dDist,Q);
title('Diffusion distance (um) (missing sqrt(2))');

%% Pick a coordinate and plot ADC
ADC = dwiGet(dwi,'adc data image',cCoords);
dwiPlot(dwi,'adc image xy',ADC);
title('ADC ');
% dwiPlot(dwi,'adc image azel',ADC)
% dwiPlot(dwi,'adc image polar',ADC)

%% Now another coordinate
ADC = dwiGet(dwi,'adc data image',dCoords);
dwiPlot(dwi,'adc image xy',ADC);
title('Spherical diffusion');

% Now in azimuth elevation format
dwiPlot(dwi,'adc image azel',ADC);

% Little used, polar format
dwiPlot(dwi,'adc image polar',ADC);

%% Compare observed and predicted dSig values

% Predict the diffusion signal.  This could be in dwiGet, such as
% dwiGet(dwi,'tensor predicted ds',coords)
Q      = dwiGet(dwi,'tensor image',dCoords);
S0     = dwiGet(dwi, 'S0 image',dCoords);
bvecs  = dwiGet(dwi,'diffusion bvecs');
bvals  = dwiGet(dwi,'diffusion bvals');
predDS = dwiComputeSignal(S0, bvecs, bvals, Q);

dSig = dwiGet(dwi,'diffusion data image',dCoords);
mrvNewGraphWin; plot(predDS,dSig,'o','MarkerFaceColor','k'); axis equal; grid on
xlabel('Predicted dSig')
ylabel('Measured dSig')

%% Compare observed and predicted ADC values

% This could be in dwiGet, such as
% dwiGet(dwi,'tensor predicted adc',coords)

obsADC = dwiGet(dwi,'adc data image',dCoords);
Q      = dwiGet(dwi,'tensor image',dCoords);
bvecs  = dwiGet(dwi,'diffusion bvecs');
predADC= dtiADC(Q,bvecs);

mrvNewGraphWin; plot(predADC,obsADC,'s'); axis equal; grid on
xlabel('Predicted ADC')
ylabel('Measured ADC')

%% Diffusion distance image

% ADC is um2/ms
% the vector is made dimensionless by 1/sqrt(ADC) units of sqrt(ms)/um
% We need to know the actual acquisition time.  We then divide the computed
% number by the sqrt(ms) of the diffusion time.
dDist = dwiGet(dwi,'diffusion distance image',dCoords);
dwiPlot(dwi,'diffusion distance image xy',dDist);
title('Diffusion distance')

% Show it in azimuth elevation format
dwiPlot(dwi,'diffusion distance image azel',dDist);

%% Spiral out plots

% Make an ADC plot which starts at the center of the image (top of the
% hemisphere) and spirals out towards the equator
adc = dwiGet(dwi,'adc data image',dCoords);
uData = dwiPlot(dwi,'adc image xy',adc);
dwiSpiralPlot(uData);
ylabel('ADC');

%% Spiral out for diffusion signal

dSig = dwiGet(dwi,'dsig image',dCoords);
uData = dwiPlot(dwi,'dsig image xy',dSig);

%% Predicted ADC, spiral out
Q      = dwiGet(dwi,'tensor image',dCoords);
bvecs  = dwiGet(dwi,'diffusion bvecs');
predADC= dtiADC(Q,bvecs);
uDataP = dwiPlot(dwi,'adc image xy',predADC);
dwiSpiralPlot(uDataP);

measuredADC = dwiGet(dwi,'adc data image',dCoords);
uDataM = dwiPlot(dwi,'adc image xy',measuredADC);
sData = dwiSpiralPlot(uDataM);
hold on; plot(sData.data,'k.')
legend('Estimated','Measured')
ylabel('ADC');

%% Make a predicted (by tensor) image

Q      = dwiGet(dwi,'tensor image',dCoords);
S0     = dwiGet(dwi,'S0 image',dCoords);
bvecs  = dwiGet(dwi,'diffusion bvecs');
bvals  = dwiGet(dwi,'diffusion bvals');
predDS = dwiComputeSignal(S0, bvecs, bvals, Q);
uDataP = dwiPlot(dwi,'dsig image xy',predDS);
dwiSpiralPlot(uDataP);

dSig = dwiGet(dwi,'diffusion data image',dCoords);
uDataM = dwiPlot(dwi,'dsig image xy',dSig);
dwiSpiralPlot(uDataM);

% Show the error
mrvNewGraphWin;
estErr = abs((uDataP.data - uDataM.data) ./ uDataM.data);
estErr(1,1) = 1;   % For the color map range
mp = hot; mp(1,:) = [0 0 0]; colormap(mp);
imagesc(estErr);
colorbar
set(get(colorbar,'xlabel'),'string','Frac. Error')


%% End