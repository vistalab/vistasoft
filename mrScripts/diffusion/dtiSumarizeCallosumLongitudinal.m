%% Initialize vars and get subject list
clear all;
close all;

% The date-code- all results wile this apended to the name.
dc = '090722';

if(ispc)
    bd = '//171.64.204.10/biac3-wandell4/data/reading_longitude';
    addpath //171.64.204.10/home/bob/matlab/stats
else
    bd = '/biac3/wandell4/data/reading_longitude/';
    addpath /home/bob/matlab/stats
end

behavDataFile = fullfile(bd,'read_behav_measures_longitude.csv');
baseDir = fullfile(bd,'callosal_analysis');


nFiberSamps = 0; % <1 means all
weightByFiberDensity = true;
outDirName = 'longitude';

diffusivityUnitStr = '(\mum^2/msec)';

% to be sure we catch all fibers within the bulk of the ROI, the minimum
% minDist is sqrt(.5^2+.5^2)=.7071, which is the distance from the center of a
% 1mm pixel to any corner of that pixel. 
minDist = .71;
useMedian = false;
figs = true;
verbose = false;

hemiName = {'left','right'};

% Graph Globals
barColor = [0.0784 0.7843 0.0784; 0.7843 0.0784 0.7843; 0.7843 0.7843 0.0784;0.0784 0.3529 0.7843;...
       0.7843 0.0784 0.0784; 0.9216 0.6471 0.2157; 0.2157 0.6471 0.9216; .75 .75 .75];
tickLabels = { 'Occipital', 'Temporal', 'P-Parietal', 'S-Parietal', ...
    'S-Frontal', 'A-Frontal', 'Orbital' };

% SET THE OUTDIR NAME BASED ON ANALYSIS FLAGS
if(useMedian) outDirName = [outDirName '_Median']; end
if(~weightByFiberDensity) outDirName = [outDirName '_noFdWeight']; end
outDirName = [outDirName '_' num2str(nFiberSamps,'%02d')];
outDir = fullfile(baseDir, outDirName);
if(~exist(outDir,'dir')) mkdir(outDir); end
% Open a log file to hold all the textual details
logFile = fopen(fullfile(outDir,'log.txt'),'wt');
s=license('inuse'); userName = s(1).user;
fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, datestr(now,31));
fprintf(logFile, 'baseDir = %s\n', baseDir);

%% Load pre-processed data 
%
% (Created with dtiCallosalSegmentation)
load(fullfile(baseDir, ['ccLongitudinal_segData_' dc '.mat']));
sumFile = fullfile(baseDir, ['ccLongitudinal_' dc '_sum.mat']);

nBrains = size(fiberCC,1);
nSegs = size(fiberCC,2);
segNames = {segs.name};

