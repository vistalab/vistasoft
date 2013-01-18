function classify_SaveROITCs()
%
% Final files contain data, analysis, and a potentially more cryptic
% meanTcs cell array.  This cell array is 1xN, with N being the number of
% trial sets.  Accessing meanTcs{1} will reveal a 1x2 cell array.  Cell 1
% of this array (meanTcs{N}{1}) contains a structure with all of the 
% condition names as fields, each of which contains a MxN matrix (M being 
% voxel number, N being mean time course point).  Cell 2 of this array 
% (meanTcs{N}{2}) contains a vector of the trials that are included in
% these means.
%
% Parameters allDirectories, allROIs, and allTrials have corresponding
% rows.  It loads the INPLANE in row N of allDirectories, loads the ROIs
% in row N of allROIs, and saves out means for the trial sets listed in
% row N of allTrials.  Thus, if you want to keep adding to them, match the
% formatting of the row given.
%
% Example:
%
%    allTrials = { ...
%        { {1:4}, {5:8}, {1:8} }; ... 
%        { {1:3}, {2:6} }; ...
%        { {6:20}, {22 111 32}, {1}, {29} }; ...
%        };
%
% renobowen@gmail.com 2010

    MOTION_COMP = 3;
        
    allDirectories = { ...
        '/biac3/wandell7/data/Words/WordEccentricity/amr091006'; ...
        };
    allROIs = { ...
        'LV1,RV1,lOTS,rOTS'; ...
        };  
    allTrials = { ...
        { {1:7} {8} }; ...
        };
    
    nDirs = size(allDirectories,1);
    
    for i = 1:nDirs
        dir = allDirectories{i};
        saveTo = [dir '/tcFiles'];
        if (~exist(saveTo,'dir'))
            mkdir(saveTo);
        end
        cd(dir);
        dirSeps = findstr(dir,'/');
        lastTokenIndex = dirSeps(end)+1;
        name = dir(lastTokenIndex:end);

        ROIs = parseROIs(allROIs{i});
        nROIs = length(ROIs);
        
        view = initHiddenInplane(MOTION_COMP, 1, ROIs);
        
        for ii = 1:nROIs
            filename = [saveTo '/' name '_' view.ROIs(ii).name];
            data = er_voxelData(view,view.ROIs(ii));
            analysis = er_chopTSeries2(data.tSeries, data.trials, data.params);
 
            % Saving out mean TCs into a few separate files
            nTrialSets = size(allTrials{i},2);
            tcourses_svm_array = cell(1, nTrialSets);
            tcourses = classify_SortAnalysis(analysis);
            
            for iii = 1:nTrialSets
                tcourses_svm = classify_ConvertForSVM(tcourses, allTrials{i}{iii}{1});
                tcourses_svm_array{iii} = tcourses_svm;
            end
            save(filename, 'data', 'analysis', 'tcourses', 'tcourses_svm_array');
        end
        
    end
    
    clear;
end

function ROIs = parseROIs(ROIList)

    ROISeps = findstr(ROIList,',');
    nROISeps = length(ROISeps);
    nROIs = nROISeps + 1;
    ROIs = cell(1,4);
    startInd = 1;
    for i = 1:nROIs
        if (i > nROISeps)
            ROIs{i} = ROIList(startInd:end);
        else
            ROIs{i} = ROIList(startInd:(ROISeps(i) - 1));
            startInd = ROISeps(i) + 1;
        end
    end
        
end