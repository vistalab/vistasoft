function conMaskLengthyStartVoxels(timeMaskFileOut, startVoxelMaskFile, pathsRootFile)
% Load path files and find average start time per start point defined in a
% start voxel mask.  We assume that the pathway file contains time required
% to create a path per path.
%
% conMaskLengthyStartVoxels(timeMaskFileOut, startVoxelMaskFile, pathsRootFile)
% 
%
%
% 
% HISTORY:
% 2007.12.11 AJS: wrote it.
%

% Get startpoint mask
niMask = niftiRead(startVoxelMaskFile);
if(isempty(niMask.data))
    error('Could not find the start voxel mask.');
end

% Create output structure
timeMask = zeros(size(niMask.data));
% Create num pathways structure
npData = zeros(size(niMask.data));
% Get pathway directory
[pathDir] = fileparts(pathsRootFile);

pathNames = dir(pathsRootFile);
disp(['Processing ' num2str(length(pathNames)) ' pathway files...']);
ticPercent = 10;
lastPercent = 0;
for nn=1:length(pathNames)
    curName = pathNames(nn).name;
    %disp(['For ' curName '...']);
    pathFile = fullfile(pathDir,curName);
    fid = fopen(pathFile,'rb','b');
    d = fread(fid,'float');fclose(fid);
    fp=1;
    %timeV = zeros(23000,1)-1;
    %nPathsV = zeros(23000,1)-1;
    pp=1;
    while(fp <= length(d))
        numstats    = d(fp);
        npoints     = d(fp+1);
        %timeV(pp)   = d(fp+2);
        %nPathsV(pp) = d(fp+3);
        [i,j,k] = xyz2ijk(d(fp+4),d(fp+5),d(fp+6),niMask);
        timeMask(i,j,k) = timeMask(i,j,k)+d(fp+2);
        npData(i,j,k) = npData(i,j,k)+1;
        fp = fp+2+numstats+3*npoints;
        pp=1+pp;
    end
    % Squeeze vectors
    %if(find(timeV==-1,1,'first')>1)
    %    timeV = timeV(1:find(timeV==-1,1,'first')-1);
    %    nPathsV = nPathsV(1:find(nPathsV==-1,1,'first')-1);
    %end
    % Replace zero times with minimum
    %timeV(timeV==0) = min(timeV(timeV>0));
    %totalTime = (sum(timeV))/3600;
    %disp(['Total time (per path and per cpu): ' num2str(totalTime) ' hours.']);
    %totalPaths = sum(nPathsV);
    %disp(['Num paths sampled to find terminating (per connecting path): ' num2str(totalPaths) ' paths.']);
    %maxPaths = max(nPathsV);
    %disp(['Max number of paths sampled to find terminating: ' num2str(maxPaths) ' paths.']);
    [lastPercent] = progress(nn,lastPercent,ticPercent,length(pathNames));
end
disp(['Total time required by pathway computation: ' num2str(sum( timeMask(:) )) ' seconds.']);
disp(['Total GM covered: ' num2str(sum( npData(:)>0 )) ' voxels.']);
avgTimePP = zeros(size(timeMask));
avgTimePP(npData>0) = timeMask(npData>0) ./ npData(npData>0);
disp(['Max. average time required per GM point ' num2str(max( avgTimePP(:) )) ' seconds']);

% Write out time mask file
timeMask(timeMask>0) = 1;
dtiWriteNiftiWrapper (timeMask, niMask.qto_xyz, timeMaskFileOut);

return;

function [i,j,k] = xyz2ijk(x,y,z,niData)
% Assume that the input paths are in mm space so we don't need to use ACPC
% offset
index = inv(niData.qto_xyz(1:3,1:3))*[x;y;z]+1;
i = round(index(1)); j=round(index(2)); k=round(index(3));
if(outBounds(i,j,k,niData.data))
    error(['Pathway position ' num2str(i) ', ' num2str(j) ', ' num2str(k) ' is out of bounds.']);
end
return;

function [bIsOut] = outBounds(i,j,k,data)
bIsOut = i<1 || i>size(data,1) || j<1 || j>size(data,2) || k<1 || k>size(data,3);
return;

function [lastPercent] = progress(curV,lastPercent,ticPercent,maxV)
curPercent = curV/maxV*100;
if(curPercent - lastPercent > ticPercent)
    disp([ num2str(curPercent) '% complete...']);
    lastPercent = curPercent;
end
return;
