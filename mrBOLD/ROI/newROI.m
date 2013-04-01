function vw = newROI(vw,name,select,color,coords, comments)
%
% vw = newROI(vw,[name],[select],[color],[coords], [comments])
%
% Makes new empty ROI, adds it to vw.ROIs, and selects it.
%
% name: name (string) for the ROI (default = 'new ROI')
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI (default 'b').
%
% djh, 1/11/98
% 
% 10.17.98 BW.  Don't call the edit dialogue box to open the ROI.
% Just open it with a default name. Use the edit dialogue when it
% is specifically called to change the name.
% 
% 6/2009 JW: added optional input arg 'comments'

% needs image size and nSlices
mrGlobals;

% Give a better default name so we don't have to bring up
% the newROI window to avoid name conflicts. -- BW
% 
if ieNotDefined('name'), name=sprintf('ROI%.0f',(size(vw.ROIs,2)+1)); end
if ieNotDefined('select'), select=1; end
if ieNotDefined('color'), color='b'; end
if ~exist('coords','var'), coords=[]; end
if ~exist('comments','var'), comments=[]; end

ROI.name=name;
ROI.viewType    = viewGet(vw,'viewType');
ROI.coords      = coords;
ROI.color       = color;
ROI.created     = datestr(now);
ROI.modified    = datestr(now);
ROI.comments    = comments;
vw = addROI(vw,ROI,select);

return;







