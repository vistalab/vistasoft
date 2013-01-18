function [rhoS, rhoK, pvalS, pvalK, overlapVec, pdbIDFiles, threshVec] = mtrComparePDBRanks(pdbSrcIDFile,pdbSrcScoreFile,pdbIDFiles,pdbScoreFiles,threshVec,bSortDestFiles)

% Load each file which contains the path IDs in rank order, compare the
% ordering of the path IDs

% Load id files
if isstr(pdbIDFiles)
    pdbDir = dir(pdbIDFiles);
    pdbIDFiles = {};
    for ff = 1:length(pdbDir)
        pdbIDFiles{ff} = pdbDir(ff).name;
    end
    % Sort dest files by length parameter
    if ~ieNotDefined('bSortDestFiles') && bSortDestFiles
        lVec = [];
        for ff = 1:length(pdbIDFiles)
            lVec(end+1) = getLengthParamFromFilename(pdbIDFiles{ff});
        end
        [foo,sortI] = sort(lVec,'ascend');
        pdbIDFiles = pdbIDFiles(sortI);
    end
end
if isstr(pdbScoreFiles)
    pdbDir = dir(pdbScoreFiles);
    pdbScoreFiles = {};
    for ff = 1:length(pdbDir)
        pdbScoreFiles{ff} = pdbDir(ff).name;
    end
    % Sort dest files by length parameter
    if ~ieNotDefined('bSortDestFiles') && bSortDestFiles
        lVec = [];
        for ff = 1:length(pdbScoreFiles)
            lVec(end+1) = getLengthParamFromFilename(pdbScoreFiles{ff});
        end
    [foo,sortI] = sort(lVec,'ascend');
    pdbScoreFiles = pdbScoreFiles(sortI);
    end    
end

disp(['Src: ' pdbSrcIDFile]);
srcIDVec = loadStatvec(pdbSrcIDFile,'int');
srcScoreVec = loadStatvec(pdbSrcScoreFile,'double');
% Sort IDs based on score
[srcScoreVec, sortI] = sort(srcScoreVec,'descend');
srcIDVec = srcIDVec(sortI);
srcRanks = [1:length(srcIDVec)];

for ff = 1:length(pdbIDFiles)
    disp(['Dest: ' pdbIDFiles{ff}]);
    destIDVec = loadStatvec(pdbIDFiles{ff},'int');
    destScoreVec = loadStatvec(pdbScoreFiles{ff},'double');
    % Sort IDs based on score
    [destScoreVec, sortI] = sort(destScoreVec,'descend');
    destIDVec = destIDVec(sortI);
    destRanks = [1:length(destIDVec)];
    
    for rankThresh = threshVec
        % Take top ranking subset
        subDIDVec = destIDVec(1:rankThresh);
        subDScoreVec = destScoreVec(1:rankThresh);
        subSIDVec = srcIDVec(1:rankThresh);
        subSScoreVec = srcScoreVec(1:rankThresh);   
        
        % Get overlap
        overlapVec(ff,find(threshVec==rankThresh)) = length(intersect(subSIDVec, subDIDVec)) / rankThresh;
        
        % Add unique elements of source to dest
        notInDest = setdiff(subSIDVec, subDIDVec);
        count = 0;
        for ii = 1:length(notInDest)
            count = count + 1;
            inI = destIDVec == notInDest(ii);
            subDIDVec(end+1) = destIDVec( inI );
            subDScoreVec(end+1) = destScoreVec( inI );
        end        
        notInSrc = setdiff(subDIDVec, subSIDVec);
        for ii = 1:length(notInSrc)
            inI = srcIDVec == notInSrc(ii);
            subSIDVec(end+1) = srcIDVec( inI );
            subSScoreVec(end+1) = srcScoreVec( inI );
        end
        
        % Reorder so that we have matched pairs
        [subDIDVec, sortI] = sort(subDIDVec,'ascend');
        subDScoreVec = subDScoreVec(sortI);
        [subSIDVec, sortI] = sort(subSIDVec,'ascend');
        subSScoreVec = subSScoreVec(sortI);
        
        % Compute the Spearman Rank-Order Correlation
        [rhoS(ff,find(threshVec==rankThresh)),pvalS(ff,find(threshVec==rankThresh))] = corr(subSScoreVec(:),subDScoreVec(:),'type','spearman');
        [rhoK(ff,find(threshVec==rankThresh)),pvalK(ff,find(threshVec==rankThresh))] = corr(subSScoreVec(:),subDScoreVec(:),'type','kendall');
        disp(['thresh: ' num2str(rankThresh) ' rhoS: ' num2str(rhoS(ff,find(threshVec==rankThresh))) ' pvalS: ' num2str(pvalS(ff,find(threshVec==rankThresh))) ' rhoK: ' num2str(rhoK(ff,find(threshVec==rankThresh))) ' pvalK: ' num2str(pvalK(ff,find(threshVec==rankThresh))) ' overlap: ' num2str(overlapVec(ff,find(threshVec==rankThresh)))]);
    end
end

function len = getLengthParamFromFilename(filename)
eI = strfind(filename,'.dat')-1;
sI = strfind(filename,'kLength_')+8;
len = str2num(filename(sI:eI));
return;

function smooth = getSmoothParamFromFilename(filename)
eI = strfind(filename,'.dat')-1;
sI = strfind(filename,'kSmooth_')+8;
smooth = str2num(filename(sI:eI));
return;

function [statvec] = loadStatvec(in_filename,datatype)

if ieNotDefined('datatype')
    datatype = 'double'
end

fid = fopen(in_filename,'r');

numP = fread(fid, 1, 'int');
statvec = fread(fid,numP,datatype);

fclose(fid);
