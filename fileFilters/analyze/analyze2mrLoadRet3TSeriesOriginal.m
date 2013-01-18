function imStack=analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipFlag)
% function imStack=analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,firstVolIndex,doRotate,scaleFact,flipFlag)
% Converts from analyze functional image data to mrLoadRet TSeries format
% Analyze functional data are stored as N individual volumes, each with S slices
% mrLoadRet has S individual files with N acquisitions in each.
% the doRotate param allows to you roate the functional data by doRotate*90 degrees
% Try to read the the first volume to see if it's there and get the dimensions of all the rest


% TODO: 1:  Rotate these so that they are in the same orientation as the anatomicals
% (Maybe make this a flag)
% 2: Why can't we see the anatomicals? Claims not to be able to read from /Raw/Anatomy/Inplane
% 3: Why can't we load in the corAnal? We do this by hand perfectly well but it won't do it from mrLoadRet
% 4: Do we want to resample the functional data? Or is this the moment to go to mrLoadRet3?
% 
%
% ARW 032703 : Now saves out data in mrLoadRet3.0 format (.mat as opposed to .dat files)


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
    doRotate=1; % This is on by default. Rotates 1*90 degrees
end

if (~exist('flipFlag','var'))
    flipFlag=1; % This is on by default. Flips up/down after rotation
end
suffix=sprintf('%04d',firstVolIndex);

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
 fprintf('Rotating by %d x 90, flipFlag=%d',doRotate,flipFlag);
    
for t=0:(nVols-1)
    thisImIndex=t+firstVolIndex;
    suffix=sprintf('%04d',thisImIndex);
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
    %s    imSlice=imresize(imSlice,[scaleFact(1)*y,scaleFact(2)*x],'nearest');
        
        im2(:,:,thisSlice)=rot90(imSlice,doRotate);
        if (flipFlag)
          
            im2(:,:,thisSlice)=flipud(im2(:,:,thisSlice));
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
    
    tSeries=squeeze(shiftdim(tSeries,2));
    
    
    
    [a,b,c]=size(tSeries);
    fprintf('\nSize after:%d samples by %d by %d',a,b*scaleFact(1),c*scaleFact(2));
    
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
