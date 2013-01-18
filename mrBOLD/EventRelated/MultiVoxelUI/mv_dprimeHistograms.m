function mv = mv_dprimeHistograms(mv, conds);
%
%  mv = mv_dprimeHistograms([mv], [conds]);
%
% Plot histograms of the d' metric (see mv_dprime) 
% distribution across voxels for the specified conditions
% (Uses the selected conditions for the mv if conds is
% omitted). Plots separate histograms for the subset of voxels
% which "prefer" (have the highest response amplitude for)
% each specified condition, and one for the overall distribution
% of d' across all voxels.
%
%
% ras, 01/2007.
if notDefined('mv'),    mv = get(gcf, 'UserData');              end
if notDefined('conds'), conds = find(tc_selectedConds(mv))-1;   end

nConds = length(conds);
[dprime prefCond] = mv_dprime(mv);

%% compute
% figure out reasonable number of bins
% (we want about 10 voxels per bin on average)
nVoxels = length(dprime);
nPrefConds = length( unique(prefCond) );
nBins = nVoxels / (nPrefConds * 10);

% set bin range, X
dpMin = min(dprime); 
dpMax = max(dprime);
binStep = (dpMax - dpMin) / nBins;
X = dpMin:binStep:dpMax;

% compute histogram numbers for each selected condition
for i = 1:nConds
    I = (prefCond==conds(i));
    N(:,i) = hist(dprime(I), X);
    tot(i) = sum(I);
    hi(i) = max(dprime(I));
    lo(i) = min(dprime(I));
    mu(i) = mean(dprime(I));
    sigma(i) = std(dprime(I));
end

% compute histogram vals across all voxels
N(:,nConds+1) = hist(dprime, X);

% get axis bounds for each histogram plot
AX = [0 nVoxels+1 dpMin dpMax];

%% display
% height of each subplot
h = 1 / (nConds + 2);

% titles for each text column

% plot bar graphs for each histogram, and add text annotation
for i = 1:nConds
    y1 = 1-(i+1)*h; % row start position
    subplot('Position', [.1 y1 .5 h]);
    
    bar(X, N(:,i), 'k');
    axis(AX);
    axis off    
    
    % cond name
    uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.6 y1 .06 h], ...
              'String', mv.trials.condNames{conds(i)+1}, ...
              'FontName', mv.params.font, 'FontSize', 9);
          
    % total # voxels
    uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.7 y1 .05 h], ...
              'String', num2str(tot(i)), ...      
              'FontName', mv.params.font, 'FontSize', 9);
          
    % min value
    uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.75 y1 .05 h], ...
              'String', sprintf('%1.2f', lo(i)), ...
              'FontName', mv.params.font, 'FontSize', 9);
          
    % mean +/-std value
    uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.8 y1 .06 h], ...
              'String', sprintf('%1.2f (%1.2f)', mu(i), sigma(i)), ...
              'FontName', mv.params.font, 'FontSize', 9);

    % max value
    uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.9 y1 .05 h], ...
              'String', sprintf('%1.2f', hi(i)), ...
              'FontName', mv.params.font, 'FontSize', 9);
          
end
          
end


return
