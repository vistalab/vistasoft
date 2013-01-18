function et=eyetrack2(filebase,thresh,pupilArea,show)
% eyetrack - simple eyetracking program
%
% et=eyetrack(filebase,thresh,pupilArea,confregion);
%
% Input:
%  filebase : string used to find the files to process
% Output:
%  matrix with x,y, size (area) of the pupil in pixels and a confidence 
%  measure. 
%
% 2007/08 SOD & RFD: wrote it.

if ~exist('thresh','var') || isempty(thresh),
    gThresh = false;
    thresh  = .15;
else
    gThresh = false;
end
if ~exist('pupilArea','var') || isempty(pupilArea),
    gPupilArea = false;
    pupilArea = [];
else
    gPupilArea = false;
end
if ~exist('show','var') || isempty(show),
    show = true;
end

% 'smoothing kernel'
%se = strel('disk',7);
%se3 = strel('disk',5);

scale = 0.7;

% 'smoothing kernel'
se = strel('disk',ceil(7.*scale));
se3 = strel('disk',max(ceil(5.*scale),2));

% get all images
files = dir(filebase);


% initialization of variables
select = true;
ii = 1;
while select
    im = imresize(im2double(imread(files(ii).name)),scale,'bicubic');
    figure(1);clf;
    imagesc(im);
    colormap(gray);axis equal off;
    if gPupilArea,
        title('Please identify the pupil and the upper, lower, left and right boundaries');
        [x y] = ginput(5);
        r = mean(sqrt((x(2:4)-x(1)).^2+(y(2:4)-y(1)).^2));
        pupilArea = pi*r*r;
    else
        title('Please identify the pupil center');
        [x y] = ginput(1);
    end
    
    % valid x and y continue else try again with the next image
    if any(x<1) || any(x>size(im,2)) || any(y<1) || any(y>size(im,1)),
        select = true;
    else
        select = false;
    end
    ii = ii+1;
end

if show,
    hold on;
else
    close;drawnow;
end

% guess thesh and guess pupilArea
ssum = 0; tsum = 0;
sn   = 0; tn   = 0;

% to compare estimates against
comp = [x(1) y(1) pupilArea thresh];

% distance limit from previous fixation (# of pupil radii)
dlim = 3;
dlim2  = sqrt(comp(3)/pi).*dlim;

% structure [x,y, size, confidence];
et  = zeros(numel(files),5);
tmp = [0 0 0 thresh 1];

% for median filter
mfDim = [1 1]*ceil(sqrt(pupilArea/pi));
r = sqrt(comp(3)/pi);


for n=1:numel(files),
    % open image
    orgim = imresize(im2double(imread(files(n).name)),scale,'bicubic');

    % estimate radius 
    if gPupilArea,
        r = sqrt(comp(3)/pi);
        mfDim = [1 1]*ceil(sqrt(pupilArea/pi));
    end
    
    % crop to region of interest
    lim = round(comp(1:2)'*[1 1]+([-1 1;-1 1].*((dlim+1.5)*r)));
    lim = max(lim,1);
    lim(1,2) = min(lim(1,2),size(orgim,2));
    lim(2,2) = min(lim(2,2),size(orgim,1));
    im2 = orgim(lim(2,1):lim(2,2),lim(1,1):lim(1,2));
    
    % remove specular reflections    
    mask = (1-im2)<comp(4);
    mask = mask & bwfill(~mask,'holes');
    mask = imdilate(mask,se3);   
    im2   = roifill(im2,mask);
        
    % median filter to clean up speckle noise
    im2 = medfilt2(im2,mfDim,'symmetric');
    %orgim = imresize(im2,size(orgim),'bilinear');
    
    if gThresh,
        % get histogram
        [h int] = hist(im2(:),100);

        % smooth histogram
        h = blurTC(h(:)-max(h(:)),4,[],25);

        % find local minima
        ii = find(h(2:end-1)< h(1:end-2) & h(2:end-1)< h(3:end));

        % find thresh closest to established threshold
        [junk i3] = min(abs(int(ii+1) - comp(4)));
        thresh = int(ii(i3(1))+1);
    end 

    % threshold image (binary)
    im=bwlabeln(im2<thresh,4);
    
    % smooth image (erode/dilate)
    im = imopen(im,se);

    % loop over remaining clusters
    cId = unique(im(:));
    for ii=2:numel(cId),
        % get selected cluster
        im2 = im==cId(ii);
        
        % find position of blob
        [x,y]=find(im2);

        % center of mass blob
        tmp(1) = median(y)+lim(1,1); % column
        tmp(2) = median(x)+lim(2,1); % row
        tmp(4) = 1;         % reset confidence
        % confidence re: distance away from previous point as defined in
        % steps relative to the average pupil radius
        if sqrt(sum(abs(tmp(1:2)-comp(1:2)).^2)) < dlim2

            % size of blob
            tmp(3) = sum(im2(:));
            
            if tmp(3) > comp(3)*.65
                
                % confidence re: distance and size
                d = sqrt(sum(abs(tmp(1:3)-comp(1:3)).^2));
                if d>0, % don't devide by 0
                    tmp(5) = 1./d;
                end

                % store  if this confidence is higher than stored one
                if tmp(5)>et(n,5),
                    tmp(4)  = thresh;
                    et(n,:) = tmp;
                end
            end
        end
    end

    % if position is found update:
    if all(et(n,1:3))
        
        % reset comparison data
        comp(1:2) = et(n,1:2);
        if gPupilArea,
            % print out average size so far
            ssum = ssum+et(n,3);
            sn   = sn + 1;
            comp(3) = ssum/sn;
            dlim2  = sqrt(comp(3)/pi).*dlim;
        end
        if gThresh,
            % print out average intensity + 1 sd
            tsum = tsum + et(n,4);
            tn   = tn + 1;
            comp(4) = tsum/tn;
        end
    else
        % reset the starting point just in case the last estimate was
        % compromised
        goodData = find(et(:,1)>0);
        ng = numel(goodData);
        if ng>0,
            if ng>5, goodData=goodData(ng-5:end); end;
            comp(1:2) = median(et(goodData,1:2));
        end
    end
    
    % plot
    if show,
        cla;
        imagesc(orgim);
        if et(n,1)
            plot(et(n,1),et(n,2),'ro','markersize',sqrt(et(n,3)/pi)*2);
        else
            tmp;
        end
        title(sprintf('%d: x=%.1f, y=%.1f, size = %d (%d), int = %.2f (%.2f)',...
            n,et(n,1:3),round(comp(3)),et(n,4),comp(4)));
        drawnow;
    end
end
