% Script: Group analysis of Arcuate: weighted average diffusion properties computed
%         along the FG path. 
%
%ER wrote it 12/2009
%
%
%% I. Set up fibersDir, dtDir andd roisDir for each participant 
fibersDir(1)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\zs040630\fibers\IPSproject\arcuate'}; 
fibersDir(2)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\dm040922\fibers\IPSproject\arcuate'}; 
roisDir(1)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\zs040630\dti06trilinrt\ROIs'};
roisDir(2)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\dm040922\dti06trilinrt\ROIs'};
dtDir(1)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\zs040630\dti06trilinrt'};
dtDir(2)={'\\White\biac3-wandell4\data\reading_longitude\dti_y1\dm040922\dti06trilinrt'};

%% II. Set up parameters
numberOfNodes = 30; 
propertyofinterest='fa'; %Can also be md, rd, ad
numsfgs=length(dtDir); 
fgName='L_Arcuate.mat'; 
roi1name='SLF_roi1_L.mat'; 
roi2name='SLFt_roi2_L.mat';


%% III. Loop
for sfg=1:numsfgs
fibersFile = fullfile(fibersDir{sfg}, fgName); 
roi1File   = fullfile(roisDir{sfg}, roi1name); 
roi2File   = fullfile(roisDir{sfg}, roi2name); 

% III. 1 LOAD THE DATA
roi2  = dtiReadROI(roi1File);
roi1  = dtiReadROI(roi2File);
fg    = dtiLoadFiberGroup(fibersFile);

cd(dtDir{sfg}); dt=dtiLoadDt6('dt6.mat'); 

% III. 2 Compute
[fa(:, sfg),md(:, sfg),rd(:, sfg),ad(:, sfg), SuperFibersGroup(sfg)]= ...
    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes);

end

%% IV Plot results
figure; 
title(['Weighted average along the FG trajectory for ' propertyofinterest]); 
plot(eval(propertyofinterest));
title(propertyofinterest); xlabel(['First node <-> Last node']); 
for sfg=1:numsfgs
    x(sfg) = SuperFibersGroup(sfg).fibers{1}(1, 1);
    y(sfg) = SuperFibersGroup(sfg).fibers{1}(2, 1);
    z(sfg) = SuperFibersGroup(sfg).fibers{1}(3, 1);
    xe(sfg)= SuperFibersGroup(sfg).fibers{1}(1, end);
    ye(sfg)= SuperFibersGroup(sfg).fibers{1}(2, end);
    ze(sfg)= SuperFibersGroup(sfg).fibers{1}(3, end);
end

display('Center-of-mass coordinates for superfiber endpoints are displayed as text');

%You can add a legend if you like -- i did not. 
text(1, 0.5, {['x=' num2str(mean(x)) ], ['y=' num2str(mean(y))],  ['z=' num2str(mean(z))]}); 
text(numberOfNodes-3, 0.5, {['x=' num2str(mean(xe)) ], ['y=' num2str(mean(ye))],  ['z=' num2str(mean(ze))]}); 
% legend('','') % Goes here
%%

