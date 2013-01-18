function vw = drawROIsMontage(vw)
%
% vw = drawROIsMontage(vw)
% 
% Draw the ROIs on a montage view (e.g. several 
% flat levels / inplane slices at once). 
%
% This function should be called only if
% vw.showROIs is non-zero.  If showROIs=1, draw only the
% selected ROI.  If showROIs=2, draw all the ROIs.
% 09/04 ras, off drawROIs.

% clear line handles for all ROIs (ras 06/06, see selectROI)
for r=1:length(vw.ROIs), vw.ROIs(r).lineHandles = []; end

% set line width parameter
w = 0.5;

s = vw.selectedROI;
n = length(vw.ROIs);

%%%%% get order of ROIs to display
if s
    order = [1:s-1,s+1:n,s];
else
    order = 1:n;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop: draw ROIs according to prefs  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for r = order   % loop through ROIs that are selected for display
    if (r==vw.selectedROI)
        % Selected ROI: now a settable param, ras 05/05
        coords = vw.ROIs(r).coords;
        color = viewGet(vw,'selRoiColor');
    else
        % Non-selected ROI, color from ROIs substruct
        % If showROIs~=2, then set coords=[] so that nothing will be
        % drawn. 
        if (vw.ui.showROIs==-2)
            coords = vw.ROIs(r).coords;
        else
            coords = [];
        end
        thisCol=vw.ROIs(r).color;
        % If it's a 'text' color, translate it...
        if (ischar(thisCol))
        nColEntries=length(thisCol);

        for thisColEntry=1:nColEntries
            thisColValue=thisCol(thisColEntry);
            colRGB=[0 0 0];
            switch (thisColValue)
                case 'y', colorRGB = colRGB+[1 1 0];
                case 'm', colorRGB = colRGB+[1 0 1];
                case 'c', colorRGB = colRGB+[0 1 1];
                case 'r', colorRGB = colRGB+[1 0 0];
                case 'g', colorRGB = colRGB+[0 1 0];
                case 'b', colorRGB = colRGB+[0 0 1];
                case 'w', colorRGB = colRGB+[1 1 1];
                case 'k', colorRGB = colRGB+[0 0 0];                
                otherwise, colorRGB = [1 1 1];
            end % end switch statement
        end % end loop
            color=colorRGB./nColEntries;
        else
            color=thisCol;
        end
        
    end
    
    % Draw the lines around each pixel, w=1/2 because you don't
    % want to connect the centers of the pixels, rather you want to
    % draw around each pixel, e.g, from (x-.5,y-.5) to (x+.5,y-.5).
    if ~isempty(coords)
        
        % The FLAT view can have a 'rotateImageDegrees' field that
        % specifies a rotation angle for L and R. 
        % If this is set, then we have to transform the ROIs by this amount as
        % well to make them register with the anatomy and functional data
        if (strcmp(vw.viewType,'Flat'))
            coords=rotateCoords(vw,coords);
        end

        % convert to coordinates of the montage image
        coords = coords2Montage(vw,coords);
        x = coords(1,:);
        y = coords(2,:);
        
        % draw boxes around the voxels
        hold on

        % if the view is set to flip the image, then we need to
        % flip the ROI too       
        if viewGet(vw, 'flip up down'), 
            height = size(vw.ui.image, 1);
            x = height - x + 1; 
        end
        
        for i=1:size(coords,2);
            l(i) = line([y(i)-w, y(i)+w, y(i)+w, y(i)-w, y(i)-w],...
                        [x(i)-w, x(i)-w, x(i)+w, x(i)+w, x(i)-w], ...
                        'Color',color);  
        end
        hold off
        

%         % remember line handles for quick refreshing
%         vw.ROIs(r).lineHandles = l;
    end 
end

return;


