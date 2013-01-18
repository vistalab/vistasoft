function designMatrix = getDesignMatrix(view)
%
% designMatrix = getDesignMatrix(view)
%
% Will prompt for a design matrix file if it hasn't already been loaded.
% 
% HISTORY
% 2004.03.02 Written by Bob and Michal.
%

global dataTYPES;

nScans = numScans(view);
for(ii=1:nScans)
    nFrames(ii) = numFrames(view, ii);
end

if(isfield(dataTYPES(view.curDataType), 'designMatrix'))
    designMatrix = dataTYPES(view.curDataType).designMatrix;
else
    [f,p] = uigetfile('*.*','Select design matrix file...');
    if(isnumeric(f))
        % PROMPT FOR MATRIX VIA GUI
        % build the designMatrix from manual input per each scan. after the last
        % scan is entered, cancel the next dlg to finish this stage.
        numConditions = 0;
        resp = inputdlg({'Condition:','Scan num:','Frame range:'}, 'Design Matrix', 1);
        while(~isempty(resp) && ~isempty(resp{1}))
            numConditions = numConditions+1;
            designMatrix(numConditions).conditionName = resp{1};
            designMatrix(numConditions).scanFrames = zeros(sum(nFrames), 3);
            scanNumList = str2num(resp{2});
            eval(['frameNumArray = ' resp{3} ';'], 'frameNumArray = [];');
            if(isempty(frameNumArray))
                error(['Error specifying design matrix. See help ' mfilename '.']);
            end
            % assign 1 to each frame included in a given condition
            for(ii=1:nScans)
                for(jj=1:nFrames(ii))
                    designMatrix(numConditions).scanFrames((ii-1)*nFrames(ii)+jj, 1) = ii;
                    designMatrix(numConditions).scanFrames((ii-1)*nFrames(ii)+jj, 2) = jj;
                end
                matchCond = (ii-1)*nFrames(ii)+[frameNumArray{scanNumList==ii}];
                designMatrix(numConditions).scanFrames(matchCond,3) = 1;
            end
            resp = inputdlg({'Condition:','Scan num:','Frame range:'}, 'Design Matrix', 1);
        end
        if(~exist('designMatrix','var') | isempty(designMatrix))
            disp([mfilename ': user cancelled.']);
            designMatrix = [];
            return;
        end
    else
        
        % load matrix from a file
        allRows = readTab(fullfile(p,f));
        clear designMatrix;
        numConditions = 0;
        rowList = [1:size(allRows,1)];
        while(sum(rowList)>0)
            numConditions = numConditions+1;
            theseRows = find(rowList>0);
            designMatrix(numConditions).conditionName = allRows{theseRows(1),4};
            designMatrix(numConditions).scanFrames = zeros(sum(nFrames), 3);
            thisCond = strmatch(designMatrix(numConditions).conditionName, allRows(:,4), 'exact');
            
            for(ii=1:nScans)
                for(jj=1:nFrames(ii))
                    designMatrix(numConditions).scanFrames((ii-1)*nFrames(ii)+jj, 1) = ii;
                    designMatrix(numConditions).scanFrames((ii-1)*nFrames(ii)+jj, 2) = jj;
                end
                thisCondRows = allRows(thisCond,:);
                curScanIndex = [thisCondRows{:,1}]==ii;
                frameRange = [thisCondRows{curScanIndex,2}; thisCondRows{curScanIndex,3}];
                for(jj=1:size(frameRange,2))
                    matchCond = (ii-1)*nFrames(ii)+[frameRange(1,jj):frameRange(2,jj)];
                    designMatrix(numConditions).scanFrames(matchCond,3) = 1;
                end
            end
            rowList(thisCond) = 0;
        end
    end
    dataTYPES(view.curDataType).designMatrix = designMatrix;
end

return;

