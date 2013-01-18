function mv = mv_sortVoxels(mv, criterion, varargin);
%
% mv = mv_sortVoxels(mv, [criterion='sortrows'], [options]);
%
% Sorts the voxels in a multivoxel UI to provide a crude form
% of clustering.
%
% Criteria to use for sorting:
%	'amplitude', [cond]: sort each voxel by amplitude according to mv_amps.
%						If the optional cond argument is provided, will
%						sort according to the amplitude for the specified
%						condition; otherwise, will prompt the user to
%						select a condition.
%
%	'normamplitude', [cond]: like 'amplitude', but subtracts the mean
%						amplitude across conditions for each voxel (a la
%						Haxby et al, 2000).
%
%	'varexplained':		sort by variance explained according to a GLM.
%
%	'dprime':			sort by d' metric (see mv_dprime).
%
%	'metric', [metric]:	sort by a user-provided metric. This metric must
%						be provided as a third argument, and must be a
%						vector with length equal to the number of voxels in
%						the mv struct. The code will sort this metric, and
%						arrange each voxel according to their rank for this
%						metric.
%
% ras, 09/2006.
if notDefined('mv'), mv = get(gcf, 'UserData'); end
if notDefined('criterion'), criterion = 'sortrows'; end

switch lower(criterion)
    case {'sortrows' 'amplitude'}
        if isempty(varargin), col = 1; else, col = varargin{1}; end
        if isequal(col, 'dialog')
            q = {'Sort voxels according to which condition?'};
            col = inputdlg(q, mfilename, 1, {'1'});
            col = str2num(col{1});
        end
        [vals I] = sortrows(mv_amps(mv), col);
        
    case {'sortrowsnorm' 'normamplitude' 'normamp'}
		% like sortrows, but sort the amplitudes after subtracting the mean
		% amplitude for each voxel
		amps = mv_amps(mv);
		amps = amps - repmat(nanmean(amps, 2), [1 size(amps, 2)]);
        if isempty(varargin), col = 1; else, col = varargin{1}; end
        if isequal(col, 'dialog')
            q = {'Sort voxels according to which condition?'};
            col = inputdlg(q, mfilename, 1, {'1'});
            col = str2num(col{1});
        end
        [vals I] = sortrows(amps, col);
		
		
    case {'varexplained' 'varexp' 've' 'varianceexplained'}
        mv = mv_applyGlm(mv);
        [vals I] = sort(mv.glm.varianceExplained);
        
    case {'dprime' 'd'''}
        dprime = mv_dprime(mv);
        [vals I] = sort(dprime);
		
	case {'user' 'metric'}
		if isempty(varargin), error('Need a user-specified metric.');	end
		metric = varargin{1};

		if length(metric) < size(mv.coords, 2)
			error('Metric must correspond to voxels in the mv struct.')
		end
		
		[vals I] = sort(metric);
		
		
	otherwise,
		error('Invalid criterion.')
        
end

mv = mv_selectSubset(mv, I, 'voxels', 0);

if checkfields(mv, 'ui', 'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig, 'UserData', mv);
    multiVoxelUI;    
end

return
