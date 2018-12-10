function tSeries = analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag,flipSliceOrder)
% Converts from analyze functional image data to mrLoadRet TSeries format
%
%  tSeries = analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag)
%
% Analyze functional data are stored as N individual volumes, each with S slices
% mrLoadRet has S individual files with N acquisitions in each.
% the doRotate param allows to you rotate the functional data by doRotate*90 degrees
% Try to read the the first volume to see if it's there and get the dimensions of all the rest
%
% example:
% for .hdr and .img files stored in
% S:\users\michal\feldmanLab\data\hf070830\functional\scan1
% where each file has a name scheme scan1.V001.hdr
% we will define:
% inFileRoot = 'S:\users\michal\feldmanLab\data\hf070830\functional\scan1\scan1.V';
% outFileRoot = 'S:\users\michal\feldmanLab\data\hf070830\Inplane\Original\TSeries\Scan1\';
% nVols = 182;
% doRotate = 1; (this is for analyze files made of Pfiles using makeVols)
% flipudFlag = 0;
% flipSliceOrder = 1;
% firstVolIndex = 1;
% scaleFact =[1 1];
% fliplrFlag = 0; %???
% then run:
% analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,1,doRotate,scaleFact,flipudFlag,fliplrFlag,flipSliceOrder);
% this will result in tSeries files for the scan, stored in outFileRoot.
% repeat this for the other scans. 
% To run mrVista on this data, you will have to also copy the mrSession.mat 
% and anat.mat files to the appropriate locations. Make sure you did not
% crop when creating mrSession.
%
% ARW 032703 : Now saves out data in mrLoadRet3.0 format (.mat as opposed
% to .dat files)
% AAB 2003.07.08 After the temporal normalization bug, I reconverted the
% Tuebingen data using the Brucker-2-analyze converter downloaded from the
% website. The new time series do not need to be rotated or flipped
% up/down, but do need to be flipped left/right. So, I changed flipFlag to
% flipudFlag (for up/down) and added fliplrFlag (for left/right). I set
% all three values to be off by default.
% BW. 2007.02.22 Fixed many things and neatened
% MBS added example and fixed for running on ANALYZE files created by
% Gary's makevols. still need to check if left-right flip needed.
%


if notDefined('firstVolIndex'), firstVolIndex=1; end

% No interpolation. (Scaling=1)
if notDefined('scaleFact'), scaleFact =[1 1]; end

% If just a scalar assume it applies in both dimensions
if (length(scaleFact)~=2), scaleFact=repmat(scaleFact(1),2); end

% Rotates 1*90 degrees
if notDefined('doRotate'), doRotate=0; end

% Flips up/down after rotation
if notDefined('flipudFlag'), flipudFlag=0; end

% Flips left/right after rotation
if notDefined('fliplrFlag'), fliplrFlag=0; end

% Flips left/right after rotation
if notDefined('flipSliceOrder'), flipSliceOrder=0; end

% SPM needs a file separator at the end of the name, but they don't check
% if ~strcmp(inFileRoot(end),filesep), inFileRoot = [inFileRoot,filesep]; end

% Read in the analyze file
suffix   = sprintf('%03d',firstVolIndex);
fileName = [inFileRoot,suffix,'.hdr'];
vol       = analyzeRead(fileName);
[y,x,nSlices] = size(vol);
fprintf('Read in a volume of size %d, %d, %d',y,x,nSlices);

% Allocate memory: This can fail.  
% We should find a way to do this a chunk at a time.
fprintf('\nAllocating an array with %d elements...\n',y*x*nSlices*nVols);

% When we rotate by 180 degrees the x and y dimensions remain unchanged
if (mod(doRotate,2)) , funcVol=zeros(x,y,nSlices,nVols);
else                   funcVol=zeros(y,x,nSlices,nVols);
end
fprintf('Rotating %d x 90 deg, flipupFlag=%d, fliplrFlag=%d\n',doRotate,flipudFlag,fliplrFlag);

wBar = mrvWaitbar(0,'Reading ...');
for t=0:(nVols-1)
    thisImIndex = t+firstVolIndex;
    suffix      = sprintf('%03d',thisImIndex);
    fileName    = [inFileRoot,suffix];
    vol         = analyzeRead(fileName);
   
    % When we rotate by 180 degrees the x and y dimensions remain unchanged
    if (mod(doRotate,2)) ,  vol2=zeros(x,y,nSlices);
    else                    vol2=zeros(y,x,nSlices);
    end
    mrvWaitbar(t/nVols,wBar);

    for thisSlice=1:nSlices
        imSlice=squeeze(vol(:,:,thisSlice));
        vol2(:,:,thisSlice)=rot90(imSlice,doRotate);
        if (flipudFlag), vol2(:,:,thisSlice)=flipud(vol2(:,:,thisSlice)); end
        if (fliplrFlag),vol2(:,:,thisSlice)=fliplr(vol2(:,:,thisSlice)); end
    end % next imSlice

    % We can make it so the slice order is reversed
    if (flipSliceOrder), vol2 = vol2(:,:,(thisSlice:-1:1)); end
    funcVol(:,:,:,t+1) = vol2;

end
close(wBar);

% Now write them out in a different format
fprintf('\nDone reading...\n');
for t=1:nSlices

    % Why now a,b,c instead of x,y?
    tSeries = squeeze(funcVol(:,:,t,:));
    [a,b,c] = size(tSeries);
    fprintf('\nSize before: %d by %d by %d vols \n',a,b,c);

    tSeries = squeeze(shiftdim(tSeries,2));

    [a,b,c]=size(tSeries);
    fprintf('Size after:%d samples by %d by %d\n',a,b*scaleFact(1),c*scaleFact(2));

    % Reshape tSeries here
    tSeries = reshape(tSeries,a,(b*c));

    if ~exist(outFileRoot,'dir'), mkdir(outFileRoot); end

    outFileName = fullfile(outFileRoot,['tSeries',num2str(t)]);
    save(outFileName,'tSeries');
    fprintf('Saving: %s\n',outFileName);

end

return;
