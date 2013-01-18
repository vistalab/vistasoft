function anal = er_2afcClassifier(voxData,subsetA,subsetB);
%
% anal = er_2afcClassifier(voxData,subsetA,subsetB);
%
% [description later]
%
%
%
% ras 05/05.
if ieNotDefined('subsetA') | ieNotDefined('subsetB')
    % choose odd/even trials    
    totalTrials = size(voxData,2);
    subsetA = 1:2:totalTrials;
    subsetB = 1:2:totalTrials;
    subsetA = subsetA(1:length(subsetB));
end

% subdivide voxel data into training and test sets
training = voxData(:,subsetA,:,:);
test = voxData(:,subsetB,:,:);

% compute the mean response across trials for each voxel
% in the training set
training = nanmeanDims(training,2);

nFrames = size(test,1);
nTrials = size(test,2);
nVoxels = size(test,3);
nConds = size(test,4);

% for now, I'm assuming a convenient format for
% my Hires E-R tests: 12 image conditions, plus a 
% novel-image condition against which each is tested.
% This will be revised down the line, probably.
bsl = 13;
nConds = 12;

% loop across conditions, generating evidence
% vectors for that condition and a comparison
% conditions (currently bsl=13) by corelating the
% data in the test set against the response in the
% training set
for i = 1:nConds
    % grab a 'training vector' of the mean response
    % to this condition in the training set, size
    % nVoxels*nFrames x 1
    trainVec = training(:,:,:,i);
    trainVec = trainVec(:);
    
    % loop across trials, getting the correlation of the
    % training vector to each trial for condition i
    % (match condition) or the different comparison condition
    % (nonmatch condition)
    for j = 1:nTrials
        match = test(:,j,:,i);
        match = match(:);
        nonmatch = test(:,j,:,bsl);
        nonmatch = nonmatch(:);
    
        R = corrcoef(match,trainVec);
        evidenceMatch(j,i) = R(2);
        R = corrcoef(nonmatch,trainVec);
        evidenceNonmatch(j,i) = R(2);            
    end
end

% set up a combinatorial number of '2-alternative forced-
% choice' trials: re-index the evidence matrices so that
% different combinations (i,j) of trial i from the match
% condition and trial j from the nonmatch are compared, 
% to see which has higher evidence (i.e., which one is more
% similar to the training data)
[X Y] = meshgrid(1:nTrials,1:nTrials);
matchTrials = evidenceMatch(X(:),:);
nonmatchTrials = evidenceNonmatch(Y(:),:);

% decision step: each virtual 2afc trial is decided
% by comparing the evidence from the match and nonmatch
% row/column and choosing the larger. This is done
% in one step, and the proportion correct is calculated
% by summing over total correct, and dividing by # of 
% virtual trials
correct = (matchTrials>nonmatchTrials);
pc = sum(correct,1) ./ size(correct,2);

% assign to output struct
anal.proportionCorrect = pc;
anal.correct = correct;
anal.evidenceMatch = evidenceMatch;
anal.evidenceNonmatch = evidenceNonmatch;


return

