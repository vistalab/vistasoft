function [mv R] = mv_corrcoef(mv, removeMeans, autoScale);
% Display a matrix of correlation coefficients (from CORRCOEF)
% comparing response patterns to different conditions in a multivoxel struct.
%
% [mv R] = mv_corrcoef(mv, [removeMeans=0], [autoScale=0]);
%
% If removeMeans is set to 1, will remove the mean response across
% conditions for each voxel before running the cross-correlations.
%
% If autoScale is set to 1, will color the values in the matrix according
% to the data. Otherwise, will scale the colors to span the range [-1, 1].
% [The default is to not auto-scale].  With autoscaling, the code uses a
% jet colormap; otherwise it uses a custom blue-red colormap (see
% mrvColorMaps('bluered'). Either way, this can be overridden with the 
% COLORMAP command. 
%
% Note that the diagonal of this matrix is equal to 1, by definition
% (because it reflects correlating a response pattern to itself). To 
% test the reliability of each pattern as well as the confusability,
% use mv_reliability, which splits the data into two parts and tests them
% against one another.
%
% Returns the correlation coefficient matrix, R, as an optional second
% output argument.
%
% ras, 11/2007.
if notDefined('mv'),	mv = get(gcf, 'UserData');		end
if ishandle(mv),		mv = get(mv, 'UserData');		end

if notDefined('removeMeans'),	removeMeans = 0;		end
if notDefined('autoScale'),		autoScale = 0;			end


%% get amps 
% compute amps if needed
if ~isfield(mv, 'amps'),	mv.amps = mv_amps(mv);		end

% restrict to selected conditions
sel = find(tc_selectedConds(mv));
amps = mv.amps(:,sel-1);  % -1 b/c amps doesn't include null condition
n = size(amps, 2);  

% remove means if needed
if removeMeans==1
	amps = amps - repmat( nanmean(amps, 2), [1 n] );
end

%% compute the correlation coefficients
R = corrcoef(amps);

%% visualize
% delete existing axes
other = findobj('Type','axes','Parent',gcf);
delete(other);

% x- and y-tick labels for conditions
str = tc_condInitials(mv.trials.condNames);
str = str(sel);

% get cmap
if autoScale==1
	cmap = jet(256);
else
	cmap = mrvColorMaps('corr2', 256); 
end

% main image
subplot('Position', [.1 .1 .7 .8]);
if autoScale==1
	imagesc(R);
	clim = [min(R(:)) max(R(:))];
else
	imagesc(R, [-1 1]);
	clim = [-1 1];
end
axis square; 
colormap(cmap); 
set(gca, 'XTick', 1:n, 'XTickLabel', str, 'YTick', 1:n, 'YTickLabel', str);
xlabel('Condition', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);
ylabel('Condition', 'FontName', mv.params.font, 'FontSize', mv.params.fontsz);

% add a colorbar
cbar = cbarCreate(cmap, 'Correlation (\rho)', 'Clim', clim, ...
					'Font', mv.params.font, 'FontSize', mv.params.fontsz, ...
					'Direction', 'vert');
hCbar = subplot('Position', [.88 .1 .03 .8]);		
cbarDraw(cbar, hCbar);


return
