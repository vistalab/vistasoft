function mtrPlotCorr(ccFilenameBase,threshVec,paramNames,midP,whichParams,strLineProp)
% 
% paramNames = {'kLength','kSmooth','kMidSD'};
% midP = [0 18 0.175];


for pp = 1:length(whichParams)
    strThreshVec = {};
    parVecs = [];
    corrVecs = [];
    ovrVecs = [];
    for tt = 1:length(threshVec)
        cc = load([ccFilenameBase '_thresh_' num2str(threshVec(tt)) '.mat']);
        ccGrid = mtrCCMatrix2Grid(cc.ccMatrix,cc.paramData,paramNames);
        indGrid = ones(size(ccGrid,1),1);
        for ss = 1:length(paramNames)
            if ss ~= whichParams(pp)
                indGrid = indGrid & ccGrid(:,ss) == midP(ss);
            end
        end
        subGrid = ccGrid(indGrid,:);
        [foo, sortI] = sort(subGrid(:,whichParams(pp)));
        parVecs(:,tt) = subGrid(sortI(:),whichParams(pp));
        corrVecs(:,tt) = subGrid(sortI(:),4);
        strThreshVec{tt} = ['Top ' num2str(threshVec(tt))];
    end
    if( pp>1 ) figure; end
    if strcmp(paramNames{whichParams(pp)},'kSmooth')
        parVecs = asin(sqrt(1./parVecs)).*180./pi;
        plot(parVecs,corrVecs,strLineProp);
    else
        plot(parVecs,corrVecs,strLineProp);
    end
    %legend(strThreshVec);
    xlabel([paramNames{whichParams(pp)} ' parameter']);
    ylabel('Corr. Coef.');
end
