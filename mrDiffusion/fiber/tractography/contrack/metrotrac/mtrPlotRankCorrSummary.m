function mtrPlotRankCorrSummary(summaryFilename)

summary = load(summaryFilename);
paramNames = {'kLength','kSmooth','kMidSD'};
midP = [-2 18 0.175];
ccGrid = mtrFilenames2Paramlist(summary.pdbIDFiles,paramNames);

for pp = 1:length(paramNames)
    strThreshVec = {};
    parVecs = [];
    corrVecs = [];
    ovrVecs = [];
    for tt = 1:length(summary.threshVec)
        ccGrid(:,4) = summary.rhoS(:,tt);
        ccGrid(:,5) = summary.overlapVec(:,tt);
        indGrid = ones(size(ccGrid,1),1);
        for ss = 1:length(paramNames)
            if ss ~= pp
                indGrid = indGrid & ccGrid(:,ss) == midP(ss);
            end
        end
        subGrid = ccGrid(indGrid,:);
        [foo, sortI] = sort(subGrid(:,pp));
        parVecs(:,tt) = subGrid(sortI(:),pp);
        corrVecs(:,tt) = subGrid(sortI(:),4);
        ovrVecs(:,tt) = subGrid(sortI(:),5);
        strThreshVec{tt} = ['Top ' num2str(summary.threshVec(tt))];
    end
    figure; plot(parVecs,corrVecs);
    legend(strThreshVec);
    xlabel([paramNames{pp} ' parameter']);
    ylabel('Spearman rank correlation');
    figure; plot(parVecs,ovrVecs);
    legend(strThreshVec);
    xlabel([paramNames{pp} ' parameter']);
    ylabel('Overlap');
end
