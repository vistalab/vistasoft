function vw = drawROIsPerimMontage(vw, lineWidth)
%
% vw = drawROIsPerimMontage(vw, [lineWidth])
%
% Draws a line around the ROIs, for montage view.
% This function should be called only if
% vw.showROIs is non-zero.  If showROIs=-1, draw only the
% selected ROI.  If abs(showROIs)=2, draw all the ROIs.
% ras 09/04, off drawROIsPerimeter.
if ~exist('lineWidth', 'var'), lineWidth = 0.5;  end
if ~exist('vw', 'var'), vw = getSelectedInplane; end

%%%%% get info about the montage size, slice size
ui = viewGet(vw,'ui');
viewType = viewGet(vw,'viewType');
switch viewType
    case 'Inplane',
        firstSlice = viewGet(vw, 'curSlice');
        nSlices = get(ui.montageSize.sliderHandle,'Value');
        selectedSlices = firstSlice:firstSlice+nSlices-1;
        selectedSlices = selectedSlices(selectedSlices <= viewGet(vw, 'numSlices'));
    case 'Flat',
        selectedSlices = getFlatLevelSlices(vw);
        nSlices = length(selectedSlices);
    otherwise,
        error('drawROIsMontage: no support for this view type.');
end
nrows = ceil(sqrt(nSlices));
ncols = ceil(nSlices/nrows);
colSz = round(ui.zoom(2)-ui.zoom(1)+1);
rowSz = round(ui.zoom(4)-ui.zoom(3)+1);
xcorner = ui.zoom(3) - 1; % location of upper-right corner w/ zoom
ycorner = ui.zoom(1) - 1;

% clear line handles for all ROIs (ras 06/06, see selectROI)
for r=1:length(vw.ROIs), vw.ROIs(r).lineHandles = []; end
l = [];

for r=1:length(vw.ROIs)
    % Selected ROI: set color=white
    if (r==vw.selectedROI)
        coords = vw.ROIs(r).coords;
        color = viewGet(vw,'selRoiColor');
        % Non-selected ROI, get coords, get color
    else
        % If showROIs~=2, then set coords=[] so that nothing will be
        % drawn.
        if (vw.ui.showROIs==-2)
            coords = vw.ROIs(r).coords;
        else
            coords = [];
        end

        %color=vw.ROIs(r).color;
        % We can now have many different colors in our ROIs. So we need
        % some way of translating the (more than 1-character) 'color' into
        % a color vector.
        thisCol=vw.ROIs(r).color;
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

    %%%%% big subloop: go through selected slices in montage
    for iSlice = 1:length(selectedSlices)
        curSlice = selectedSlices(iSlice);

        % Get subset of coords corresponding to the current slice
        if ~isempty(coords)
%             coords = canOri2CurOri(vw,coords);
            indices = coords(3,:)==curSlice;
            subCoords = coords(:,indices);
        else
            subCoords = [];
        end

        % Draw the lines around each pixel's edge that doesn't have a neighbor
        % w=1/2 because you want to draw the outside boarder, not the pixel
        % centers
        if ~isempty(subCoords)

            % The FLAT view can have a 'rotateImageDegrees' field that
            % specifies a rotation angle for each slice (L or R).
            % If this is set, then we have to transform the ROIs by this amount as
            % well to make them register with the anatomy and functional data
            if isfield(vw,'rotateImageDegrees')
                subCoords = rotateCoords(vw,subCoords,0);
            end

            % further restrict to coordinates contained within the
            % zoom settings:
            if checkfields(vw, 'ui', 'zoom')
                Y = vw.ui.zoom(3:4); % ymin ymax
                X = vw.ui.zoom(1:2); % xmin xmax
                ok = subCoords(1,:)>=Y(1) & ...
                    subCoords(1,:)<=Y(2) & ...
                    subCoords(2,:)>=X(1) & ...
                    subCoords(2,:)<=X(2);
                subCoords = subCoords(:,ok);
            end
            

            % What sort of perimeter shall we draw? 'filled Perimeters' get rid
            % of the blobby effect that transforming from the volume view
            % sometimes causes.
            doFilledPerimeter=0;
            if (isfield(vw.ui,'filledPerimeter')) && (vw.ui.filledPerimeter)
                doFilledPerimeter=1;
            end

            if (doFilledPerimeter)
                tmat=zeros(size(vw.ui.image));

                % figure out offset sizes for different
                % locations in the montage
                row = ceil(iSlice/ncols);
                col = mod(iSlice-1,ncols) + 1;
                yoffset = (col-1) * colSz;
                xoffset = (row-1) * rowSz;

                % get the x, y coords of the pixels
                subCoords(1,:)=subCoords(1,:) + xoffset - xcorner;
                subCoords(2,:)=subCoords(2,:) + yoffset - ycorner;

                % clip subCoords: may not be necessary for montage
                subCoords=round(subCoords(1:2,:));
                [msize]=max(size(vw.ui.image));
                subCoords(subCoords<1)=1;
                subCoords(subCoords>msize)=msize;

                % These are the indices into the image of the ROI
                inds=sub2ind((size(vw.ui.image)),subCoords(1,:),subCoords(2,:));
                tmat(inds)=1;

                % Use the image processing toolbox to dilate, erode, fill the
                % ROI.
                se=strel('disk',4,4);
                tmat=imdilate(logical(tmat),se);
