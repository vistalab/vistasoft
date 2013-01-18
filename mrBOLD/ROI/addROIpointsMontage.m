function view = addROIpointsMontage(view)
%
% view = addROIpointsMontage(view)
%
% Adds/removes user-specified points to selected ROI in current slice.
%
% If you change this function make parallel changes in:
%   all addROI*.m functions
%
% djh, 7/98
%
% Bugs: If you add a point that's on remCoords then we need to
% remove it from remCoords. (Fixed by ras, 09/04).

% if no current ROI, make a new one
if view.selectedROI==0,    view = newROI(view);   end

% Get current ROI coords
curCoords = getCurROIcoords(view);

% Save prevSelpts for undo
view.prevCoords = curCoords;

msg='Click left to add points, middle to remove points, right to quit';
msgboxHandle = mrMessage(msg,'left','ur',12);

% Select the window
set(0,'CurrentFigure',view.ui.windowHandle)

% Loop until right button is clicked, collecting new coordinates
% and drawing temporary squares around selected pixels.
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
    
    % convert from montage img coords -> view coords
    newCoords = montage2Coords(view,[y x]');
    z = newCoords(3,:); % slice #
    		    
    % set to add/remove point, based on button pressed
    if button ~= 3
        count = count+1;
        if button == 1
            addCoords = [addCoords, newCoords];
            h(count) = line([x-w,x-w,x+w,x+w,x-w],...
                [y-w,y+w,y+w,y-w,y-w],...
                'Color','w');  
            
            % if you'd accidentally removed this
            % before, take it out of remCoords
            if ismember([y x z],remCoords','rows')
                remCoords = setdiff(remCoords',newCoords,'rows')';
            end
            
        elseif button == 2
            remCoords = [remCoords, newCoords];
            h(count) = line([x-w,x-w,x+w,x+w,x-w],...
                [y-w,y+w,y+w,y-w,y-w],...
                'Color','k');  
        end
    end
    
end

close(msgboxHandle);

% Delete the temporarily drawn squares
for i=1:count
    delete(h(i));
end

% Do an (inverse) rotation if necessary
if (strcmp(view.viewType,'Flat'))
    addCoords=(rotateCoords(view,addCoords,1));
end

% Convert coords to canonical frame of reference
addCoords = curOri2CanOri(view,addCoords);
remCoords = curOri2CanOri(view,remCoords);

% Merge and remove new coordinates
coords = mergeCoords(curCoords,addCoords);
coords = removeCoords(remCoords,coords);
view.ROIs(view.selectedROI).coords = coords;

view.ROIs(view.selectedROI).modified = datestr(now);

return
