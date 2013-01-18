function mv = mv_removeOutliers(mv,criterion,thresh,plotFlag);
%
% mv = mv_removeOutliers([mv,criterion,thresh,plotFlag]);
%
% Remove outlier voxels, whose extreme values lie
% beyond a certain threshold. This threshold
% can either be a certain # of standard deviations
% away from the mean, or greater/less than a certain
% absolute value. 
%
% criterion is 0 (count standard deviations  criterion) or 1 
% (use abs value criterion). thresh is the threshold # of S.D.s or
% threshold value to use.. Omitting either brings up a dialog.
%
% after removing voxels, the mv struct is re-initialized.
%
% ras 05/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

plotFlag = 0;

if ieNotDefined('thresh') | ieNotDefined('criterion')
	ui(1).string = 'Threshold value:';
	ui(1).fieldName = 'thresh';
	ui(1).style = 'edit';
	ui(1).value = '1';

	ui(2).string = 'Criterion:';
	ui(2).fieldName = 'criterion';
	ui(2).list = {'Standard Deviations from Mean' 'Absolute % Signal'};
	ui(2).style = 'popup';
	ui(2).value = 1;
    
    ui(3).string = 'Report on response distributions';
    ui(3).fieldName = 'plotFlag';
    ui(3).style = 'checkbox';
    ui(3).value = 0;
    
	resp = generalDialog(ui,'Remove Outliers');
    thresh = str2num(resp.thresh);
    criterion = cellfind(ui(2).list,resp.criterion)-1;
    plotFlag = resp.plotFlag;
end

amps = mv_amps(mv);

% find outliers, based on specified criterion
switch criterion
    case 0, % remove voxels w/ mean > thresh std. deviations from
        amps = permute(nanmean(amps),[3 2 1]);
        sigma = nanstd(abs(amps(:)));
        mu = nanmean(abs(amps));
        muTotal = nanmean(abs(amps(:))); % overall mean across voxels
        outliers = find(mu>muTotal+thresh*sigma);
    case 1, % tSeries extends greater than thresh pct. signal
        [rows cols] = find(abs(mv.tSeries) > thresh);
        outliers = unique(cols);
end

% first, check that not ALL voxels are outliers...
if length(outliers)==size(mv.roi.coords,2)
    msg = ['Warning: Given the selected criteria, ALL voxels '...
           'were found to be outliers! No action taken.'];
    mrMessage(msg);
    return
end

% report the # and location of outliers found
fprintf('%i Outlier Voxels Found. \n',length(outliers));
% fprintf('Locations: \n ');
% for i = 1:length(outliers)
%     fprintf('\t %s \n', num2str(mv.roi.coords(:,i)));
% end
% fprintf('\n')


% keep only voxels that aren't outliers
keep = setdiff(1:size(mv.tSeries,2),outliers);
mv.tSeries = mv.tSeries(:,keep);

% also set roi coords to reflect only kept voxels
mv.coords = mv.coords(:,keep);
mv.roi.coords = mv.roi.coords(:,keep);

% plot distributions if selected
if plotFlag==1
    h = figure;
    subplot(211);
    if criterion > 0,
        amps = permute(nanmean(mv.voxAmps),[3 2 1]);
    end
    hist(amps(:),100);
    title('Before')    
end

% recompute voxData matrix
mv.voxData = er_voxDataMatrix(mv.tSeries,mv.trials,mv.params);

% recompute voxAmps matrix
mv.voxAmps = er_voxAmpsMatrix(mv.voxData,mv.params);

% plot distributions if selected
if plotFlag==1
    figure(h);
    subplot(212);
    newAmps = permute(nanmean(mv.voxAmps),[3 2 1]);
    hist(newAmps(:),100);
    title('After')    
    xlabel('Amplitude, % Signal')
    ylabel('# Voxels')
    
    figure(mv.ui.fig);
end


% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
    multiVoxelUI; % refresh UI
end

return