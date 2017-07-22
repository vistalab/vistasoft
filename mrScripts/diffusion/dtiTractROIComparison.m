%%% Script for comparing groups of fibers between an individual subject and
%%% a control group.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%% OPTIONS TO SET %%
%%%%%%%%%%%%%%%%%%%%

% which fiber tracts to compare
fgNameRoot = 'precentralG-temporal';    % options: corticospinal, inf_occipitofrontal, precentralG-temporal

if strcmp(fgNameRoot,'corticospinal')
    mmBeyond = 20;
    alignPlane = [NaN NaN 20];
elseif strcmp(fgNameRoot,'inf_occipitofrontal')
    mmBeyond = 70;
    alignPlane = [NaN -15 NaN];
elseif strcmp(fgNameRoot,'precentralG-temporal')
    mmBeyond = 20;
    alignPlane = [NaN NaN 15];
else
    disp('Error: Fiber group input option is not valid');
end

% save output options
outDir = '/biac2/wandell2/data/RadiationNecrosis/dti/al060406_sn2';
outFileName = sprintf('tractComparisonAL_%s',fgNameRoot);


%% group and individual subject to compare %%

% group fibers
tdir = '/silver/scr1/data/templates/child_new';
tname = 'SIRL54';
avgdir = fullfile(tdir,[tname 'warp3']);
tFiberPath = fullfile(avgdir,'fibers');

% single subject fibers
subjectDt6Dir = '/biac2/wandell2/data/RadiationNecrosis/dti/al060406_sn2';
subjectDt6 = fullfile(subjectDt6Dir,['al060406_dt6_fatSat_' tname '.mat']);
sFiberPath = fullfile(subjectDt6Dir,'fibers');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPUTATIONS -- Skip if loading from saved file %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fgNames = { sprintf('%s%s',fgNameRoot,'LH'), sprintf('%s%s',fgNameRoot,'RH') };
nFg = length(fgNames);

% % % % % % % % % % % % % % % % % % % % 
% align fiber coordinates to a plane  %
% % % % % % % % % % % % % % % % % % % %

alignPlaneInd = ~isnan(alignPlane);

% number of 1-mm steps per fiber
nSamplesPerFiber = mmBeyond*2+1;

for ii=1:nFg
    % for control group average
    tmpFgName = fullfile(tFiberPath,[fgNames{ii},'.mat']);
    tmpFg = dtiReadFibers(tmpFgName);
    nFibers = size(tmpFg.fibers,2);
    avgFg(ii).fiberCoord = zeros(3,nFibers,nSamplesPerFiber)*NaN;
    for jj=1:nFibers
        distSq = (tmpFg.fibers{jj}(alignPlaneInd,:)-alignPlane(alignPlaneInd)).^2;
        nearest = find(distSq==min(distSq));
        nearest = nearest(1);
        avgFg(ii).dist(jj) = sqrt(distSq(nearest));
        fiberCoords = [nearest-mmBeyond:nearest+mmBeyond];
        %         if mmBeyond<=tmpFg.fibers{jj}
        if ~(strcmp(fgNameRoot,'precentralG-temporal'))
            if diff(tmpFg.fibers{jj}(alignPlaneInd,[nearest-1 nearest+1])) < 0
                fiberCoords = fliplr(fiberCoords);
            end
        end
        %         end
        fiberCoords(fiberCoords<1) = NaN;
        fiberCoords(fiberCoords>size(tmpFg.fibers{jj},2)) = NaN;
        avgFg(ii).fiberCoord(:,jj,~isnan(fiberCoords)) = ...
            tmpFg.fibers{jj}(:,fiberCoords(~isnan(fiberCoords)));
    end
    
    % for patient
    tmpFgName = fullfile(sFiberPath,[fgNames{ii},'.mat']);
    tmpFg = dtiReadFibers(tmpFgName);
    nFibers = size(tmpFg.fibers,2);
    sFg(ii).fiberCoord = zeros(3,nFibers,nSamplesPerFiber)*NaN;
    for jj=1:nFibers
        distSq = (tmpFg.fibers{jj}(alignPlaneInd,:)-alignPlane(alignPlaneInd)).^2;
        nearest = find(distSq==min(distSq));
        nearest = nearest(1);
        sFg(ii).dist(jj) = sqrt(distSq(nearest));
        fiberCoords = [nearest-mmBeyond:nearest+mmBeyond];
        %         if mmBeyond<=tmpFg.fibers(jj)
        if ~(strcmp(fgNameRoot,'precentralG-temporal'))   % quick fix because this pathway (arcuate) crosses every plane twice
            if diff(tmpFg.fibers{jj}(alignPlaneInd,[nearest-1 nearest+1])) < 0
                fiberCoords = fliplr(fiberCoords);
            end
        end
        %         end
        fiberCoords(fiberCoords<1) = NaN;
        fiberCoords(fiberCoords>size(tmpFg.fibers{jj},2)) = NaN;
        sFg(ii).fiberCoord(:,jj,~isnan(fiberCoords)) = ...
            tmpFg.fibers{jj}(:,fiberCoords(~isnan(fiberCoords)));
    end   
