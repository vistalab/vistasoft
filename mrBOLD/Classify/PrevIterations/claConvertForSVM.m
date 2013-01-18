function tcourses_svm = classify_ConvertForSVM(tcourses, trials)

nConds = length(tcourses.labels);
[nVoxels nTimePoints] = size(tcourses.data.conditions(1).trials{1});
nEntries = nTimePoints*nVoxels;
nTrials = length(trials);
tcourses_svm.trials = trials;
tcourses_svm.labels = tcourses.labels;
tcourses_svm.label_vector = (1:(nConds*nTrials))';
tcourses_svm.instance_matrix = zeros(nConds,nEntries);

condIndex = 0;
for cond = 1:nConds
    for trial = trials;
        condIndex = condIndex + 1;
        tcourses_svm.label_vector(condIndex) = cond;
        tcourses_svm.instance_matrix(condIndex,:) = ...
            reshape(tcourses.data.conditions(cond).trials{trial}',[1 nEntries]);
    end
end