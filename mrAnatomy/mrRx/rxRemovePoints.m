function rx = rxRemovePoints(rx,whichPoints);
% rx = rxRemovePoints([rx],[whichPoints]);
%
% Remove pairs of corresponding points (b/w
% prescribed and reference volumes) in mrRx.
%
% whichPoints should be an index into the
% set of selected points. If omitted, will
% pop up a dialog.
%
%
% ras 03/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end   

% check that there are points to remove
if ~isfield(rx,'points') | isempty(rx.points{1})
    msg = 'No points to remove! ';
    msg = [msg 'Select Edit | Points | Add Points.'];
    myWarnDlg(msg);
    return
end

nPoints = size(rx.points{1},2);

if ieNotDefined('whichPoints')
    % build up a points list
    for i = 1:nPoints
        % we'll use the reference coords
        y = rx.points{2}(1,i); % y = rows
        x = rx.points{2}(2,i); % x = cols
        z = rx.points{2}(3,i);        
        txt = sprintf('Point %i, Slice %3.0f, row %3.0f, col %3.0f',i,z,y,x);
        pointsList{i} = txt;
    end
    
    % have user select points
    [whichPoints, ok] = listdlg('PromptString','Delete which points?',...
                                'ListSize',[400 600],...
                                'ListString',pointsList,...
                                'InitialValue',1 ,...
                                'OKString','OK');
                            
    % exit gracefully if canceled                
	if ~ok  return;  end
end

% remove the points
keepPoints = setdiff(1:nPoints,whichPoints);
rx.points{1} = rx.points{1}(:,keepPoints);
rx.points{2} = rx.points{2}(:,keepPoints);

% set in GUI if it's still open
if ishandle(rx.ui.controlFig)
    set(rx.ui.controlFig,'UserData',rx);
end

rxRefresh(rx);

return