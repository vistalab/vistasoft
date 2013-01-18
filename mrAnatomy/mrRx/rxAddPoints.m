function rx = rxAddPoints(rx, volpts, refpts);
%
% rx = rxAddPoints([rx], [volpts, refpts]):
%
% Selected corresponding points between the
% prescribed and reference volume in mrRx.
% 
% If the volpts and inpts are omitted,  the user
% selects the points graphically in a manner
% similar to mrAlign3. Otherwise (in case it
% for some reason is useful),  they can
% be entered as arrays in which each column
% specifies a point,  in S/I,  A/P,  and R/L 
% coords,  respectively,  for each row (same
% as mrAlign3).
%
%
% ras 03/05
if notDefined('rx')
    cfig = findobj('Tag', 'rxControlFig');
    rx = get(cfig, 'UserData');
end   

if ~isfield(rx, 'points') | isempty(rx.points),  rx.points = cell(1, 2); end

if notDefined('volpts') | notDefined('refpts')
    %%%%%%%%%%%%%%%%%%%
    % get graphically %
    %%%%%%%%%%%%%%%%%%%    
    % make sure the interp and ref figures are open
    if ~ishandle(rx.ui.interpFig)
        rx = rxOpenInterpFig;
    end
    
    if ~ishandle(rx.ui.refFig)
        rx = rxOpenRefFig;
    end
    
	% we clear the current character property of the figure, to allow
	% use of the 'q' button to quit:
	set(rx.ui.refFig, 'CurrentCharacter', 'w');
	set(rx.ui.interpFig, 'CurrentCharacter', 'w');
	
	% put up an instructions message
    msg = 'Select corresponding points in Prescribed and Reference Figs. ';
    msg = [msg 'Click in the yellow-highlighted figure. '];
    msg = [msg 'LEFT button to select points,  RIGHT button or ''q'' to quit. '];
    hmsg = mrMessage(msg, 'left', [.12 .35 .2 .2], 12);
    
    % run loop to get points
	button = 0;
    volpts = [];
    refpts = [];
    rxSlice = get(rx.ui.rxSlice.sliderHandle, 'Value');
    cnt = 1; % index to color seq
    cmap = cool(24);
	
	while button ~= 3
        col = cmap(mod(cnt-1, 24)+1,:);
        
        figure(rx.ui.refFig);
        hold on
        set(rx.ui.refFig, 'Color', 'y');
        title('Select Point on Reference Slice')
		[x1, y1, button] = mrGinput(1, 'cross');
        set(rx.ui.refFig, 'Color', 'w');

        % mark the point
        plot(x1, y1, 'o', 'Color', col);
        text(x1, y1-10, num2str(cnt), 'Color', col);
        
		% test for q key (in case right mouse button isn't available)
		if get(gcf, 'CurrentCharacter')=='q'
			button = 3;
		end		
		
        if button==3
            % don't force the user to 
            % pick the next point
            break;
        end
        
        figure(rx.ui.interpFig);
        hold on
        set(rx.ui.interpFig, 'Color', 'y');
        title('Select Point on Prescribed Slice')
		[x2, y2, button] = mrGinput(1, 'cross');
        set(rx.ui.interpFig, 'Color', 'w');
        
        % mark the point
        plot(x2, y2, 'o', 'Color', col);
        text(x2, y2-10, num2str(cnt), 'Color', col);

        % round to nearest voxel,  and
        % compensate for translation
        % (see note at top):
        newPt1 = [x1; y1; rxSlice];
        newPt2 = [x2; y2; rxSlice];
        
        % convert 2nd (interp) pt into 
        % volume coordinates using xform:
        newPt2 = rx2vol(rx, newPt2);
        
        volpts = [volpts newPt2];
        refpts = [refpts newPt1];
        
        cnt = cnt + 1;
		
		% test for q key (in case right mouse button isn't available)
		if get(gcf, 'CurrentCharacter')=='q'
			button = 3;
		end
    end
    
    close(hmsg);
end


%%%%%%%%%%%%%%%%%%%% 
% set in rx struct %
%%%%%%%%%%%%%%%%%%%%
if isfield(rx, 'points')
    points = rx.points;
else
    points = cell(1, 2);
end

points{1} = [points{1} volpts];
points{2} = [points{2} refpts];

rx.points = points;

if ishandle(rx.ui.controlFig)
    set(rx.ui.controlFig, 'UserData', rx);
end

rxRefresh(rx);


return