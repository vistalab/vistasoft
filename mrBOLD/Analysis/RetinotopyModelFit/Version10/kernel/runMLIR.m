% ==============================================================================
% SAFIR, Luebeck, November 2006
%
%
%
% ==============================================================================
function yOpt=runMLIR();
clc;

str = {'SAFIR-Luebeck: November 2006'
  'Image Registration for fMRI-Image Data'
  ' '};

fprintf('%s\n',char(ones(1,80)*'*'));
fprintf('%s\n',str{:});

matfile = 'safirData.mat';
fprintf('matfile is [%s]\n',matfile);


% setting some default values
Omega             = [1,1];
m                 = [128,128];
minLevel          = 3;
model             = 'rigid2D';
distanceMeasure   = 'SSD_W';
regularizer       = 'elastic';
alpha             = 5e-1;
beta              = 1;
interpolationMode = 'linear-periodic';
period            = 2*pi;
colmap            = hsv(256);
doParametric      = 1;
w0                = [];

maxIterPIR    = 50;
maxIterNPIR   = 10;
doParametric  = 1;
doPlotHistory = 0;
doPause       = 0;


% load the data from mat-file
load(matfile);

m = 2^maxLevel * [1,1];
maxLeveln = maxLevel;
interpolation('set','MODE',interpolationMode,'period',period);

viewPara = viewImage('set','viewer','imagesc2D','colmap',colmap);


% throwing the NaNs away
RD1(isnan(RD1))=0;
RD2(isnan(RD2))=0;
TD1(isnan(TD1))=0;
TD2(isnan(TD2))=0;
WD1(isnan(WD1))=0;
WD2(isnan(WD2))=0;

% preparing the Multilevel-Data for each
% Atlas Reference and Mask
[MLR1,minLevel,maxLevel] = ...
  getMultiLevel(RD1,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);
[MLR2,minLevel,maxLevel] = ...
  getMultiLevel(RD2,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);
[MLT1,minLevel,maxLevel] = ...
  getMultiLevel(TD1,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);
[MLT2,minLevel,maxLevel] = ...
  getMultiLevel(TD2,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);
[MLW1,minLevel,maxLevel] = ...
  getMultiLevel(WD1,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);
[MLW2,minLevel,maxLevel] = ...
  getMultiLevel(WD2,Omega,m,'minLevel',minLevel,'fig',2,'pause',0,'plots',0);

% save(mfilename,'matfile','viewPara',...
%   'MLR1','MLR2','MLT1','MLT2','MLW1','MLW2',...
%   'minLevel','maxLevel',...
%   'model','distanceMeasure','alpha','beta');
% 

maxLevel = maxLeveln;
tolJ=tol;
tolY=sqrt(tol);
tolG=tol^(2/3);
% ==============================================================================

fprintf('%s\n',char(ones(1,80)*'*'));

% ==============================================================================

% set the distance to weighted SSD
if strcmp(interpolationMode,'linear-periodic')
    distance('set','MODE','SSD_WP','period',period);
elseif strcmp(interpolationMode,'linear')
    distance('set','MODE','SSD_W');
else
    error('Unknown interpolationMode')
end;

% =========================================================================

% prepare for pre-registration (rigid2D)
if isempty(w0),
  w0 = feval(model);
end;

% empty program history
his = [];

% start the Multilevel approach
% begin at the coarsest iteration
% all imagesizes of each iteraton have size 2^level
for level=minLevel:maxLevel,

  % get data for level:
  fprintf('level %d from %d to %d\n',level,minLevel,maxLevel);
  RD1 = MLR1{level}.D;
  RD2 = MLR2{level}.D;
  TD1 = MLT1{level}.D;
  TD2 = MLT2{level}.D;
  WD1 = MLW1{level}.D;
  WD2 = MLW2{level}.D;
  m   = MLT1{level}.m;
  Omega = MLT1{level}.Omega;

  % if parametric pre-registration is choosen just perform it on the
  % coarsest grid
  if level == minLevel & doParametric,
    y0   = []; % no preknowledge
    wRef = w0;

    [wOpt,hist,hisstr] = PIR(RD1,RD2,TD1,TD2,WD1,WD2,Omega,m,...
      y0,model,wRef,w0,'maxIter',maxIterPIR,'fig',minLevel-1);

    % so right now we have cancelled the iteraton plots
    % to get smarter outputs
%     if doPlotHistory,
%       hisstr{1} = 'iteration history for PIR';
%       J = 1:4;
%       plotHistory(hist(:,J),hisstr(J),'fig',100+minLevel-1)
%     end;

    % just write the parameters to console
    fprintf('wOpt = \n');
    disp(wOpt');
   
    
  elseif level == minLevel,
    wOpt = w0;
  end;

 
  % yKern is the part of the deformation field that should not be
  % penelazid by the regularizer
  % the regularizer works for B*(y-yKern)
  
  % map wt to the staggered grid level
  yKern = w2stg(model,Omega,m,wOpt);

  % perform resolution changes for the deformation field
  if level == minLevel,
    y0 = yKern;
  else
    xCoarse = getGrid(Omega,m/2,'staggered');
    xFine   = getGrid(Omega,m  ,'staggered');
    uCoarse = yOpt - xCoarse;
    uFine   = mfPu(uCoarse,length(m),m/2,'Pu');
    y0      = xFine + uFine;
  end;

  % and start the nonparametric nonlinear image registration on this level
  [yOpt,hist,hisstr] = NPIR(RD1,RD2,TD1,TD2,WD1,WD2,Omega,m,...
    yKern,y0,'alpha',alpha,'beta',beta,'maxIter',maxIterNPIR,'fig',level,...
    'regularizer',regularizer,'tolJ',tolJ,'tolG',tolG,'tolY',tolY);

  his = [his;hist];
end;

% after the multilevelapproach save the result on the finest grid to the
% file named 'safirResult.mat'
save('safirResult.mat','yOpt');

fprintf('%% %s  [ %s - done ]  % s\n',char(ones(1,10)*'='),mfilename,...
  char(ones(1,53-length(mfilename))*'='));

% =========================================================================

% here the iterationhistory is plot
% skip it if it disturbes you
hisstr{1} = 'iteration history for MLIR3D';
plotMLhis(his,'MLPIR',100);

return
% ==============================================================================
