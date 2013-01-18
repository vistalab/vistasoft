function anal = er_wtaClassifier(amps1,amps2,subtractDC,plotFlag,names);
%
% anal = er_wtaClassifier(amps1,amps2,[plotFlag],[names]);
%
% Apply a winner-take-all classifier to event-related
% data.
%
% [more description forthcoming]
%
% Input args: amps1 and amps2 should be of shape voxels x conditions:
% each column represents the pattern of response across voxels to a 
% given condition. (See mv_reliability for an example of how 
% to compute these.) 
%
% plotFlag: 1 x 3 vector to flag each of the following
% possible output plots:
%   1) image the amplitudes for each subset
%   2) summarize the reliability analysis
%   3) 'omnibus' contrast: regress mean response, across conditions,
%   from each subset
%
% subtractDC: option to subtract the baseline response
% across conditions for 
% 
% ras 05/05. Based on exp5_haxby, by ras 03/05.
if ieNotDefined('subtractDc')
    subtractDC = 0;
else 
    subtractDC
end

if ieNotDefined('plotFlag')
    plotFlag = [0 0 0];
else 
    plotFlag
end

if ieNotDefined('names')
    for i = 1:size(amps1,2)
        names{i} = num2str(i);
    end
end

if size(amps1) ~= size(amps2)
    error('amps1 and amps2 must be same size.')
end

nVoxels = size(amps1,1);
nConds = size(amps1,2);
font = 'Arial';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% omnibus test                    %
% (always do this before zeroing, %
% or you remove the effect)       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mu1 = mean(amps1,2);
mu2 = mean(amps2,2);
% ignore zeroed voxels
notzeroed = find(mu1~=0 & mu2~=0);
mu1 = mu1(notzeroed);
mu2 = mu2(notzeroed);
[R P] = corrcoef(mu1(:),mu2(:));
anal.omnibusR = R(1,2);
anal.omnibusP = P(1,2);
anal.mu1 = mu1;
anal.mu2 = mu2;


if subtractDC==1
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Normalize responses, in a manner similar   %
	% to Haxby et al 2001 -- subtract mean       %
	% response across conditions from each voxel %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	bsl1 = repmat(mean(amps1,2),1,size(amps1,2));
	usedAmps1 = amps1 - bsl1;
	bsl2 = repmat(mean(amps2,2),1,size(amps2,2));
	usedAmps2 = amps2 - bsl2;
else
    % use the non-corrected amps
    usedAmps1 = amps1;
    usedAmps2 = amps2;
end

% assign amplitude fields to anal struct
anal.amps1 = amps1;
anal.amps2 = amps2;
anal.usedAmps1 = usedAmps1;
anal.usedAmps2 = usedAmps2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% perform pairwise correlations between maps %
% in the first and second data sets          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:nConds 
    for j = 1:nConds 
        training = usedAmps1(:,i);
        test = usedAmps2(:,j);
        
        % remove NaNs
        ok = ~isnan(training) & ~isnan(test);
        if sum(ok)==0
            error('Too many NaNs in amplitudes.');
        end
        training = training(ok); test = test(ok);
        
        [R p] = corrcoef(training,test);
        anal.corrRvals(i,j) = R(1,2);
        anal.corrPvals(i,j) = p(1,2);        
    end
end

% % 02/22/05: kalanit suggested thresholding
% % the R vals, based on the p -- let's try it:
% anal.corrRvals(anal.corrPvals>0.05) = 0;

% as an ideal observer of activity patterns,
% 'guess' the image shown in the 2nd data set
% by looking at what provoked the most similar
% (by correlation) response from the 1st data set
for i = 1:nConds 
    anal.guess(i,:) = zeros(1,nConds);
    guess = find(anal.corrRvals(i,:)==max(anal.corrRvals(i,:)));
    anal.guess(i,guess) = 1;
    
    % guesses along the diagonal are correct -- the
    % highest-correlated pattern comes from the same image.
    % other guesses are mistakes.
    if isempty(guess), guess = 0; end
    anal.correct(i) = (guess(1)==i);
end
anal.pctCorrect = 100 * sum(anal.correct)/length(anal.correct);

% let's also compute the 'voxel reliability',the 
% correlation value for each voxel of the set of nConds
% response amplitudes between the two subsets:
for v = 1:nVoxels
    [R p] = corrcoef(anal.amps1(v,:),anal.amps2(v,:));
    voxR(v) = R(1,2);
end
anal.voxR = voxR;

