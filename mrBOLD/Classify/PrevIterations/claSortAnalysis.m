function tcourses = classify_SortAnalysis(analysis)

nVoxels = length(analysis);
[nTimePoints nConds] = size(analysis(1).meanTcs);
tcourses.labels = strtrim(analysis(1).labels)';

for cond = 1:nConds
    nTrials = length(analysis(1).allTcs(1,~isnan(analysis(1).allTcs(1,:,cond)),cond));
    tcourses.data.conditions(cond).trials = cell(nTrials, 1);
    for trial = 1:nTrials
        tcourses.data.conditions(cond).trials{trial} = zeros(nVoxels,nTimePoints);
        for voxel = 1:nVoxels
            tcourses.data.conditions(cond).trials{trial}(voxel,:) = ...
                analysis(voxel).allTcs(:, trial, cond)';
        end
    end
end