end

% % % % % % % % % % % % % % % % % % % % % % %
% create dt6 matrices for the fiber groups  %
% % % % % % % % % % % % % % % % % % % % % % %

% get a list of all subjects in the average directory
snFiles  = findSubjects(avgdir, '*_sn*',{});
nSubject = length(snFiles);

for ii=1:nSubject
    disp(['Loading ' snFiles{ii} '...']);
    dt = load(snFiles{ii},'dt6','xformToAcPc');
    for jj=1:size(avgFg,2) % different fiber groups
        nFibers = size(avgFg(jj).fiberCoord,2);
        coords  = reshape(avgFg(jj).fiberCoord,3,nFibers*nSamplesPerFiber);
        coords  = mrAnatXformCoords(inv(dt.xformToAcPc), coords);
        % Trilinear interpolation
        tmpDt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','trilin');
        fiberDt6Tri{ii,jj} = reshape(tmpDt6, nFibers, nSamplesPerFiber, 6);
        % Do it again using nearest-neighbor interpolation
        tmpDt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','nearest');
        fiberDt6NN{ii,jj} = reshape(tmpDt6, nFibers, nSamplesPerFiber, 6);
    end
end

% get data from patient
disp(['Loading ' subjectDt6 '...']);
dt = load(subjectDt6,'dt6','xformToAcPc');
for jj=1:size(sFg,2) % different fiber groups
    nFibers = size(sFg(jj).fiberCoord,2);
    coords  = reshape(sFg(jj).fiberCoord,3,nFibers*nSamplesPerFiber);
    coords  = mrAnatXformCoords(inv(dt.xformToAcPc), coords);
    % Trilinear interpolation
    tmpDt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','trilin');
    sFiberDt6Tri{jj} = reshape(tmpDt6, nFibers, nSamplesPerFiber, 6);
    % Do it again using nearest-neighbor interpolation
    tmpDt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','nearest');
    sFiberDt6NN{jj} = reshape(tmpDt6, nFibers, nSamplesPerFiber, 6);
    
    % calculate mean for each fiber group
    sFiberTensorStats(jj).name = fgNames{jj};
    
    dt6              = shiftdim(sFiberDt6NN{jj},1);
    dt6(isnan(dt6))  = 1e-50;
    dt6(dt6==0)      = 1e-50;
    [eigVec,eigVal]  = dtiEig(dt6);
    eigVal(eigVal<0) = 1e-50;
    logDt6           = dtiEigComp(eigVec,log(eigVal));
    [M,S,N]          = dtiLogTensorMean(logDt6);
    
    sFiberTensorStats(jj).M = M;
    sFiberTensorStats(jj).S = S;
    sFiberTensorStats(jj).N = N;
end

% % % % % % % % % % % % % % % % % % % % % % % % %
% calculate mean tensor along each fiber group  %
% % % % % % % % % % % % % % % % % % % % % % % % %

