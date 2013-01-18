function mv = mv_reliability(mv,varargin);
%
% mv = mv_reliability(mv,[options]);
%
% For MultiVoxel UI, perform Reliability Analysis
% using a winner-take-all classifier. 
%
% This code takes the data contained in the mv
% multi-voxel struct (grabs it off the current figure
% if it's not provided), subdivides the data into
% even and odd runs (or user-defined subsets), and 
% correlates the mean response amplitudes across 
% voxels for each condition. This will return a 
% matrix, corrRVals, of size nConditions by nConditions.
% The (i,jth) entry of corrRVals contains the correlation
% coefficient between the 
%
% The code then finds the
%
% 
%
% ras, 05/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

%%%%% default params
runList = unique(mv.trials.run);
odd = runList(1:2:end);   
even = runList(2:2:end);
sel = find(tc_selectedConds(mv))-1;
sel = sel(sel>0); % ignore null
names = mv.trials.condNames(sel+1); 
symmetric = 1;
tr = mv.params.framePeriod;
plotFlag = 1;

%%%%% parse the input options
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case 'user', 
                % user-defined params
                ui(1).string = 'Runs in subset A:';
                ui(1).fieldName = 'odd';
                ui(1).style = 'edit';
                ui(1).value = num2str(odd);

                ui(2).string = 'Runs in subset B:';
                ui(2).fieldName = 'even';
                ui(2).style = 'edit';
                ui(2).value = num2str(even);

                ui(3).string = 'Force subsets to have same # of runs';
                ui(3).fieldName = 'symmetric';
                ui(3).style = 'checkbox';
                ui(3).value = 1;

                ui(4).string = 'Method to Calculate Amplitudes?';
                ui(4).fieldName = 'ampType';
                ui(4).list = {'Peak-Bsl Difference', 'GLM Betas', 'Dot-product Relative Amps'};
                ui(4).style = 'popup';
                ui(4).value = ui(4).list{1};

                resp = generalDialog(ui,'Reliability Analysis');
                odd = str2num(resp.odd);
                even = str2num(resp.even);
                symmetric = resp.symmetric;
                ampInd = cellfind(ui(4).list,resp.ampType);
                opts = {'difference' 'betas' 'relamps'};
                params.ampType = opts{ampInd};

            case {'asymm','asymmetric'},
                % don't force even-odd subsets to have same # of runs
                symmetric = 0;    
            case {'glm','betas'},
                % use betas computed by GLM as amplitudes for each voxel
                params.ampType = 'betas';
            case 'relamps',
                % use dot-product relative amplitudes for each voxel
                params.ampType = 'relamps';
            case 'plotflag',
                plotFlag = varargin{i+1};
            case 'subsets'
                subsets = varargin{i+1};
                odd = subsets{1};
                even = subsets{2};
        end
            
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if symmetric flag is set, ensure same # of runs
% for even/odd subsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if symmetric==1
    odd = odd(1:length(even));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute a 2D voxels x conditions matrix of amplitudes
% based on the selected amplitude type
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
amps1 = mv_amps(mv,odd);
amps2 = mv_amps(mv,even);

sel = find(tc_selectedConds(mv))-1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run the WTA classifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv.wta = er_wtaClassifier(amps1,amps2,plotFlag.*[1 1 1],names);

% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
    figure(mv.ui.fig)
    multiVoxelUI; % refresh UI
end


return