%                 se=strel('disk',4,4);
                tmat=imerode(logical(tmat),se);
                tmat=imfill(tmat,'holes');
                tmat=tmat-min(tmat(:));
                tmat=bwperim(tmat);
                onpoints=find(tmat);

                [y x]=ind2sub((size(vw.ui.image)),onpoints);

                %line(b(:,1),b(:,2),'Color',color,'LineWidth',lineWidth);
                hold on;
                
                % if the view is set to flip the image, then we need to
                % flip the ROI too
                if viewGet(vw, 'flip up down'), x = rowSz - x + 1; end

                l = plot(x,y,'.','LineWidth',lineWidth*2);
                set(l, 'Color',color, 'Marker','.', 'MarkerSize',lineWidth*15);
            else
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Do the regular perimeters %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % figure out offset sizes for different
                % locations in the montage
                row = ceil(iSlice/ncols);
                col = mod(iSlice-1,ncols) + 1;
                yoffset = (col-1) * colSz;
                xoffset = (row-1) * rowSz;

                % get the x, y coords of the pixels
                w = lineWidth;
                x = subCoords(1,:) + xoffset - xcorner;
                y = subCoords(2,:) + yoffset - ycorner;
               
                % if the view is set to flip the image, then we need to
                % flip the ROI too
                if viewGet(vw, 'flip up down'), x = rowSz*nrows - x + 1; end

                hold on
                for i=1:size(subCoords,2);
                    xMinus = find(x == x(i)-1);
                    xEquals = find(x == x(i));
                    xPlus = find(x == x(i)+1);
                    if isempty(xMinus)
                        l(end+1) = line([y(i)-w,y(i)+w], [x(i)-w, x(i)-w], ...
                                'Color', color, 'LineWidth', lineWidth);
                    elseif ~any(y(i) == y(xMinus))
                        l(end+1) = line([y(i)-w,y(i)+w], [x(i)-w, x(i)-w], ...
                                'Color', color, 'LineWidth', lineWidth);
                    end
                    if isempty(xPlus)
                        l(end+1) = line([y(i)-w,y(i)+w], [x(i)+w, x(i)+w], ...
                                'Color', color, 'LineWidth', lineWidth);
                    elseif ~any(y(i) == y(xPlus))
                        l(end+1) = line([y(i)-w,y(i)+w], [x(i)+w, x(i)+w], ...
                                'Color', color, 'LineWidth', lineWidth);
                    end
                    if ~isempty(xEquals)
                        if ~any(y(i) == y(xEquals)-1)
                            l(end+1) = line([y(i)+w y(i)+w], [x(i)-w x(i)+w], ...
                                'Color', color, 'LineWidth', lineWidth);
                        end

                        if ~any(find(y(i) == y(xEquals)+1))
                            l(end+1) = line([y(i)-w y(i)-w], [x(i)-w x(i)+w], ...
                                'Color', color, 'LineWidth', lineWidth);
                        end
                    end

%                     set(l, 'Color', color, 'LineWidth', lineWidth);
                end  % drawing regular perimeters

                % remember line handles for quick refreshing
                vw.ROIs(r).lineHandles = l(l>0);
            end     % filled vs. reg perimeter if statemnt

            hold off
        end     % if ~isempty(subCoords)
    end     % loop through selected slices
end

return;