%% CLEAN CC ROIs
%
% Clean up the CC ROIs by removing fiber crossing points that are too far
% from the CC ROI, filling holes, and eroding edge pixels (if desired).
% The resulting ROIs should each be a 1mm-spaced grid of voxel centers.
ccExtrema = [min([ccCoords{:}]')-1; max([ccCoords{:}]')+1];
ccSz = diff(ccExtrema)+1;
for(ii=1:nBrains)
    ccBox = zeros(ccSz);
    coords = double(ccCoords{ii});
    coords = round(coords-repmat(ccExtrema(1,:)',1,size(coords,2))+1);
	ccBox(sub2ind(ccSz, coords(1,:), coords(2,:))) = 1;
    ccBoxCleaned = imfill(ccBox==1,'holes');
    [x,y] = ind2sub(ccSz, find(ccBoxCleaned==1));
    coords = [x,y]';
    coords = coords+repmat(ccExtrema(1,:)',1,size(coords,2))-1;
    ccCoordsCleaned{ii} = coords;
end
clear ccCoords x y coords ccSz ccExtrema ccBoxCleaned;

nSampsAlongFiber = size(fiberCC(1,1,1).fiberCoord,3);
midFiberSamp = round((nSampsAlongFiber+1)/2);
if(nFiberSamps==1)
  fiberSampPts = midFiberSamp;
elseif(nFiberSamps<1)
  fiberSampPts = [1:nSampsAlongFiber];
else
  fiberSampPts = [midFiberSamp-nFiberSamps:midFiberSamp+nFiberSamps];
end

%
% EXTRACT DT6 VALUES FOR ANALYSIS
%
% Extract all midsaggital points that are within the cleaned CC
% ROI.
clear dt6 fiberYZ fiberNearestCC;
for(ii=1:nBrains)
  ccYZCoords{ii} = ccCoordsCleaned{ii}';
  for(jj=1:nSegs)
    for(hs=1:2)
      clear fiberYZ;
      tmp = fiberCC(ii,jj,hs).fiberCoord;
      fiberYZ(:,1) = squeeze(tmp(2,:,midFiberSamp));
      fiberYZ(:,2) = squeeze(tmp(3,:,midFiberSamp));
      [tmp,distSq] = nearpoints2d(double(fiberYZ'), double(ccYZCoords{ii}'));
      fiberNearestCC{ii,jj,hs} = single(tmp);
      goodPts = distSq < minDist.^2;
      % Exclude fibers with crazy points
      if(jj==2)
        % clean the temporal fibers by removing fibers with a
        % mid-sag crossing that is anterior of the AC (Y>0).
        badPts = fiberYZ(:,1)'>0;
        if(true)%any(badPts))
          msg = sprintf('Removing %d of %d points from %s in subject %s.',sum(badPts),length(goodPts),segNames{jj},datSum(ii).subCode);
          disp(msg);
          fprintf(logFile, msg);
          goodPts = goodPts&~badPts;
        end
      end
      fiberNearestCC{ii,jj,hs}(~goodPts) = [];
      if(~isempty(goodPts))
         for(kk=1:6)
            tmp = dt6Vals{ii,jj}(:,kk);
            dt6{ii,jj,hs}(:,:,kk) = tmp(dt6Inds{ii,jj,hs}(goodPts,fiberSampPts));
         end
      else
         dt6{ii,jj,hs} = [];
      end
    end
  end
end
clear tmp goodPts distSq badPts fiberYZ fiberSampPts 
clear hs dt6Inds dt6Vals fiberCC ccCoordsCleaned;

% Somehow, the dims get messed up when there is just one point:
bdCell = find(cellfun('size', dt6, 2)==1);
for(ii=bdCell'), dt6{ii} = permute(dt6{ii},[2 1 3]); end

%% SUMMARIZE SEGMENTS
%
% We collapse all fiber point measurements into one measurement per segment
% per subject. 
%
disp('Summarizing Segments...');
if(useMedian) avgFuncName = 'nanmedian'; 
else avgFuncName = 'nanmean'; end
fprintf(logFile, '\nCentral tendency function is "%s".\n', avgFuncName);
mnFa = ones([nBrains,nSegs])*NaN;
mnMd = ones([nBrains,nSegs])*NaN;
mnRd = ones([nBrains,nSegs])*NaN;
mnAd = ones([nBrains,nSegs])*NaN;
mnPdd = ones([nBrains,nSegs,3])*NaN;
mnSdd = ones([nBrains,nSegs,3])*NaN;
for(ii=1:nBrains)
  fprintf('Processing # %d of %d (%s)...\n',ii,nBrains,datSum(ii).subCode);
  for(jj=1:nSegs)
     % Combine the two hemisphere
     tmp = cat(1,dt6{ii,jj,1},dt6{ii,jj,2});
     tmp = reshape(tmp,size(tmp,1)*size(tmp,2),6);
     [vec,val] = dtiEig(double(tmp));
     val(val<0) = 0;
     [tmpFa,tmpMd,tmpRd] = dtiComputeFA(val);
     tmpAd = val(:,1);
     tmpPdd = vec(:,:,1);
     tmpSdd = vec(:,:,2);
     tmpEigVals = val;
     clear vec val;
     if(~weightByFiberDensity)
        [junk,uniquePdd] = unique(tmpPdd,'rows');
        [junk,uniqueEV] = unique(tmpEigVals,'rows');
        uniqueVals = intersect(uniquePdd,uniqueEV);
        tmpFa = tmpFa(uniqueVals);
        tmpMd = tmpMd(uniqueVals);
        tmpPdd = tmpPdd(uniqueVals,:);
        tmpSdd = tmpSdd(uniqueVals,:);
        tmpEigVals = tmpEigVals(uniqueVals,:);
      end
      n(ii,jj) = length(tmpFa);
      if(n(ii,jj)>0)
         mnFa(ii,jj) = feval(avgFuncName, tmpFa);
         mnMd(ii,jj) = feval(avgFuncName, tmpMd);
         mnAd(ii,jj) = feval(avgFuncName, tmpAd);
         mnRd(ii,jj) = feval(avgFuncName, tmpRd);
         % It doesn't make sense to average PDDs with mean or
         % median. The following will account for the fact that,
         % eg. [0 0 1] is equivalent to [0 0 -1]. Note that
         % dtiDirMean collapses across the 'subject' dimension (the
         % last dim), so we need the fancy reshaping to get it to do
         % what we want.
         tmpPdd = tmpPdd(all(~isnan(tmpPdd),2),:);
         [mnPdd(ii,jj,:),S] = dtiDirMean(shiftdim(tmpPdd',-1));
         % convert dispersion into an angle, in degrees
         dispPdd(ii,jj,:) = asin(sqrt(S))./pi.*180;
         tmpSdd = tmpSdd(all(~isnan(tmpSdd),2),:);
         [mnSdd(ii,jj,:),S] = dtiDirMean(shiftdim(tmpSdd',-1));
         dispSdd(ii,jj,:) = asin(sqrt(S))./pi.*180;
         mnEigVals(ii,jj,:) = feval(avgFuncName, tmpEigVals, 1);
      end
      % Compute the fiber intersection density for each point in the ccRoi
      nCcCoords = size(ccYZCoords{ii},1);
      ccYZDensity{ii,jj} = hist([fiberNearestCC{ii,jj,:}],[1:nCcCoords]);
  end
end
clear tmp tmpFa tmpMd tmpPdd tmpSdd tmpRd tmpAd fiberNearestCC;
clear dt6;

disp(['Saving summarized measurements to ' sumFile '...']);
save(sumFile);


