function rxShowPoints(rx);
%
% rxShowPoints(rx);
%
% Display any selected corresponding
% points b/w the prescribed volume and
% reference volume on the current slices.
%
% ras 03/05.
if ~exist('rx', 'var') | isempty(rx)
    cfig = findobj('Tag',  'rxControlFig');
    rx = get(cfig, 'UserData');
end

if ~isfield(rx, 'points') | isempty(rx.points) | isempty(rx.points{1})
    % exit quietly
    return
end


rxSlice = get(rx.ui.rxSlice.sliderHandle, 'Value');
volpts = rx.points{1};
refpts = rx.points{2};

% check whether there are any points to display 
% on the current rx (==ref) slice:
whichPoints = find(refpts(3, :)==rxSlice);

if isempty(whichPoints)
    % exit quietly
    return
end

% get ready show the points
volpts = volpts(:,whichPoints);
refpts = refpts(:,whichPoints);
nPoints = size(volpts, 2);
cmap = cool(24);

% convert volpts to reference coords
volpts = vol2rx(rx, volpts);

%%%%%%%%%%%%%%%%%%%
% show the points %
%%%%%%%%%%%%%%%%%%%
%%%%% prescribed slice pts
if ishandle(rx.ui.interpFig)
    figure(rx.ui.interpFig);
	hold on
	
	% figure out how high above each point
	% to place the label:
	AX = axis;
	yoffset = 0.05 * (AX(4)-AX(3));
	
	for i = 1:nPoints
       col = cmap(mod(whichPoints(i)-1, 24)+1, :);
       plot(volpts(1, i), volpts(2, i),  'o',  'Color', col);
       text(volpts(1, i), volpts(2, i)-yoffset, ...
           num2str(whichPoints(i)),  'Color', col);
	end
end

%%%%% reference pts
if ishandle(rx.ui.refFig)
    figure(rx.ui.refFig);
	hold on
	
	% figure out how high above each point
	% to place the label:
	AX = axis;
	yoffset = 0.05 * (AX(4)-AX(3));
	
	for i = 1:nPoints
       col = cmap(mod(whichPoints(i)-1, 24)+1, :);
       plot(refpts(1, i), refpts(2, i),  'o',  'Color', col);
       text(refpts(1, i), refpts(2, i)-yoffset, ...
           num2str(whichPoints(i)),  'Color', col);
	end
end


return

