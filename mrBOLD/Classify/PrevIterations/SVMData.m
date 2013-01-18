classdef SVMData < handle
    properties
        data
        conditions
        labels
        trials
        nTrials
        groups
        groupLabels
    end
    
    methods
        %%
        function obj = SVMData(raw)
        % SVMData(raw)
        %   Constructor for SVMData.   
        %
        % @param rawDataClass raw
        % @return SVMData obj
        %
            if (exist('raw','var'))
                type = class(raw);
                switch (type)
                    case {'TimeSeriesData'}
                        obj.(['convert' type])(raw);
                    otherwise
                        fprintf(1,'\nUnrecognized data type.\n');
                end
            else
                fprintf(1,'\nObject created.  No data loaded.\n');
            end
        end
        
        %%
        function plot(obj, selectedData, color)
        % plot(selectedData, colorMap)
        %   Plots N rows of images depicting the data values with a
        %   colormap for ease of visual inspection.
        % 
        %   Usage (Function):
        %       obj.plot({2, 3, 'first'; 3:4, 7:9, 'second'}, 'autumn');
        %       The first row will be condition 2, trial 3, label 'first', 
        %       while the second row will be the mean of conditions 3 and 
        %       4, trials 7 through 9, label 'second'.
        %
        %   Usage (Plot):
        %       Click and drag the mouse upon the plot to zoom in.  Click
        %       without dragging to zoom out one step from where you were.
        %
        % @param Nx2_cellarray<vector<int>> selectedData
        % @param string colorMap
        % @return void
        %
            figureHandle = figure;
            isDataSelected = (exist('selectedData','var'));
            if (isDataSelected)
                nRows = size(selectedData, 1);
                dataToPlot = zeros(nRows,size(obj.data,2));
                for i = 1:nRows
                    dataToPlot(i,:) = mean(obj.data(...
                        ismember(obj.conditions, selectedData{i,1}) ...
                        & ismember(obj.trials, selectedData{i,2}),:),1);
                end
            else
                nRows = length(obj.labels);
                dataToPlot = zeros(nRows,size(obj.data,2));
                for i = 1:nRows
                    dataToPlot(i,:) = mean(obj.data(...
                        ismember(obj.conditions, i) ...
                        & ismember(obj.trials, 1:obj.nTrials(i)),:),1);
                end
            end
            
            if (~exist('color','var')), color = 'bone'; end
            colormap(color);
            
            imagesc(dataToPlot);
            set(gca, 'YTick', 1:nRows);
            if (isDataSelected)
                set(gca, 'YTickLabel', selectedData(:,3));
            else
                set(gca,'YTickLabel', obj.labels);
            end

            startLine = line(0,0);
            endLine = line(0,0);
            xClick = [0, size(dataToPlot,2)];
            xLimits = xClick;
            clickHistory = [0, size(dataToPlot,2)];
            set(figureHandle,...
                'WindowButtonUpFcn', @stopDragCallback, ...
                'WindowButtonDownFcn', @startDragCallback);
            
            function startDragCallback(varargin)
                point = get(gca,'CurrentPoint');
                xValue = point(1);
                if (xValue > 0 || xValue < size(dataToPlot,2))
                    set(startLine, ...
                        'XData', [xValue xValue], ...
                        'YData', [0 (nRows + .5)]);
                    set(endLine, ...
                        'XData', [xValue xValue], ...
                        'YData', [0 (nRows + .5)]);
                    xClick = ones(1,2)*round(xValue);
                    set(figureHandle, 'WindowButtonMotionFcn', @draggingCallback);
                end
            end
            
            function stopDragCallback(varargin)
                set(figureHandle, 'WindowButtonMotionFcn', '');
                set(startLine, 'XData', 0, 'YData', 0);
                set(endLine, 'XData', 0, 'YData', 0);
                if (xClick(1) < xClick(2))
                    clickHistory = [clickHistory; xClick];
                elseif (xClick(1) > xClick(2))
                    xClick = fliplr(xClick);
                    clickHistory = [clickHistory; xClick];
                elseif (xClick(1) == xClick(2))
                    lastClick = size(clickHistory,1);
                    if (lastClick > 1)
                        clickHistory(lastClick,:) = [];
                        xClick = clickHistory(lastClick - 1,:);
                    elseif (lastClick == 1)
                        xClick = clickHistory(1,:);
                    end
                end
                xLimits = xClick;
                set(gca, 'XLim', xClick);

            end

            function draggingCallback(varargin)
                point = get(gca,'CurrentPoint');
                xValue = point(1);
                if (xValue > xLimits(1) && xValue <= xLimits(2))
                    set(endLine, ...
                        'XData', [xValue xValue]);
                    xClick(2) = round(xValue);
                end
                
            end
        end
        
        %%
        function convertTimeSeriesData(obj, raw)
        % convertTimeSeriesData(raw)
        %   Read a TimeSeriesData object and get the data into SVM format.
        %
        % @param TimeSeriesData raw
        % @return void
        %
                if (isempty(raw.analysis))
                    raw.loadTimeCourses();
                end
                nVoxels                     = length(raw.analysis);
                [nTimePoints nConds]        = size(raw.analysis(1).meanTcs);
                obj.labels                  = strtrim(raw.analysis(1).labels)';
                obj.nTrials                 = zeros(1,nConds);

                for i = 1:nConds
                    obj.nTrials(i) = length(raw.analysis(1).allTcs(1,~isnan(raw.analysis(1).allTcs(1,:,i)),i));
                end

                temp = zeros([size(raw.analysis(1).allTcs) nVoxels]);
                for i = 1:nVoxels
                    temp(:,:,:,i) = raw.analysis(i).allTcs;
                end
                temp = permute(temp, [2 1 3 4]);

                totalTrials              = sum(obj.nTrials);
                obj.data                 = zeros(totalTrials,nVoxels*nTimePoints);
                obj.conditions           = zeros(totalTrials, 1);
                obj.trials               = zeros(totalTrials, 1);
                obj.groups               = zeros(totalTrials, 1);

                for i = 1:nConds
                    startIndex    = sum(obj.nTrials(1 : (i - 1))) + 1;
                    endIndex      = startIndex + obj.nTrials(i) - 1;
                    obj.data(startIndex : endIndex, :) = ...
                        reshape(temp(1 : obj.nTrials(i), :, i, :), obj.nTrials(i), nVoxels * nTimePoints);
                    obj.conditions(startIndex : endIndex) = i;
                    obj.trials(startIndex : endIndex) = 1:obj.nTrials(i);
                end
        end
        
        %% I'm unhappy with the way labels and groups are handled...
        function group(obj, conditions, groupName)
        % group(conditions, groupName)
        %   Groups a set of conditions for SVM training.
        %
        % @param vector<int> conditions
        % @param string groupName
        % @return void
        %
            if (~exist('conditions','var'))
                conditions = obj.promptUser('Enter condition(s): ', {1:length(obj.labels)});
            end
            
            if (length(conditions) == 1)
                tellUser('Please select more than one condition when grouping.');
                return;
            end
            
            % Checks if we've already grouped these conditions
            if (sum(ismember(obj.conditions(find(obj.groups)),conditions)) ~= 0)
                tellUser(['One or more of the specified conditions have already '...
                    'been grouped.\nUngroup and rerun, or choose different conditions.']);
                return;
            end
            
            targetIndices = ismember(obj.conditions, conditions);
            
            obj.groups(targetIndices) = conditions(1);
            
            if (exist('groupName','var'))
                obj.groupLabels = [obj.groupLabels; {conditions(1), groupName}];
            end
            
        end
        
        %% Ditto from the groupSVM function
        function ungroup(obj)
        % ungroup()
        %   Run to remove groupings of training groups.
        %
        % @return void
        %
            obj.groups(:,1) = 0;
        end
        
        %%
        function clonedObject = clone(obj)
        % clonedObject = clone()
        %   Generate a deep copy of the object.
        % 
        % @return SVMData clonedObject
        %
            clonedObject = SVMData();
            classInfo = metaclass(obj);
            nProperties = length(classInfo.Properties);
            for i = 1:nProperties
                if (~classInfo.Properties{i}.Constant)
                    name = classInfo.Properties{i}.Name;
                    clonedObject.(name) = obj.(name);
                end
            end
        end
    end
    
    methods (Static)
        %%
        function userResponse = promptUser(userMessage, acceptableInput)
        % userResponse = promptUser(userMessage, acceptableInput)
        %   Prompt user with message and limit acceptable responses.
        %
        %   Usage:
        %       resp = promptUser('Give me 1, 2, or 3: ', [1 2 3]);
        %       resp = promptUser('What is your name? ', 'string');
        %       resp = promptUser('How about a vector?', {1:8});
        %
        % @param string userMessage
        % @param string|vector<int>|cellarray acceptableInput
        % @return string|int|vector<int> userResponse
        %
            while (true)
                try
                    userResponse = input(userMessage);
                catch %#ok<*CTCH>
                    tellUser('Erroneous input: Could not process input.');
                    continue;
                end
                
                if (isa(acceptableInput, 'char'))
                    if (isa(userResponse, 'char'))
                        break;
                    else
                        tellUser('Erroneous input: Please enter a string.');
                    end
                elseif (isa(acceptableInput,'cell'))
                    if (~isa(userResponse, 'char')) && ...
                            (length(intersect(acceptableInput{1}, userResponse)) ...
                            == length(userResponse))
                        break;
                    else
                        tellUser(['Erroneous input: One or more of the ' ...
                            'integers entered was not valid.']);
                    end      
                else
                    if (~isa(userResponse, 'char') && ...
                            (~sum(acceptableInput==userResponse)==0))
                        break;
                    else
                        tellUser('Erroneous input: Please enter a valid integer.');
                    end
                end
            end
        end
    end
end

%%
function tellUser(message)
% tellUser(message)
%   Shorthand to print a message to the user with some convenient
%   line breaks.
%
% @param string message
% @return void
%
    fprintf(1,['\n' message '\n']);
end
