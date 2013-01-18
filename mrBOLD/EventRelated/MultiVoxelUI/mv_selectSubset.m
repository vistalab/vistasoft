function mvNew = mv_selectSubset(mv, X, metric, newUIFlag, varargin);
%
% mvNew = mv_selectSubset([mv, X, [metric='voxels'], [newUIFlag], [options]);
%
%
% Select a subset of voxels in a MultiVoxel UI,  to 
% start a new MVUI. This is intended as a callback to
% plots of classifier performance vs. number of voxels
% (see mv_sortByVoxR),  but can be called from the command
% line or generalized.
%
% mv: mv struct
%
% X: can refer to:
%   (1) set of indices of which voxels in the data to sub-select
%       (in which case the metric argument should be 'voxels')
%   (2) X location on axes / # of voxels to restrict with,  
%     sorted by the specified metric (see below).
%
% metric: metric to use. Could be: 
%   voxels: directly specify the indices of the voxels to select in X.
%   sig: significance level of a contrast. Can specify the active and
%        control conditions for the contrast as options, or else 
%        a dialog will ask for them. In this case, will select all
%        voxels for which -log(p) of the contrast is greater than X.
%   varExplained: proportion variance explained by a GLM on the data.
%   dprime: select voxels with a d' measure > X.
%   voxR: voxel reliability (mean odd-even correlation across conditions).
%   
%
% newUIFlag: if 1,  will open a new UI; if 0,  won't. If 2, will open 
%            a timeCourseUI instead. If 3, will open both an mvUI and
%            a tcUI.
% 
% ras,  09/2005.
if notDefined('mv'),  mv = get(gcf, 'UserData'); end
if notDefined('X'),  pt=get(gca, 'CurrentPoint'); X=pt(1); end
if notDefined('metric'),  metric = 'voxels'; end
if notDefined('newUIFlag')
        newUIFlag = 0;
end

%% figure out which voxels to keep
switch lower(metric)
    case {'sig' 'significance' '-logp' 'contrast'}
        if ~isfield(mv, 'glm'), mv = mv_applyGlm(mv); end
        if length(varargin) >= 2
            active = varargin{1};
            control = varargin{2};
        else
            q = {'Active Conditions' 'Control Conditions'};
            resp = inputdlg(q, mfilename, 1, {'1' '0'});
            active = str2num(resp{1});
            control = str2num(resp{2});
        end
        contrast = glm_contrast(mv.glm, active, control);
        keep = find(contrast> X);
        
    case {'varexp' 'varexplained' 'varianceexplained'}
        if ~isfield(mv, 'glm'), mv = mv_applyGlm(mv); end
        keep = find(mv.glm.varianceExplained > X);
    
    case {'voxr' }
        keep = find(mv.wta.voxR > X);
        
    case {'sel'}
        [scaledSel sel] = mv_selectivity(mv);
        keep = find(sel > X);
        
    case {'scaledsel'}
        [scaledSel sel] = mv_selectivity(mv);
        keep = find(scaledSel > X);
        
    case {'dprime'}
        dprime = mv_dprime(mv);
        keep = find(dprime > X);
        
    case {'voxels'}
        keep = X;
		
	case {'coords'}
		[commonCoords keep] = intersectCols(mv.roi.coords, X);
        
    case {'dialog' 'gui'}
        % put up a dialog to get metric
        dlg(1).fieldName = 'metric';
        dlg(1).string = 'Select voxels by which metric?';
        dlg(1).style = 'popup';
        dlg(1).list = {'sig' 'varexplained' 'dprime' 'voxR'};
        dlg(1).value = 2;
        
        dlg(2).fieldName = 'X';
        dlg(2).string = 'Cutoff value for metric:';
        dlg(2).style = 'edit';
        dlg(2).value = '.1';
        
        dlg(3).fieldName = 'newUI';
        dlg(3).string = 'Create a new UI for this subset';
        dlg(3).style = 'checkbox';
        dlg(3).value = 0;    
        
        resp = generalDialog(dlg);
        
        mvNew = mv_selectSubset(mv, str2num(resp.X), resp.metric, resp.newUI);
        return
        
end

% check that there are some voxels which satisfy the criterion
switch length(keep)
    case 0, 
        warning('No voxels satisfy the criterion.')
    case 1,
        warning('Only 1 voxel satisfies the criterion.')
    otherwise, 
        if prefsVerboseCheck==1
            fprintf('[%s] %i / %i voxels pass criterion\n', mfilename, ...
                    length(keep), size(mv.coords, 2));
        end
end

%% init output mv struct
mvNew = mv;

% remove any older UI information
if (newUIFlag > 0) & (isfield(mv, 'ui'))
    mvNew = rmfield(mvNew, 'ui');
end

% keep only voxels that satisfy the specified criteria
mvNew.tSeries = mvNew.tSeries(:,keep);
        
% also set roi coords to reflect only kept voxels
mvNew.coords = mvNew.coords(:,keep);
mvNew.roi.coords = mvNew.roi.coords(:,keep);

% If dprime was been computed for the original, also compute for the
% new mv struct:
if isfield(mv, 'dprime'), mvNew.dprime = mv_dprime(mvNew, [], 0); end

% recompute voxData matrix
mvNew.voxData = er_voxDataMatrix(mvNew.tSeries, mvNew.trials, mvNew.params);

% % recompute voxAmps matrix
% mvNew.voxAmps = er_voxAmpsMatrix(mvNew.voxData, mvNew.params);

if checkfields(mv, 'amps')
	try
		mvNew.amps = mvNew.amps(keep,:);
	end
end

% if a retinotopy model has been applied to these data,
% sort those fields as well (see mv_retinoModel):
if checkfields(mvNew, 'rm')		% basic pRF model fields
	try
		mvNew.rm.x0{1} = mvNew.rm.x0{1}(keep);
		mvNew.rm.y0{1} = mvNew.rm.y0{1}(keep);
		mvNew.rm.sigma{1} = mvNew.rm.sigma{1}(keep);
		mvNew.rm.beta{1} = mvNew.rm.beta{1}(keep);
		mvNew.rm.varexp{1} = mvNew.rm.varexp{1}(keep);
		mvNew.rm.residual = mvNew.rm.x0{1}(:,keep);
		mvNew.rm.patternR = mvNew.rm.patternR(keep);
		
		if checkfields(mvNew, 'rm', 'amps')
			% pRF predicted fields
			mvNew.rm.amps = mvNew.rm.amps(keep,:);
			% mvNew.rm.tSeries = mvNew.rm.tSeries(:,keep);
		end
		
	catch
		disp('Couldn''t grab retinotopy model params')
	end
end

if ~strncmp(mv.roi.name, 'Subset', 6)
	mvNew.roi.name = ['Subset of ' mv.roi.name];
end

% if a GLM has already been run on this, re-run it for the new subset
if isfield(mvNew, 'glm')
    mvNew = mv_applyGlm(mvNew);
end

%% start a new UI, or update existing UI controls, as appropriate:   
switch newUIFlag
	case 0
		% update existing UI controls (the GLM voxel slider)
		% to reflect the new subset of voxels
		if checkfields(mvNew, 'ui', 'glmVoxel')
			mrvSliderSet(mvNew.ui.glmVoxel, 'range', [1 length(keep)]);
		end
    
	case 1,		mvNew = mv_openFig(mvNew);
    
	case 2,		mv_makeTCUI(mvNew);
    
	case 3,		mvNew = mv_openFig(mvNew);
				mv_makeTCUI(mvNew);    
    
end

return


