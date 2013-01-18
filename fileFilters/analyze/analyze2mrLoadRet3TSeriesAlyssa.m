function imStack=analyze2mrLoadRet3TSeriesAlyssa(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag)
% function imStack=analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag)
% Converts from analyze functional image data to mrLoadRet TSeries format
% Analyze functional data are stored as N individual volumes, each with S slices
% mrLoadRet has S individual files with N acquisitions in each.
% the doRotate param allows to you rotate the functional data by doRotate*90 degrees
% Try to read the the first volume to see if it's there and get the dimensions of all the rest
 

% ARW 032703 : Now saves out data in mrLoadRet3.0 format (.mat as opposed to .dat files)

% AAB 2003.07.08 After the temporal normalization bug, I reconverted the
% Tuebingen data using the Brucker-2-analyze converter downloaded from the
% website. The new time series do not need to be rotated or flipped
% up/down, but do need to be flipped left/right. So, I changed flipFlag to
% flipudFlag (for up/down) and added fliplrFlag (for left/right). I set
% all three values to be off by default.

if (~exist('firstVolIndex','var'))
    firstVolIndex=1;
end

if (~exist('scaleFact','var'))
    scaleFact=[1 1]; % No interpolation. (Scaling=1)
end

if (length(scaleFact)~=2) % If we just get a scalar for the scale factor, assume that it applies in both dimensions
    scaleFact=repmat(scaleFact(1),2);
end

if (~exist('doRotate','var'))
    doRotate=0; % This is off by default. Rotates 1*90 degrees
end

if (~exist('flipudFlag','var'))
    flipudFlag=0; % This is off by default. Flips up/down after rotation
end

if (~exist('fliplrFlag','var'))
    fliplrFlag=0; % This is off by default. Flips left/right after rotation
end

suffix=sprintf('%03d',firstVolIndex);

fileName=[inFileRoot,suffix,'.hdr'];

V=spm_vol(fileName);
im=spm_read_vols(V);

[y,x,nSlices]=size(im);
fprintf('Read in a volume of size %d, %d, %d',y,x,nSlices);


% Pre-allocate memory: This is a monster and will fail on many machines. 
fprintf('\nTrying to allocate an array with %d elements...\n',y*x*nSlices*nVols);

if (mod(doRotate,2)) % When we rotate by 180 degrees the x and y dimensions remain unchanged
    funcVol=zeros(y,x,nSlices,nVols);
else
    funcVol=zeros(x,y,nSlices,nVols);
end
 fprintf('Rotating by %d x 90, flipupFlag=%d, fliplrFlag=%d',doRotate,flipudFlag,fliplrFlag);
    
for t=0:(nVols-1)
    thisImIndex=t+firstVolIndex;
    suffix=sprintf('%03d',thisImIndex);
    fileName=[inFileRoot,suffix];
    V=spm_vol(fileName);
    im=spm_read_vols(V);
    
    % Do the rotation and scaling
    
    if (mod(doRotate,2)) % When we rotate by 180 degrees the x and y dimensions remain unchanged
        im2=zeros(y,x,nSlices);
    else
        im2=zeros(x,y,nSlices);
    end
    fprintf('\nVol=%d',thisImIndex);
   
    for thisSlice=1:nSlices
        imSlice=squeeze(im(:,:,thisSlice));
%         imSlice=imresize(imSlice,[scaleFact(1)*y,scaleFact(2)*x],'nearest');
        
        im2(:,:,thisSlice)=rot90(imSlice,doRotate);
        
        if (flipudFlag)
            im2(:,:,thisSlice)=flipud(im2(:,:,thisSlice));
        end
        
        if (fliplrFlag)
            im2(:,:,thisSlice)=fliplr(im2(:,:,thisSlice));
        end
        
    end % next imSlice
     
    funcVol(:,:,:,t+1)=im2;
    %fprintf('.');
    
end
size(funcVol);
[y x nSlices nVols]=size(funcVol);

% Now write them out in a different format
fprintf('\nDone reading data: Writing now...\n');
for t=1:nSlices
    suffix=int2str(t);
    tSeries=squeeze(funcVol(:,:,t,:));
    [a,b,c]=size(tSeries);
    fprintf('\nSize before: %d by %d by %d vols ',a,b,c);
    nTime = c;
    
%     tSeries=squeeze(shiftdim(tSeries,2));
    tSeries=squeeze(tSeries);
    
%    tSeries=imresize(tSeries,[scaleFact(1)*a,scaleFact(2)*b],'nearest');
%   imresize takes in a 2D image and we are using a 3D structure - this
%   works okay in windows but not on unix, so let's loop through instead
tSeriesLarge  = zeros(scaleFact(1)*a,scaleFact(2)*b,nTime);

 for ii = 1:nTime
     % May want to try 'bilinear' rather than 'nearest'
     tSeriesLarge(:,:,ii) = imresize(tSeries(:,:,ii),[scaleFact(1)*a,scaleFact(2)*b],'nearest');
 end

 clear tSeries
 tSeries = tSeriesLarge;
 clear tSeriesLarge
 
 
    tSeries=shiftdim(tSeries,2);
    [a,b,c]=size(tSeries);
    
%     fprintf('\nSize after:%d samples by %d by %d',a,b*scaleFact(1),c*scaleFact(2));
    fprintf('\nSize after:%d samples by %d by %d',a,b,c);
    
    % Reshape tSeries here
    tSeries=reshape(tSeries,a,(b*c));
    
    if ~exist(outFileRoot,'dir')
      mkdir(outFileRoot);
    end

    pathStr = fullfile(outFileRoot,['tSeries',num2str(t)]);
%disp(['Saving: ',pathStr]);
    save(pathStr,'tSeries');

    fprintf('_');
end
fprintf('\nDone\n');
imStack='pathStr';
