function view = makeCorAnalFields4MeanMap(view);
% view = makeCorAnalFields4MeanMap(view);
% 
% mrLoadRet can be quite snobbish about parameter maps
% that are 'unescorted' by corresponding co/amp/ph fields
% for the same scan. Rather than find all the code which
% assumes these fields will be there and fix them, it seems
% easier to make this code, which adds these fields to any
% scan with an assigned parameter map.
%
% For these scans, the code assigns a co field that reflects
% the normalized amplitude of whatever is in the parameter map 
% (so the cothresh button does restrict the param map); the ph 
% field is all zeros, and the amplitude fields is the same as
% the map field. 
%
% For future uses (such as contrast maps), it may make sense to 
% add further flexibility to this -- for instance, some GLM/contrast 
% map code will provide a map of an estimated contrast effect size 
% (difference between different stimulus conditions), as well as
% a statistic of how good the GLM fitting is. In this case, it makes
% sense to color code the amplitude of effect, but restrict to voxels
% satisfying a slideable statistical criterion, in the same way we can
% color code fitted sinewave amplitudes but restrict to a certain
% coherence criterion.
%
% ras, 10/02

if isempty(view.co) & isempty(view.ph) & isempty(view.amp)
	% load any existing corAnal, so it doesn't get overwritten
	view = loadCorAnal(view);
end

for i = 1:length(view.map)
    % only copy parameter map for scans which 
    % have them (don't copy empty maps)
    if ~isempty(view.map{i}) 
        if isempty(view.co) | (~isempty(view.co) & isempty(view.co{i}))
            view.amp{i} = view.map{i};
            view.ph{i} = zeros(size(view.map{i}));
            
            % scale positive values only of map onto cothresh--
            % this is not a meaningful mapping, just a loose approximation
            % of the statistical strength of the map (if you want to look
            % at negative correlations only, will need to look at parameter
            % map, for which the values are meaningful)
            maxVal = max(max(max(view.map{i})));
            view.co{i} = view.map{i}./maxVal;
        end
    end
end

% make sure amp, co, and ph are padded out to the right number
% of scans
if length(view.amp) < length(view.map)
    view.amp{length(view.map)} = [];
    view.ph{length(view.map)} = [];
    view.co{length(view.map)} = [];
end

% % maybe want to save the corAnal (disabled)
% amp = view.amp;
% ph = view.ph;
% co = view.co;
% pathStr=fullfile(dataDir(view),'corAnal.mat');
% fprintf('Saving %s...',pathStr);
% save(pathStr,'co','ph','amp');
% fprintf('done.\n');

return