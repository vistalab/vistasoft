function drawROIsPerimeter(view, lineWidth)
%
% drawROIsPerimeter(view, [lineWidth])
% 
% Draws a line around the ROIs.  
% This function should be called only if
% view.showROIs is non-zero.  If showROIs=-1, draw only the
% selected ROI.  If abs(showROIs)=2, draw all the ROIs.

if ~exist('lineWidth', 'var'), lineWidth = 0.5;  end

for r=1:length(view.ROIs)
    % Selected ROI color: now a set-able param, ras 05/05
    if (r==view.selectedROI)
        coords = view.ROIs(r).coords;
        color = viewGet(view,'selRoiColor');
        % Non-selected ROI, get coords, get color
    else
        % If showROIs~=2, then set coords=[] so that nothing will be
        % drawn. 
        if (view.ui.showROIs==-2)
            coords = view.ROIs(r).coords;
        else
            coords = [];
        end
        
        %color=view.ROIs(r).color;
        % We can now have many different colors in our ROIs. So we need
        % some way of translating the (more than 1-character) 'color' into
        % a color vector.
        thisCol=view.ROIs(r).color;
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
            color=colorRGB./nColEntries;
        else
            color=thisCol;
        end
    end
    
    % Get subset of coords corresponding to the current slice
    if ~isempty(coords)
        coords = canOri2CurOri(view,coords);
        curSlice = viewGet(vw, 'Current Slice');
        indices = find(coords(3,:)==curSlice);
        coords = coords(:,indices);
    end
    
    % Draw the lines around each pixel's edge that doesn't have a neighbor
    % w=1/2 because you want to draw the outside boarder, not the pixel
    % centers
    
    if ~isempty(coords)
        
        % The FLAT view can have a 'rotateImageDegrees' field that
        % specifies a rotation angle for each slice (L or R). 
        % If this is set, then we have to transform the ROIs by this amount as
        % well to make them register with the anatomy and functional data
        if isfield(view,'rotateImageDegrees')
            coords=rotateCoords(view,coords);
        end
        
        % What sort of perimeter shall we draw? 'filled Perimeters' get rid
        % of the blobby effect that transforming from the volume view
        % sometimes causes.
        doFilledPerimeter=0;   
        if (isfield(view.ui,'filledPerimeter'))
            if(view.ui.filledPerimeter)
                doFilledPerimeter=1;
            end
        end
        
        if (doFilledPerimeter)
            % Get colormap, numGrays, numColors and clipMode
            modeStr=['view.ui.',view.ui.displayMode,'Mode'];
            mode = eval(modeStr);
            cmap = mode.cmap;    
            tmat=zeros(size(view.ui.image));
            coords=round(coords(1:2,:));    %ROI coords
            coords(coords<1)=1;
            [msize]=max(size(view.ui.image));
            
            coords(coords>msize)=msize;
            
            % These are the indices into the image of the ROI
            inds=sub2ind((size(view.ui.image)),coords(1,:),coords(2,:));
            tmat(inds)=1;
            
            % Use the image processing toolbox to dilate, erode, fill the
            % ROI.
            se=strel('disk',4,4);
            tmat=imdilate(logical(tmat),se);
            se=strel('disk',4,4);
            tmat=imerode(logical(tmat),se);
            tmat=imfill(tmat,'holes');
            tmat=tmat-min(tmat(:));
            tmat=bwperim(tmat);
            onpoints=find(tmat);
            
            [y x]=ind2sub((size(view.ui.image)),onpoints);
            
            %line(b(:,1),b(:,2),'Color',color,'LineWidth',lineWidth);
            hold on;
            lineVect=plot(x,y,'.','LineWidth',lineWidth*2);
            for t=1:length(lineVect)
                set(lineVect,'Color',color,'Marker','.','MarkerSize' ,lineWidth*15);
            end
            
            
        else % Do the regular perimeters
            
            w=0.5;
            x=coords(1,:);
            y=coords(2,:);
            
            hold on
            for i=1:size(coords,2);
                xMinus = find(x == x(i)-1);
                xEquals = find(x == x(i));
                xPlus = find(x == x(i)+1);
                if isempty(xMinus)
                    line([y(i)-w,y(i)+w],[x(i)-w, x(i)-w],'Color',color,'LineWidth',lineWidth);
                else
                    if ~any(y(i) == y(xMinus))
                        line([y(i)-w,y(i)+w],[x(i)-w, x(i)-w],'Color',color,'LineWidth',lineWidth);
                    end
                end
                if isempty(xPlus)
                    line([y(i)-w,y(i)+w],[x(i)+w, x(i)+w],'Color',color,'LineWidth',lineWidth);
                else
                    if ~any(y(i) == y(xPlus))
                        line([y(i)-w,y(i)+w],[x(i)+w, x(i)+w],'Color',color,'LineWidth',lineWidth);
                    end
                end
                if ~isempty(xEquals)
                    if ~any(y(i) == y(xEquals)-1)
                        line([y(i)+w,y(i)+w],[x(i)-w, x(i)+w],'Color',color,'LineWidth',lineWidth);
                    end
                    
                    if ~any(find(y(i) == y(xEquals)+1))
                        line([y(i)-w,y(i)-w],[x(i)-w, x(i)+w],'Color',color,'LineWidth',lineWidth);
                    end  
                end
            end
        end
        hold off
    end
end

return;