avgFiberDt6NN = repmat(struct( 'M', zeros(nSamplesPerFiber,6,nSubject)*NaN, ...
    'S', zeros(nSamplesPerFiber,nSubject)*NaN, ...
    'N', zeros(1,nSubject) ), size(fiberDt6NN,2), 1 );

for ii=1:nSubject
    for jj=1:(size(fiberDt6NN,2))
        avgFiberDt6NN(jj).name = fgNames{jj};
        
        dt6              = shiftdim(fiberDt6NN{ii,jj},1);
        dt6(isnan(dt6))  = 1e-50;
        dt6(dt6==0)      = 1e-50;
        [eigVec,eigVal]  = dtiEig(dt6);
        eigVal(eigVal<0) = 1e-50;
        logDt6           = dtiEigComp(eigVec,log(eigVal));
        [M,S,N]          = dtiLogTensorMean(logDt6);
        
        avgFiberDt6NN(jj).M(:,:,ii) = M;
        avgFiberDt6NN(jj).S(:,ii) = S;
        avgFiberDt6NN(jj).N(ii) = N;
    end
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% calculate group mean for single-subject comparison  %
% % % % % % % % % % % % % % % % % % % % % % % % % % % %

gpFiberTensorStats = repmat(struct('M',[],'S',[],'N',0), size(avgFiberDt6NN,1), 1 );

for ii=1:size(avgFiberDt6NN,1)
    [M,S,N] = dtiLogTensorMean(avgFiberDt6NN(ii).M);
    gpFiberTensorStats(ii).M = M;
    gpFiberTensorStats(ii).S = S;
    gpFiberTensorStats(ii).N = N;
    gpFiberTensorStats(ii).name = avgFiberDt6NN(ii).name;
end

% % % % % % % % % % % % % % 
% save tensor statistics  %
% % % % % % % % % % % % % % 

save(fullfile(outDir,outFileName),'sFiberTensorStats','gpFiberTensorStats','mmBeyond','alignPlaneInd','alignPlane');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOG TENSOR STATISTICS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load from file -- be sure to run first part of script (before "computations") first
fiberTensorStats = load(fullfile(outDir,outFileName));
gpFiberTensorStats = fiberTensorStats.gpFiberTensorStats;
sFiberTensorStats  = fiberTensorStats.sFiberTensorStats;
mmBeyond           = fiberTensorStats.mmBeyond;
alignPlaneInd      = fiberTensorStats.alignPlaneInd;
alignPlane         = fiberTensorStats.alignPlane;


% OPTIONS for stats
tensorComp = 'val'; % which component to compare 'vec' or 'val'
fgID = 1; % which fiber group to test, see gpFiberTensorStats(:).name; usually 1 is left, 2 is right

% test using Armin's tool
[T, DISTR, df] = dtiLogTensorTest(tensorComp, gpFiberTensorStats(fgID).M, ...
    gpFiberTensorStats(fgID).S, gpFiberTensorStats(fgID).N, sFiberTensorStats(fgID).M);

% convert test statistics to p-values
pval = 1-fcdf(T,df(1),df(2));

whichPlane = 'xyz';

% create some plots
x = [-mmBeyond:mmBeyond]';

% plot for F values
figure; plot(x,T);
set(gca,'xlim',mrvMinmax(x'));
xlabel(['1-mm steps from ' whichPlane(alignPlaneInd) ' = ' num2str(alignPlane(alignPlaneInd))]);
ylabel('F-value');
title(['F-value for testing ' tensorComp ' in ' gpFiberTensorStats(fgID).name]);

% plot for p-values
figure; plot(x,pval);
% log scale
set(gca,'yscale','log','xlim',mrvMinmax(x'));
xlabel(['1-mm steps from ' whichPlane(alignPlaneInd) ' = ' num2str(alignPlane(alignPlaneInd))]);
ylabel('p-value');
title(['p-value for testing ' tensorComp ' in ' gpFiberTensorStats(fgID).name]);
