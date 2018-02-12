function anal = er_chopTSeries3D(tSeries,trials,roiName,varargin);
% anal = er_chopTSeries3D(tSeries,trials,roiName,varargin);
% 
%
% View-independent verson of er_chopTSeries.
% chops up entered tSeries according to the assigned parfiles.
%
% Inputs are tSeries (matrix where rows are time points, cols are
% different tSeries, say from diff't rois/voxels), and trials
% (a struct obtained from er_concatParfiles, containing design matrix
% information).
%
% returns an analysis struct with the following fields:
%
%  
%   allTcs4D:   4D matrix of size nVoxelsXwindowlengthxnCondsXnreps
%               time courses for each voxel, condition, repetition.
%               The data is taken from the specified
%               time window, incl. prestim frames.
%   meanTcs:    matrix of mean time courses for each condition. Rows 
%               are different time points, columns are different conds.
%   timeWindow: vector specifying the time in seconds, relative to the
%               trial onset, from which each trial / mean trial time 
%               course is taken. [default is -4:16].
%   peakPeriod: time, in seconds, where the HRF is expected to peak.
%               This will be used for t-test and amplitude results below.
%               [default is 8:14].
%   bslPeriod:  time, in seconds, to consider as a baseline period. 
%               [default is 2:6].
%   allamps:    Estimated amplitudes for each trial, taken
%               as the mean amplitude during the peak period
%               minus the mean amplitude during the baseline period.
%               This is a 3D matrix voxels X nConds X nreps
%               
%   Hs:         1 x nConds binary vector reflecting whether
%               each condition had a mean significant activation
%               during peak relative to baseline periods
%               (one-sided t-test alpha = 0.05 by default but
%               may be entered as an optional argument).
%   ps:         Corresponding p-values for the t-tests for Hs.
%
%
% Many params can be entered as optional arguments. In these cases,
% call them with the form ...'arg name',[value],.... The fields
% that can be entered are: timeWindow, peakPeriod, bslPeriod, alpha.
%
% Further options:
%   barebones:          do only a minimal analysis, extracting
%                       mean time courses, amplitudes, and SEMs.
%                       This is useful for across-voxel analyses.
%
%   normBsl,[1 or 0]:   if 1, will align trials during the baseline
%                       period [default is 1].
%   alpha,[val]:        alpha value for t-tests [default 0.05].
%   onsetDelta,[val]:   automatically shift the onsets in parfiles
%                       relative to the time course by this amount
%                       (e.g. to compensate for HRF rise time).
%   'mrvWaitbar':          put up a mrvWaitbar instead of showing progress in
%                       the command line.
%   'findPeaks':        when calculating response amplitudes, figure
%                       out the peak amplitude separately for each 
%                       condition, taking the peak and surrounding 2 points.
%   [params struct]:    input a struct containing all of these
%                       params. See er_getParams.
%
% 06/17/04 ras: wrote it.
% 07/28/04 ras: clarified annotation.
% 01/25/05 ras: can now input params struct.

%%%%% params/defaults %%%%%
barebones = 0;          % if 0, do full analysis; if 1, do minimal analysis
normBsl = 0;            % flag to zero baseline or not
alpha = 0.05;           % threshold for significant activations
bslPeriod = -6:0;       % period to use as baseline in t-tests, in seconds
peakPeriod = 6:12;       % period to look for peaks in t-tests, in seconds
timeWindow = -6:22;     % seconds relative to trial onset to take for each trial
onsetDelta = 0;         % # secs to shift onsets in parfiles, relative to time course
snrConds = [];          % For calculating SNR, which conditions to use (if empty, use all)
waitbarFlag = 0;        % flag to show a graphical mrvWaitbar to show load progress
findPeaksFlag = 0;      % when computing amps, find peak period separately for each cond
TR = trials.TR;

%colors = {'r' 'm' 'c' 'b' 'g' 'y' 'b'};  % for categories in general
colors2 = {[1 0 0],    [0.7 0 .0],[ 1 0  1 ],[.5 0 0.5]...
            [ 0 .8 .8], [0 .5 .5],[ 0  0  1 ],[0 0 .5],...
            [.5 .5 0] , [ 1 .5 0] ,[ 1 1 0] , [1 1 .5]};
           % for joint category / rep condition

%%%%% parse the options %%%%%
varargin = unNestCell(varargin);
for i = 1:length(varargin)
   if isstruct(varargin{i})
        % assume it's a params struct
        names = fieldnames(varargin{i});
        for j = 1:length(names)
            cmd = sprintf('%s = varargin{i}.%s;',names{j},names{j});
        end
            
    elseif ischar(varargin{i})
        switch lower(varargin{i})
            case 'normbsl', normBsl = varargin{i+1};
            case 'alpha', alpha = varargin{i+1};
            case 'peakperiod', peakPeriod = varargin{i+1};
            case 'bslperiod', bslPeriod = varargin{i+1};
            case 'timewindow', timeWindow = varargin{i+1};
            case 'onsetdelta', onsetDelta = varargin{i+1};
            case 'snrconds', snrConds = varargin{i+1};
            case 'whichconds', whichconds=varargin{i+1};
            case 'plotampsmat',plotampsmat=varargin{i+1}; 
            case 'mrvWaitbar', waitbarFlag = 1;
            case 'findpeaks', findPeaksFlag = 1;
            otherwise, % ignore
        end
    end
end

%%%%% account for format of time series
% in this code compared to elsewhere (dumb, I know, but there's a reason)

% account for onset shift
if mod(onsetDelta,TR) ~= 0
    % ensure we shift by an integer # of frames
    onsetDelta = TR * round(onsetDelta/TR);
end
trials.onsetSecs = trials.onsetSecs + onsetDelta;
trials.onsetFrames = trials.onsetFrames + onsetDelta/TR;

   
%%%%% get nConds from trials struct
condNums = unique(trials.cond(trials.cond > 0)); % do not include baseline cond which is zero
nConds = length(condNums);
if ~exist('whichconds')
    whichconds=condNums;
end
%%%%% get a set of label names, if they were specified in the parfiles
for i = 1:nConds
    ind = find(trials.cond==condNums(i));
    labels{i} = trials.label{ind(1)};
end

%%%%% convert params expressed in secs into frames
frameWindow = unique(round(timeWindow./TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(peakPeriod./TR));
bslFrames = unique(round(bslPeriod./TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));

%%%%% build allTcs matrix of voxels x frameWindow*nCOnd x  reps per cond
%%%%% take (frameWindow) secs from each trial

[ntps, nVoxels]=size(tSeries);
tSeries=tSeries';
nreps=0;
for i = 1:nConds % cond 0 is baseline cond
   ind = find(trials.cond==i);
   nreps=max([nreps, length(ind)]);
end
windowlength=length(frameWindow);
allTcs3D = zeros(nVoxels,windowlength*nConds,nreps);
allTcs4D= zeros(nVoxels,windowlength,nConds,nreps);

for i = 1:nConds
   cond = condNums(i);
   ind = find(trials.cond==cond);
   for j = 1:length(ind)
       tstart = max(trials.onsetFrames(ind(j)),1);
       tend = min([tstart+frameWindow(end),ntps]);
       rng = tstart:tend;

       % add prestim
       if tstart < prestim+1
           % for 1st trial, no baseline available -- set to 0
           allTcs3D(:,(i-1)*windowlength+1:i*windowlength,j) = [zeros(nVoxels,prestim) tSeries(:,rng)];
           allTcs4D(:,1:length(fullrng),i,j)=[zeros(nVoxels,prestim) tSeries(:,rng)];
       else
           % augment the range by previous [prestim] frames
           fullrng = rng(1)-prestim:rng(end);
           if length(fullrng)<windowlength
               allTcs3D(:,(i-1)*windowlength+1:(i-1)*windowlength+length(fullrng),j) = tSeries(:,fullrng);   
               allTcs4D(:,1:length(fullrng),i,j)=tSeries(:,fullrng);
           else
              allTcs3D(:,(i-1)*windowlength+1:i*windowlength,j) = tSeries(:,fullrng);   
              allTcs4D(:,:,i,j)=tSeries(:,fullrng);
          end
       end
%     allTcs4D= zeros(nVoxels,windowlength,nConds,nreps);
       if normBsl
           % estimate DC offset by prestim baseline vals
             DC = mean(allTcs4D(:,bslFrames,i,j),2);
             allTcs4D(:,:,i,j) = allTcs4D(:,:,i,j) - DC*ones(1,windowlength);
             allTcs3D(:,(i-1)*windowlength+1:i*windowlength,j)=allTcs3D(:,(i-1)*windowlength+1:i*windowlength,j)-DC*ones(1,windowlength);
       end
   end 
end 

%%%%% find 'empty' trials, set to NaNs
% (Empty trials will result if some conditions have more
% trials than others -- in the conditions w/ fewer trials,

%%%%% get mean time courses, sems for each condition across trial repeats
meanTcs3D = mean(allTcs3D,3); 
sems3D = std(allTcs3D,0,3)/sqrt(nreps-1);
meanROItc=mean(meanTcs3D,1); 
semROI = std(meanTcs3D,0,1)/sqrt(nVoxels-1); 
semROI=reshape(semROI,windowlength,nConds);
meanROItc=reshape(meanROItc,windowlength,nConds); %each cond is a column

% remove DC from each voxel
voxelDC=mean(mean(allTcs3D,3),2); % dc value for each voxel 
allamps=mean(allTcs4D(:,peakFrames,:,:),2); % 3D matrix voxels X amps X nConds
allamps=reshape(allamps, nVoxels, nConds, nreps);

voxelDCmat=zeros(nVoxels, nConds, nreps);
for i=1:nConds
    for j=1:nreps
        voxelDCmat(:,i,j)=voxelDC;
    end
end
allampsminusDC=allamps-voxelDCmat; % each voxel minus DC value;
meanamps=mean(allamps, 3); % 2D matrix voxels X meanamps



%%%%%%%%%%%%% PLOT Results %%%%%%%%%%%%%%%%%%
%% calculate voxel based statistics
if plotampsmat
    fig1 = figure('Name','mean Voxel amps ',...
              'Units','Normalized',...
              'Position',[0.0 0.05 .5 .15],...
              'Color',[1 1 1]);
    imagesc(meanamps', [ 0 mean(max(meanamps))]);colorbar; colormap(jet);
    xlabel('voxel #'); set(gca, 'Ytick', [1:1:length(labels)], 'YtickLabel', labels,'Fontsize',8);
    
    
    fig3 = figure('Name','mean Voxel ampsminus DC ',...
              'Units','Normalized',...
              'Position',[0.5 0.05 .5 .15],...
              'Color',[1 1 1]);
    imagesc(mean(allampsminusDC,3)', [ 0 mean(max(meanamps))]);colorbar; colormap(jet);
    xlabel('voxel #'); set(gca, 'Ytick', [1:1:length(labels)], 'YtickLabel', labels,'Fontsize',8);
end
% plot mean amplitudes for each condition

fig2 = figure('Name','mean ROI data ',...
              'Units','Normalized',...
              'Position',[0.5 0.5 .5 .3],...
              'Color',[1 1 1]);
    % mean tc
subplot (1,2,1)
twmat=[];hold
for i=1:length(whichconds)   
%    twmat=[twmat frameWindow'];
    htmp=errorbar(TR*frameWindow',meanROItc(:,whichconds(i)),semROI(:,whichconds(i)));
    set(htmp,'LineWidth',1.5,'Color',colors2{whichconds(i)});
end
hold 
axis('tight')
xlabel('time [s]'); ylabel('% signal from baseline'); %legend(labels);
% mean amps
subplot(1,2,2);
hold on
roiamps=mean(allamps,1); % mean across voxels
roiamps=reshape(roiamps,nConds,nreps);
for i = 1:length(whichconds)
	Y = mean(roiamps(whichconds(i),:));
	E = std(roiamps(whichconds(i),:)) ./ sqrt(nreps); 
    H = ttest(roiamps(whichconds(i),:)',0,alpha,'right'); % test if significantly greater than baseline     
	starbar(Y,E,H,'color',colors2{whichconds(i)},'X',i);
end
set(gca,'XTick',[1:length(whichconds)],'XTickLabel',labels(whichconds)); 
ylabel('Mean Amplitude, % Signal');
hold off
if ~exist('Results')
        mkdir 'Results'
 end
 fileName=[roiName 'MeanTC']
 savePath = fullfile(pwd,'Results',fileName)
 exportfig(gcf,savePath,'Format','jpeg','Color','cmyk');



h = mrvWaitbar(0,'calculating voxel based statistics');
voxelhist=zeros(nConds,1);
sigvoxels=zeros(nVoxels,nConds);
pictspervoxel=zeros(nVoxels,1);
for j = 1:nConds
    for i =1: nVoxels
        H = ttest(allamps(i,j,:),0,alpha,'right'); % test if significantly greater than baseline     
        if H==1
            sigvoxels(i,j)=1;
            voxelhist(j)=voxelhist(j)+1;
        end
    end
    mrvWaitbar(j/nConds,h)
end
close(h)
voxelhist=voxelhist/nVoxels;
fig4 = figure('Name','Voxel-based statistics ',...
              'Units','Normalized',...
              'Position',[0.0 0.5 .7 .3],...
              'Color',[1 1 1]);
 subplot (1,3,1)
 bar(voxelhist(whichconds));axis('square');
 set(gca,'XTick',[1:nConds],'XTickLabel',labels);    
 ylabel ('percent responsive voxels');
 pictspervoxel=sum(sigvoxels(:,whichconds),2); % sum in each row
 subplot (1,3,2)
 hist(pictspervoxel); axis('square');        
 ylabel ('number of voxels'); xlabel ('number of conditions')
 subplot(1,3,3)
 Nwhichconds=length(whichconds);
 voxcorrmat=zeros(Nwhichconds, Nwhichconds,nVoxels);
 for i=1:nVoxels
       for j=1:Nwhichconds;
           cond=whichconds(j);
           for k=j:Nwhichconds
                voxcorrmat(j,k,i)=sigvoxels(i,whichconds(j))*sigvoxels(i,whichconds(k));
                voxcorrmat(k,j,i)=voxcorrmat(j,k,i);
            end
        end
 end
 rsigvox=sum(voxcorrmat,3)/nVoxels; % sum across voxels              
 imagesc(rsigvox);axis('image'); colorbar; colormap(hot);
 set(gca, 'Ytick', [1:Nwhichconds],'YtickLabel', labels(whichconds),'Fontsize',8);
set(gca, 'Xtick', [1:Nwhichconds], 'XtickLabel', labels(whichconds),'Fontsize',8);
 if ~exist('Results')
        mkdir 'Results'
 end
 fileName=[roiName 'PercentResponsive']
 savePath = fullfile(pwd,'Results',fileName);
 exportfig(gcf,savePath,'Format','jpeg','Color','cmyk');

anal.allamps=allamps;
anal.allampsminusDC=allampsminusDC;
anal.meanamps=meanamps;
anal.allTcs4D=allTcs4D;
anal.meanROItc=meanROItc;
anal.semROI=semROI;
anal.timeWindow=timeWindow;
anal.frameWindow=frameWindow;
anal.peakFrames=peakFrames;
anal.bslFrames=bslFrames;
anal.TR=TR;
anal.labels=labels;
anal.sigvoxels=sigvoxels;
anal.voxelhist=voxelhist;
anal.pictspervoxel=pictspervoxel;
anal.rsigvox=rsigvox;
