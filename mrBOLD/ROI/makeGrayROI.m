function vw = makeGrayROI(vw,name,select,color)
%
% vw = makeGrayROI(vw,[name],[select],[color])
%
% Makes an ROI consisting of all of the gray.coords
%
% name: name (string) for the ROI (default = 'gray')
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI (default 'b').
%
% djh, 2/15/2001
% 09/2005 ras, if non-gray view, makes it in a hidden gray and xforms over

% needs image size and nSlices
mrGlobals;


if notDefined('name'),      name='gray'; end
if notDefined('select'),    select=1;    end
if notDefined('color'),     color=[.6 .6 .6]; end 
    
if ~strcmp(vw.viewType,'Gray')
    % make a gray ROI in a hidden gray view,
    % and xform it over
    % (but, first check if a segmentation is installed)
    if ~exist(fullfile('Gray','coords.mat'), 'file')
        error('No Segmentation currently installed.');
    end
    
    dt = viewGet(vw,'curdt');
    scan = viewGet(vw,'curscan');
    hG = initHiddenGray(dt,scan);
    hG = makeGrayROI(hG,name,select,color);
    switch vw.viewType
        case 'Inplane', vw = vol2ipAllROIs(hG,vw);
        case 'Flat', vw = vol2flatAllROIs(hG,vw);
        case 'Volume', vw = addROI(vw,hG.ROIs);
        otherwise, error('Unkown view type.');
    end
            
    return
end


ROI.name=name;
ROI.viewType=vw.viewType;
ROI.coords=vw.coords;
ROI.color=color;

vw = addROI(vw,ROI,select);

return;
