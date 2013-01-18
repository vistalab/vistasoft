function tcourses = classify_GetMeanTCs(file, trials)

load(file);

nVoxels = length(analysis);
nTrials = length(trials);
[nTimePoints nConds] = size(analysis(1).meanTcs);
tcourses.labels = strtrim(analysis(1).labels)';
tcourses.trials = trials;
tcourses.data = cell(nConds,1);

for i = 1:nConds
    tcourses.data{i} = zeros(nVoxels, nTimePoints);
    for ii = 1:nVoxels
       tcourses.data{i}(ii,:) = (sum(analysis(ii).allTcs(:, trials, i),2)/nTrials)';
       % eval(sprintf('tcourses.cond_%s(%d,:) = (sum(analysis(%d).alltcourses(:, trials, %d),2)/nTrials)'';', ...
       %     strtrim(analysis(i).labels{ii}), i, i, ii));
    end
end