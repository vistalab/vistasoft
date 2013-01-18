function [roiRGB,roiMask,dataMask] = makeROIPerimeterRGB(vw, upSampFactor, upSampImSize, lineWidth)
%
% [roiRGB,roiMask,dataMask] = makeROIPerimeterRGB(vw, upSampFactor, upSampImSize, lineWidth)
% 
% Draws a line around the ROIs.  
%
% roiRGB is the RGB color image with the ROI outlines drawn in. 
% roiMask is a mask image (binary) showing where the all the ROIs are. You
% can use this to draw in the roiRGB data without disturbing the rest of
% the image.
% dataMask is created if an ROI that is called 'mask' exists- it is an
% empty matrix if it doesn't exist. It is a binary mask image with ones 
% inside the ROI called 'mask' and zeros outside it. It can be used to 
% show only a selected portion of the data.
%
% 2002.12.18 RFD: added dataMask output and some comments.
if ~exist('lineWidth', 'var')
    lineWidth = 0.5;
end

% get the ROI draw mode
drawMethod = vw.ui.roiDrawMethod;  % couldn't find viewGet arg for this...


% Initialize the output RGB image
roiRGB = zeros([upSampImSize 3]);
roiMask = zeros(upSampImSize);
dataMask = [];
if(vw.ui.showROIs==0)
    rois = [];
elseif(abs(vw.ui.showROIs)==1)
    rois = vw.ROIs(vw.selectedROI);
else
    rois = vw.ROIs;
end

for r=1:length(rois)
    coords = rois(r).coords;
    % Changed the color allocation scheme here. Now you can have
    % multi-character colors such as 'yyb'. We compute the final light as a
    % mean of the requested color
    
    thisCol=rois(r).color;
     if (ischar(thisCol))
            nColEntries=length(thisCol);
            
            
            for thisColEntry=1:nColEntries
                thisColValue=thisCol(thisColEntry);
                colRGB=[0 0 0];
                switch (thisColValue)
                    case 'y', colorRGB = colRGB+[1 1 0];
                    case 'm', colorRGB = colRGB+ [1 0 1];
                    case 'c', colorRGB = colRGB+ [0 1 1];
                    case 'r', colorRGB = colRGB+ [1 0 0];
                    case 'g', colorRGB = colRGB+ [0 1 0];
                    case 'b', colorRGB = colRGB+ [0 0 1];
                    case 'w', colorRGB = colRGB+ [1 1 1];
                    case 'k', colorRGB = colRGB+ [0 0 0];                
                    otherwise, colorRGB = [1 1 1];
                end % end switch statement
            end % end loop
            colorRGB=colorRGB./nColEntries;
        else
            colorRGB=thisCol;
        end
    % **************************
    
    % Get subset of coords corresponding to the current slice
    if ~isempty(coords)
        coords = canOri2CurOri(vw,coords);
        curSlice = viewGet(vw, 'Current Slice');
        indices = find(coords(3,:)==curSlice);
        
        if ~isempty(indices)
            % We ignore the z-dimention and shift everything up and to the
            % left, because the ROI coords indicate the points at the
            % bottom-right
            % of each voxel.
             
            
            y = coords(1,indices)-1;
            x = coords(2,indices)-1;
            
            % upSample the coords
            x = x.*upSampFactor;
            y = y.*upSampFactor;
            
            upSampSq = upSampFactor^2;
            n = length(x)*upSampSq;
            hiResX = zeros(1,n);
            hiResY = zeros(1,n);
            
            for ii=1:upSampFactor
                offsetX = (ii-upSampFactor-.5)+upSampFactor/2;
                for jj=1:upSampFactor
                    offsetY = (jj-upSampFactor-.5)+upSampFactor/2;
                    hiResX((ii-1)*upSampFactor+jj:upSampSq:end) = x+offsetX;
                    hiResY((ii-1)*upSampFactor+jj:upSampSq:end) = y+offsetY;
                end
            end
            
            hiResX = round(hiResX);
            hiResY = round(hiResY);
            
            goodVals=find((hiResX>0) & (hiResY>0) & (hiResX<upSampImSize(2)) & (hiResY<upSampImSize(1)));
            
            hiResX=hiResX(goodVals);
            hiResY=hiResY(goodVals);
            
            % Draw the whole ROI into an image
            roiBits = zeros(upSampImSize);
            
            roiBits(sub2ind(upSampImSize,hiResY,hiResX)) = 1;
            
            % blur it some
            roiBits = round(blur(roiBits,2));
            
            if(strcmp(rois(r).name, 'mask'))
                dataMask = roiBits;
            else
                doFilledPerimeter=0;
                if (isfield(vw.ui,'filledPerimeter'))
                    if(vw.ui.filledPerimeter)
                        doFilledPerimeter=1;
                    end
                end
                if (doFilledPerimeter)
                    % Do the ROI plotting using the image processing
                    % toolbox's morphological ops
                    
                    % Dilate, erode, fill
                    se=strel('disk',32);
                    tmat=imdilate(logical(roiBits),se);
                    se=strel('disk',32);
                    tmat=imerode(logical(tmat),se);
                    tmat=imfill(tmat,'holes');
                    tmat=tmat-min(tmat(:));
                    roiBits=bwperim(tmat);
                    se=strel('square',lineWidth*2);
                    
                    roiBits=double(imdilate(logical(roiBits),se));
                    
                    
                elseif strncmp(drawMethod, 'perim', 5) > 0
                    % for this option, we are drawing perimeters but not
                    % filled perimeters -- the code below finds the ROI
                    % outline, by growing the region a bit (determined 
                    % by lineWidth), and subtracting out the original ROI
                    % points, leaving an outer boundary. (Comments by RAS)
                    
                    % create a circular filter of ones
                    e = exp(-([-lineWidth:lineWidth]./lineWidth).^2);
                    filt = double( (e'*e) > .367 );
                    roiBits = (conv2(roiBits,filt,'same')>0.1)-roiBits;
                    
                elseif strncmp(drawMethod, 'boxes', 5) > 0
                    % 'draw boxes around each pixel' option --
                    % here, we use the lineWidth argument as a blurring
                    % parameter, to slightly decrease the patchiness of the
                    % upsampled image. To show the filled ROIs with no
                    % blurring, set lineWidth == 0 in the preferences.
                    % (RAS, 06/2010).
                    e = exp(-([-lineWidth:lineWidth]./lineWidth).^2);
                    filt = double( (e'*e) > .367 );
                    roiBits = (conv2(roiBits, filt, 'same') > 0.1);

                
                end % if isfield filledPerimeter
                
                
                roiRGB(:,:,1) = roiRGB(:,:,1) + roiBits.*colorRGB(1);
                roiRGB(:,:,2) = roiRGB(:,:,2) + roiBits.*colorRGB(2);
                roiRGB(:,:,3) = roiRGB(:,:,3) + roiBits.*colorRGB(3);
                roiMask = roiMask | roiBits;
                
                
            end 
            
        end % if ~isempty(indices)
        
    end % if ~isempty(coords)
    
end % for r=1:length(vw.ROIs)


return;
