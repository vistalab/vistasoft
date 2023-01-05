function view = makeCorAnalFields4Map(view);
% view = makeCorAnalFields4Map(view);
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
% ras, 05/04: in addition to some code correction, renamed the function
% 'makeCorAnalFields4Map'.

% grab the relevant view fields
ph = viewGet(view,'ph');
amp = viewGet(view,'amp');
co = viewGet(view,'co');
map = viewGet(view,'map');

% if isempty(co) & isempty(ph) & isempty(amp)
% 	% load any existing corAnal, so it doesn't get overwritten
%     % (disabled, I HATE corAnals)
% 	view = loadCorAnal(view);
%     ph = viewGet(view,'ph');
%     amp = viewGet(view,'amp');
%     co = viewGet(view,'co');
% end

for i = 1:length(map)
    % only copy parameter map for scans which 
    % have them (don't copy empty maps)
    if ~isempty(map{i}) 
        % run a series of tests to see if the ph field is assigned
        % (I'm assuming if it's assigned, the other 2 fields are as well)
        assignedCheck = (~isempty(ph) & length(ph)==numScans(view));
        if assignedCheck    assignedCheck = ~isempty(ph{i});    end
        
        if ~assignedCheck
            amp{i} = view.map{i};
            ph{i} = zeros(size(map{i}));
            
            % scale positive values only of map onto cothresh--
            % this is not a meaningful mapping, just a loose approximation
            % of the statistical strength of the map (if you want to look
            % at negative correlations only, will need to look at parameter
            % map, for which the values are meaningful)
            maxVal = max(max(max(map{i})));
            co{i} = map{i}./maxVal;
        end
    end
end

% make sure amp, co, and ph are padded out to the right number
% of scans
if length(amp) < length(map)
    amp{length(view.map)} = [];
    ph{length(view.map)} = [];
    co{length(view.map)} = [];
end

% assign back to view
view = viewSet(view,'amp',amp);
view = viewSet(view,'co',co);
view = viewSet(view,'ph',ph);

% % maybe want to save the corAnal (disabled)
% pathStr=fullfile(dataDir(view),'corAnal.mat');
% fprintf('Saving %s...',pathStr);
% save(pathStr,'co','ph','amp');
% fprintf('done.\n');

return