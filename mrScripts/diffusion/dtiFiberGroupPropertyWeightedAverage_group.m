% script allSubjectsFG = dtiFiberGroupPropertyWeightedAverage_group(subjDirs, wDir)
%
%dtiFiberGroupPropertyWeightedAverage_group(subjDirs, wDir)
%For a fiber group fg, obtain average eigenvalues across the fg length, in
%numberOfNodes points. The average is weighted with a gaussian kernel, where fibers close to the center-of-mass
%of a bundle contribute more, whereas fibers at the edges contribute less.
%The variance for this measure, for the subsequent t-tests, can be [in the future]
%computed two ways: 1. across subjects 2.within a subject -- with a bootstrapping procedure, removing one fiber at a time from the bundle, and recomputing your average valNames.
%valNames: l1/l2/l3/AD/RD/MD/FA

%Important assumptions: the fiber bundle is a tight bunch. All fibers begin
%in one ROI and end in another. An example of input bundle is smth that
%emerges from clustering or from manualy picking fibers.


if notDefined('subjDirs'),
    subjDirs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...
        'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
        'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
end
if notDefined('numberOfNodes'),  end
if notDefined('wDir'), wDir = pwd; end

%% parameters
% # nodes in the supergroup
numberOfNodes = 40;

% this is the path to the fiber group within each subject directory. We
% assume it's the same for each subject.
if notDefined('fiberGroupPath')
    %fiberGroupPath = {'dti06\fibers\conTrack\occ_MORI_clean\Mori_Occ_CC_100k_top1000_RIGHT.mat'};
    %fiberGroupPath(2,:) ={'dti06\fibers\conTrack\occ_MORI_clean\Mori_Occ_CC_100k_top1000_LEFT.mat'};

% fiberGroupPath = {'dti06\fibers\conTrack\OT_clean\rtOC_inf_10_rtLGN_500'};
% fiberGroupPath(2,:)={'dti06\fibers\conTrack\OT_clean\ltOC_inf_10_ltLGN_500'};

    fiberGroupPath = {'dti06\fibers\conTrack\OR_clean\rtLGN_rtCalcarine_top1000_clean.mat'};
    fiberGroupPath(2,:)={'dti06\fibers\conTrack\OR_clean\ltLGN_ltCalcarine_top1000_clean.mat'};
   
end

%Stats will be saved in statsFile (specify full name here)
% statsFile='myStats';

%% initialize the output variable
% allSubjectsFG is a matrix of size:
%   nNodes (30) x 3 x # subjects X 2 for two hemispheres
% each 3-dimensional slice is one subject's data
clear SuperFibersGroup allSubjectsFG eigValFG stats;

% For each subject
for ss = 1:length(subjDirs)
    for hh=1:size(fiberGroupPath, 1)
    fprintf('Running subject %s...%s\n', subjDirs{ss}, fiberGroupPath{hh} );
    
    curDir = fullfile(wDir, subjDirs{ss});
    
    % read the diffusion data for this subject
    dt = dtiLoadDt6(fullfile(curDir,'dti06','dt6.mat'));
    
    % read the fiber group for this subject
    fgFile = fullfile(curDir, fiberGroupPath{hh});
    fg = dtiReadFibers(fgFile);

    % call Elena's super-fiber group code
    [eigValFG(:, :, ss, hh), SuperFibersGroup(ss, hh)] = dtiFiberGroupPropertyWeightedAverage(fg, dt, numberOfNodes);
    
    % store the "EigenFibers" for each session
    end
end
for hh=1:size(fiberGroupPath, 1)
[SuperFibersGroup(:, hh), IDsOfFlipped]=dtiReorientSuperfiberGroups(SuperFibersGroup(:, hh));
allSubjectsFG(:,:,:, hh) = eigValFG(:, :, :, hh);
allSubjectsFG(:,:,IDsOfFlipped, hh) = flipdim(eigValFG(:, :, IDsOfFlipped, hh), 1);
if ~isempty(IDsOfFlipped)
    fprintf(1, 'fiberGroupPath %s Flipped superfibers for %s subjects \n', num2str(sum(IDsOfFlipped)), num2str(hh)); 
