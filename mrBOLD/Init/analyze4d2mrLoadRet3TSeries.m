function view=analyze4d2mrLoadRet3TSeries(view,inFile,scan,volsToSkip,rotateInplanes,scaleFact,flipudFlag,rotateFlag,flipSliceOrder)
% view=4danalyze2mrLoadRet3TSeries(view,inFile,scan,volsToSkip,rotateInplan
% es,scaleFact,flipudFlag,fliplrFlag,flipSliceOrder)
% Converts from 4d analyze functional image data to mrLoadRet TSeries
% format.
% Uses read_avw to read in 4d analyze files. Then saves out the block as
% mlr TSeries while skipping over any initial 'junk frames';
%
% The doRotate param allows to you rotate the functional data by doRotate*90 degrees
% Try to read the the first volume to see if it's there and get the
% dimensions of all the rest
% ARW 032703 : Now saves out data in mrLoadRet3.0 format (.mat as opposed to .dat files)

% AAB 2003.07.08 After the temporal normalization bug, I reconverted the
% Tuebingen data using the Brucker-2-analyze converter downloaded from the
% website. The new time series do not need to be rotated or flipped
% up/down, but do need to be flipped left/right. So, I changed flipFlag to
% flipudFlag (for up/down) and added fliplrFlag (for left/right). I set
% all three values to be off by default.
% ARW : 120805 : This function based on analyze2mrLoadRet3TSeries. 


if (~exist('volsToSkip','var'))
    volsToSkip=0;
end

if (~exist('scaleFact','var'))
    scaleFact=[1 1]; % No interpolation. (Scaling=1)
end

if (length(scaleFact)~=2) % If we just get a scalar for the scale factor, assume that it applies in both dimensions
    scaleFact=repmat(scaleFact(1),2);
end

if (~exist('rotateInplanes','var'))
    rotateInplanes=0; % This is off by default. Rotates 1*90 degrees
end

if (~exist('flipudFlag','var'))
    flipudFlag=0; % This is off by default. Flips up/down after rotation
end

if (~exist('fliplrFlag','var'))
    fliplrFlag=0; % This is off by default. Flips left/right after rotation
end
if (~exist('flipSliceOrder','var'))
    flipSliceOrder=0; % This is off by default. Flips left/right after rotation
end


disp('Reading volume');
funcVol=read_avw(inFile);
disp('Done');

% Now take care of flipping...

% 
% if (mod(doRotate,2)) % When we rotate by 180 degrees the x and y dimensions remain unchanged
%     funcVol=zeros(y,x,nSlices,nVols);
% else
%     funcVol=zeros(x,y,nSlices,nVols);
% end
% 
% fprintf('Rotating by %d x 90, flipupFlag=%d, fliplrFlag=%d',doRotate,flipudFlag,fliplrFlag);
% 
% 
% for t=0:(nVols-1)
%     thisImIndex=t+firstVolIndex;
%     suffix=sprintf('%03d',thisImIndex);
%     fileName=[inFileRoot,suffix];
%     V=spm_vol(fileName);
%     im=spm_read_vols(V);
%     
%     % Do the rotation and scaling
%     
%     if (mod(doRotate,2)) % When we rotate by 180 degrees the x and y dimensions remain unchanged
%         im2=zeros(y,x,nSlices);
%     else
%         im2=zeros(x,y,nSlices);
%     end
%     fprintf('\nVol=%d',thisImIndex);
%    
%     for thisSlice=1:nSlices
%         imSlice=squeeze(im(:,:,thisSlice));
% %         imSlice=imresize(imSlice,[scaleFact(1)*y,scaleFact(2)*x],'nearest');
%         
%         im2(:,:,thisSlice)=rot90(imSlice,doRotate);
%         
%         if (flipudFlag)
%             im2(:,:,thisSlice)=flipud(im2(:,:,thisSlice));
%         end
%         
%         if (fliplrFlag)
%             im2(:,:,thisSlice)=fliplr(im2(:,:,thisSlice));
%         end
%         
%     end % next imSlice
%     
%     
%     if (flipSliceOrder) % We can make it so the slice order is reversed 
%         im2=im2(:,:,[thisSlice:-1:1]);
%     end
% 
%     funcVol(:,:,:,t+1)=im2;
%     %fprintf('.');
%     
% end

% Crop the skipped frames
funcVol=funcVol(:,:,:,(volsToSkip+1):end);

if (rotateInplanes)
disp('Rotating');

[y x nSlices nVols]=size(funcVol)
for thisVol=1:nVols
    for thisSlice=1:nSlices
        funcVol(:,:,thisSlice,thisVol)=rot90(squeeze(funcVol(:,:,thisSlice,thisVol)),rotateInplane);
    end
end
end

% Now write them out in a different format
fprintf('\nDone reading data: Writing now...\n');
for t=1:nSlices

    tSeries=squeeze(funcVol(:,:,t,:));
    tSeries=reshape(tSeries,x*y,nVols);
    tSeries=tSeries';
    view=saveTSeries(tSeries,view,scan,t);
    
    fprintf('_');
end

fprintf('\nDone\n');

