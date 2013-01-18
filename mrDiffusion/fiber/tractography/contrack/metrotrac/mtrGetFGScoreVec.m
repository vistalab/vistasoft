function scoreVec = mtrGetFGScoreVec(fg)

scoreID = [];
% XXX Correct this hack
if (length(fg.params) == 1 && strcmp(fg.params{1}.name,'Weight'))
    scoreID = 1;
else
    for pp = 1:length(fg.params)
        ind = strfind(fg.params{pp}.name,'Posterior');
        if ~isempty(ind)
            scoreID = pp;
        end
    end
end
if (isempty(scoreID))
    error('Error: Unable to find score in statistics list!');
end
scoreVec = fg.params{scoreID}.stat;