end
end
for ss=1:length(subjDirs)
    for hh=1:2
 stats{ss,hh} = allSubjectsFG(:,:,ss, hh);
    end 
end


%display SuperFiber variance (generalized and separately for LR, AP, IS)
figure; 
numNodes=size(SuperFibersGroup(1, 1).fibers{1}, 2);
for hh=1:size(fiberGroupPath, 1)
for sp=1:length(subjDirs)
for nodeI=1:numNodes
    [determinant, varcovmatrix] =detLowTriMxVectorized(SuperFibersGroup(sp, hh).fibervarcovs{1}(:, nodeI));
    genvar(nodeI, sp, hh)=sqrt(trace(diag(eig(varcovmatrix)))./3);
    lrvar(nodeI, sp, hh)=varcovmatrix(1, 1);
    apvar(nodeI, sp, hh)=varcovmatrix(2, 2);
    isvar(nodeI, sp, hh)=varcovmatrix(3, 3);
end
end
subplot(4, 2, hh);
hold on; plot(genvar(:, :, hh)); title(fiberGroupPath(hh)); xlabel('Node'); ylabel('Var in locations');
subplot(4, 2, hh+2); hold on; plot(lrvar(:, :, hh)); title(fiberGroupPath(hh)); xlabel('Node'); ylabel('LR');
subplot(4, 2, hh+4); hold on; plot(apvar(:, :, hh)); title(fiberGroupPath(hh)); xlabel('Node'); ylabel('AP');
subplot(4, 2, hh+6); hold on; plot(isvar(:, :, hh)); title(fiberGroupPath(hh)); xlabel('Node'); ylabel('IS');
end
%

save(statsFile,'subjDirs','pathFiles','stats');
    
% grab only the data in a desired range (end effects tend to produce large
% inter-subject variability)
% keepRange = [5:15];  % nodes to keep
% meanEigenVal = mean( allSubjectsFG(keepRange,:,:), 1);
% meanEigenVal = permute(meanEigenVal, [3 2 1]); % size [subjects x 3]

%% plot the data
nRows = 6; nCols = 5;  % assuming 30 subjects
figure('Color', 'w', 'Name', 'EigenFibers For Each Subject');
for ss = 1:length(subjDirs)
    subplot(nRows, nCols, ss);
    plot( allSubjectsFG(:,:,ss), 'k', 'LineWidth', 2);
    xlabel('Node #');
    ylabel('Eigenvalue');
    title( subjDirs{ss} );
    
    set(gca, 'Box', 'off', 'FontSize', 10);
    setLineColors({'r' 'g' 'b'});
end

legendPanel({'1st eigenvalue' '2nd eigenvalue' '3rd eigenvalue'});

% also plot each eigenvalue across subjects
figure('Color', 'w', 'Name', 'EigenFibers Across Subjects');
for ii = 1:3
    subplot(3, 1, ii);
    % plot inidividual subject data in blue
    plot( squeeze(allSubjectsFG(:,ii,:)), 'r' );
    
    % plot the kept range in black
    hold on
    plot( squeeze(allSubjectsFG))
    
    xlabel('Node');
    ylabel('Eigenvalue');
    title(['Eigenvalue #' num2str(ii)]);
    set(gca, 'Box', 'off', 'FontSize', 10);
end
figure;
%   plot( squeeze(allSubjectsFG(:,2,:)), 'r' );
%hold on;    plot( squeeze(allSubjectsFG(:,3,:)), 'g' );
   plot( squeeze(allSubjectsFG(:,1,:)), 'b' );hold on;
   plot( squeeze(allSubjectsFG(:,2,:)+allSubjectsFG(:,3,:))./2, 'k' );%RD
  
 
normAxes;
legendPanel(subjDirs);