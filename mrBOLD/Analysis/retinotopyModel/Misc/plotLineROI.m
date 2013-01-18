function line=plotLineROI(view, smoothStep, flip, titlename, plotFlag)
% plotLineROI - plot current map along a line ROI
%
% line=plotLineROI(view, smoothStep, flip, titlename, plotFlag);
%
% Arguments:
%  view : mrVista view struct
%  smoothStep : averaging steps across neighboring vertices [default=0]
%  flip       : flip line [default=false]
%  titlename  : title for plot
%
% Outputs:
%  line.x     : distance across cortical surface
%  line.y     : values in current view
%
% 2007/09 SOD: wrote it.
if ~exist('view','var') || isempty(view),
    view = getSelectedGray;
end
if ~exist('smoothStep','var') || isempty(smoothStep),
    smoothStep = 0;
else
    if smoothStep==-1, % aks subject
        ttltxt = sprintf('Enter number of smoothing steps [0 = no smoothing]');
        smoothStep = inputdlg('Number larger than 0, recommended range [0-5]:',ttltxt,1,{'0'});
        smoothStep = str2double(smoothStep{1});
        if isempty(smoothStep), smoothStep = 0; end
   end
end
if ~strcmp(view.viewType,'Gray'),
    error('This function is only defined for the Gray view');
end
if ~exist('flip','var') || isempty(flip),
    flip = false;
end
if ~exist('titlename','var') || isempty(titlename),
   titlename = [];
end
if ~exist('plotFlag','var') || isempty(plotFlag),
    plotFlag = 1;
end

mrGlobals;

% get ROI coords
roi = view.ROIs(view.selectedROI);

% get dimensions
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% get all gray coords, nodes and edges
%coords  = double(viewGet(view,'coords'));
nodes   = double(view.nodes);
edges   = double(view.edges);
numNeighbors = double(view.nodes(4,:));
edgeOffsets  = double(view.nodes(5,:));

% Get nearest gray node
allNodeIndices = zeros(1,size(roi.coords,2));
for ii=1:size(roi.coords,2)
    grayNode = find(nodes(2,:) == roi.coords(1,ii) & ...
                    nodes(1,:) == roi.coords(2,ii) & ...
                    nodes(3,:) == roi.coords(3,ii));
   
    % Catch errors. 
    if(isempty(grayNode))
        error('No gray nodes were found!');
    end
    if(length(grayNode)>1)
        fprintf('[%s]: WARNING- coord %d - more than one grayNode found!\n',mfilename,ii);
        grayNode = grayNode(1);
    end
    allNodeIndices(ii) = grayNode;
end

% HACK: find starting point: 
% Define as the point that has the largest distance to
% one other point in the line with the fewest direct neighbors. 
% This will in most cases be the end or the beginning.
allDist = zeros(numel(allNodeIndices));
for n=1:numel(allNodeIndices),
    tmp = mrManDist(nodes, edges, allNodeIndices(n), mmPerPix, -1, 0);
    allDist(:,n)    = tmp(allNodeIndices);
end

%figure;imagesc(allDist)

% nodes distances
distNodes   = zeros(numel(allNodeIndices),1);
for n=1:numel(distNodes)-1
    distNodes(n+1,1) = allDist(n,n+1);
end
distNodes =cumsum(abs(distNodes));


% get current map
curMap =  double(view.(view.ui.displayMode){view.curScan});

% smooth
if smoothStep,
    numNeighbors = numNeighbors(:);
    if ~strcmpi('ph',view.ui.displayMode),
        for n=1:smoothStep,
            curMap = sumOfNeighbors(curMap,edges,edgeOffsets,numNeighbors)./(numNeighbors+1);
        end
    else
        % phase data, so go complex, smooth and go back
        curMap = -exp(i*curMap).*double(view.co{view.curScan});
        cm_r   = real(curMap);
        cm_i   = imag(curMap);
        for n=1:smoothStep,
            cm_r = sumOfNeighbors(cm_r,edges,edgeOffsets,numNeighbors)./(numNeighbors+1);
            cm_i = sumOfNeighbors(cm_i,edges,edgeOffsets,numNeighbors)./(numNeighbors+1);
        end
        curMap = angle(cm_r+cm_i*i)+pi;
    end;
end

%%%% PLOT CODE BELOW

% line data
line.y   = curMap(allNodeIndices);
line.x   = distNodes;
line.y = line.y(:);
line.x = line.x(:);
if flip,
    line.x   = abs(line.x-max(line.x));
end

% ras 05/2008: if the user is plotting phase data, and if there are
% retinotopy params set (e.g. for mapping polar angle or eccentricity),
% auto-convert the phase values to the appropriate parameter
if strcmp(view.ui.displayMode, 'ph')
	rparams = retinoGetParams(view);
	if ~isempty(rparams)  % these parameters have been set
		if isequal(lower(rparams.type), 'polar_angle')
			% map from phase to polar angle
			line.y = polarAngle(line.y, rparams);
		else
			% assume eccentricity: map to eccentricity
			line.y = eccentricity(line.y, rparams);
		end

		% temporarily set the display mode to map, and the map name and units
		% to the relevant values (this should not propagate to the global view
		% variable)
		view.ui.displayMode = 'map';
		view.mapName = rparams.type;
		view.mapUnits = 'degrees';
	end
end

% Plot if requested
if plotFlag==1
    if strcmp(view.ui.displayMode,'ph')
        if (max(line.y)-min(line.y))>6
            % line data
            line.y   = pi-line.y;
            %line.coords = coords(:,sampleNodes);
            %line.index  = sampleNodes;
            % plot
            figure;
            hold on;
            plot(line.x,mod(line.y,2*pi)-pi,'ko-');
            plot([0 ceil(max(line.x)/10)*10],[0 0],'k');

            ylim([-pi pi])
        else
            line.y   = line.y-pi;
            % plot
            newGraphWin;
            hold on;
            plot(line.x,line.y,'ko-');
            plot([0 ceil(max(line.x)/10)*10],[0 0],'k');
            ylim([-pi pi])
        end
    else
        newGraphWin;
        hold on;
        plot(line.x,line.y,'ko-');
    end
    if ~isempty(titlename),
        title(titlename);
    end
    
    if isequal(view.ui.displayMode, 'map')
        ylabelText = sprintf('%s (%s)', view.mapName, view.mapUnits);
    else
        ylabelText = view.ui.displayMode;
    end
    ylabel(ylabelText, 'FontSize', 14, 'Interpreter', 'none');
    xlabel('distance (mm)', 'FontSize', 14, 'Interpreter', 'none');    
    
    % kalanit wanted to add this -- don't blame me!
    set(gcf, 'Color', 'w');
    
    % add a button to flip the line along the X axis, in case the hack
    % didn't correctly identify the start and end points
    cb = ['tmp = get(gca, ''Children''); ' ...
          'set(tmp(end), ''XData'', fliplr(get(tmp(end), ''XData''))); ' ...
          'clear tmp '];
    uicontrol('Style', 'pushbutton', 'Units', 'norm', ...
              'Position', [.7 .02 .1 .05], 'String', 'Flip L/R', ...
              'Callback', cb);
end

return