% calculate mean correlations for same image,
% diff image but same cat, diff cat:
nImgs = nConds; %length(1:nConds);
group = 3*ones(nImgs,nImgs); % diff cat 
for i = 1:nImgs
    for j = 1:nImgs
        if ceil(j/4)==ceil(i/4)
            group(i,j) = 2; % same cat
        end
    end
    group(i,i) = 1;  % same img
end

anal.group = group;
anal.meanR = [];
anal.semR = [];
for j = 1:3
    anal.meanR(j) = mean(anal.corrRvals(group==j));
    nObs = sum(group(:)==j);
    anal.semR(j) = std(anal.corrRvals(group==j))/sqrt(nObs-1);
    try
        [H p] = ttest2(anal.corrRvals(group==j),anal.corrRvals(group==3));
    catch
        H = 0; p = 1;
    end
    anal.sigDiffR(j) = H;
    anal.pvalR(j) = p;
end


%%%%%%%%%%%%%%%%%%%%%
% plot the results  %
%%%%%%%%%%%%%%%%%%%%%
% Amplitude plots
if plotFlag(1)==1
	anal.h1 = figure('Name','Amplitudes From Each Half of Data',...
                    'Units','Normalized','Position',[.7 .8 .3 .18],...
                    'MenuBar','none',...
                    'Color','w'); % [0 .4 .7 .4]
	colormap jet

    minVal = min([min(anal.amps1(:)) min(anal.amps2(:))]);
	maxVal = max([max(anal.amps1(:)) max(anal.amps2(:))]);

    subplot('Position',[.1 .15 .35 .75])
	imagesc(anal.amps1,[minVal maxVal]); 
	set(gca,'XTick',1:nConds,'XTickLabel',names);
	ylabel('Voxels');
    title('Subset 1 (Training)')
    set(gca,'FontName',font,'FontSize',10);

    subplot('Position',[.5 .15 .35 .75])
	imagesc(anal.amps2,[minVal maxVal]);
	set(gca,'XTick',1:nConds,'XTickLabel',names,'YTick',[]);
	ylabel('Voxels');
    title('Subset 2 (Test)');
    set(gca,'FontName',font,'FontSize',10);

	
    hcb = subplot('Position',[.9 .2 .03 .6]);
    colorbar(hcb);
    ylabel('Response Amplitude, % Signal');
    set(gca,'FontName',font,'FontSize',10);
end

% reliability summary
if plotFlag(2)==1
	anal.h2 = figure('Name','Reliability Amps Results',...
                'Color','w','MenuBar','none','Units','Normalized',...
                'Position',[.7 .6 .3 .18]); % [.1 .2 .7 .7]
	subplot(2,2,1);
	imagesc(anal.corrRvals); % colorbar;
	set(gca,'XTick',1:nConds,'XTickLabel',names,...
            'YTick',1:nConds,'YTickLabel',names);
	set(gca,'FontName',font,'FontSize',10);
	xlabel('First Half');
	ylabel('Second Half');
	title('Correlation Coefficient R');
	
    subplot(2,2,2);
	imagesc(anal.guess); % colorbar;
	set(gca,'XTick',1:nConds,'XTickLabel',names,...
            'YTick',1:nConds,'YTickLabel',names);
	set(gca,'FontName',font,'FontSize',10);
	xlabel('First Half');
	ylabel('Second Half');
	title('Ideal Observer Best Guess');
	
    subplot(2,2,3);
	starbar(anal.meanR,anal.semR,anal.sigDiffR);
	grps = {'Same Image' 'Same Category' 'Different Category'};
	set(gca,'XTickLabel',grps);
	set(gca,'FontName',font,'FontSize',10);
	ylabel('Mean R Value');

    subplot(2,2,4);
	table = {'Percent Correct:'; num2str(anal.pctCorrect)};
	plotTable(table);
end

% 'omnibus' test
if plotFlag(3)==1
	anal.h3 = figure('Color','w','MenuBar','none','Units','Normalized',...
                     'Position',[.7 .4 .2 .18]);
	regressPlot(mu1,mu2);
	set(gca,'FontName',font,'FontSize',10);
	axis equal
	axis square
	xlabel('Amplitude, Odd Runs','FontName','Helvetica','FontSize',nConds);
	ylabel('Amplitude, Even Runs','FontName','Helvetica','FontSize',nConds);
	ttltxt = sprintf('Amplitudes Across All Images');
	title(ttltxt,'FontName','Helvetica','FontSize',14);
end

return
