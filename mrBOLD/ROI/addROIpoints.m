function vw = addROIpoints(vw)
%
% vw = addROIpoints(vw)
%
% Adds/removes user-specified points to selected ROI in current slice.
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%
% djh, 7/98
%
% Bugs: If you add a point that's on remCoords then we need to
% remove it from remCoords.  (Fixed by ras, 09/04).

% if no current ROI, make a new one
if vw.selectedROI==0,    vw = newROI(vw);   end

% Get current ROI coords
curCoords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = curCoords;

msg='Click left to add points, middle to remove points, right to quit';
msgboxHandle = mrMessage(msg,'left','ur',12);

% Select the window
set(0,'CurrentFigure',vw.ui.windowHandle)

% Loop until right button is clicked, collecting new coordinates
% and drawing temporary squares around selected pixels.
z = viewGet(vw, 'Current Slice');
hold on 
w=0.5;
button = 0;
count = 0;
addCoords = [];
remCoords = [];
while button ~= 3
    [x,y,button] = ginput(1);
    x = round(x); 
    y = round(y);
    if button ~= 3
        count = count+1;

        if button == 1
            addCoords = [addCoords, [y x z]'];
            h(count) = line([x-w,x-w,x+w,x+w,x-w],...
                [y-w,y+w,y+w,y-w,y-w],...
                'Color','w');  
            
            % if you'd accidentally removed this
            % before, take it out of remCoords
            if ismember([y x z],remCoords','rows')
                remCoords = setdiff(remCoords',[y x z],'rows')';
            end

        elseif button == 2
            remCoords = [remCoords, [y x z]'];
            h(count) = line([x-w,x-w,x+w,x+w,x-w],...
                [y-w,y+w,y+w,y-w,y-w],...
                'Color','k');  
        end
        
    end
end

close(msgboxHandle);

% Delete the temporalily drawn squares
for i=1:count
    delete(h(i));
end
% Do an (inverse) rotation if necessary
if (strcmp(vw.viewType,'Flat'))
    addCoords=(rotateCoords(vw,addCoords,1));
end

% Convert coords to canonical frame of reference
addCoords = curOri2CanOri(vw,addCoords);
remCoords = curOri2CanOri(vw,remCoords);

% Merge and remove new coordinates
coords = mergeCoords(curCoords,addCoords);
coords = removeCoords(remCoords,coords);
vw.ROIs(vw.selectedROI).coords = coords;

vw.ROIs(vw.selectedROI).modified = datestr(now);

