function dtiShowROIs(handles);
%
%  dtiShowROIs(handles);
%
%Author: Dougherty, Wandell
%Purpose:
%   Manage display of the ROIs on the dtiFiberUI
%

% Programming notes:  We are not checking the .visible, I think.
mmPerVoxel = dtiGet(handles,'mmPerVoxelCurrentBG');
sliceSlop = mmPerVoxel./2;
if isempty(handles.rois), return; end

showTheseRois = dtiROIShowList(handles);
curPosition   = dtiGet(handles,'curpos');
glassbrain    = dtiGet(handles,'glassbrain');

for(ii=showTheseRois)
    if(~isempty(handles.rois(ii).coords) & handles.rois(ii).visible)
      rgbaColor = dtiRoiGetColor(handles.rois(ii));
        if(glassbrain)
            rc = handles.rois(ii).coords(:,[1,2]);
        else
            indx = handles.rois(ii).coords(:,3) >= curPosition(3)-sliceSlop(3) ...
                & handles.rois(ii).coords(:,3) <= curPosition(3)+sliceSlop(3);
            rc = handles.rois(ii).coords(indx,[1,2]);
        end
        if(~isempty(rc))
            axes(handles.z_cut); hold on;
            h = plot(rc(:,1), rc(:,2), 'k.');
            set(h,'Color', rgbaColor(1:3));
            hold off;
        end
        if(glassbrain)
            rc = handles.rois(ii).coords(:,[1,3]);
        else
            indx = handles.rois(ii).coords(:,2) >= curPosition(2)-sliceSlop(2) ...
                & handles.rois(ii).coords(:,2) <= curPosition(2)+sliceSlop(2);
            rc = handles.rois(ii).coords(indx,[1,3]);
        end
        if(~isempty(rc))
            axes(handles.y_cut); hold on;
            h = plot(rc(:,1), rc(:,2), 'k.');
            set(h,'Color', rgbaColor(1:3));
            hold off;
        end
        if(glassbrain)
            rc = handles.rois(ii).coords(:,[2,3]);
        else
            indx = handles.rois(ii).coords(:,1) >= curPosition(1)-sliceSlop(1) ...
                & handles.rois(ii).coords(:,1) <= curPosition(1)+sliceSlop(1);
            rc = handles.rois(ii).coords(indx,[2,3]);
        end
        if(~isempty(rc))
            % Again, to flip left right, we could apply a formula here. 
            axes(handles.x_cut); hold on;
            h = plot(rc(:,1), rc(:,2), 'k.');
            set(h,'Color', rgbaColor(1:3));
            hold off;
        end
    end
end

return;
