classdef TimeSeriesData < handle
    % TimeSeriesData
    %   Encapsulates time series data.  List methods available for public
    %   use by creating an object and using the help method by typing 
    %   MyObjectName.help().
    %
    %   Usage:
    %       Construct with ROI and session path in one line:
    %           MyObjectName = TimeSeriesData(sessionPath, ROIPath);
    %       Construct empty object and load session and ROI:
    %           MyObjectName = TimeSeriesData();
    %           MyObjectName.loadSession(sessionPath);
    %           MyObjectName.loadROI(ROIPath);
    %
    % renobowen@gmail.com [2010]
    %
    
    properties (GetAccess = public, SetAccess = private)
        sessionPath
        selectedROIName
        analysis
        data
        dataTypes
        inplane
        methodNames
        loadedROIPaths
        loadedROINames
        selectedROIIndex
    end
    
    properties (GetAccess = public, SetAccess = private, Hidden)

    end
    
    properties (GetAccess = public, Constant)
        % ROI Directory titles

    end
    
    properties (GetAccess = private, Constant, Hidden)
        DEFAULT_DATATYPE = 'MotionComp';
        IN_CANCEL = 0;
        IN_OVERWRITE = -1;
        IN_SELECT = 1;
        ROI_DIRS = {'Inplane' 'Gray' 'Volume' '3dAnatomy'};
        INPLANE_ROI = '/Inplane/ROIs/'
    end
    
    methods (Access = public)
        %%
        function obj = TimeSeriesData(sessionPath, ROIPath)
        % TimeSeriesData(sessionPath, ROIPath)
        %   Object constructor with optional args for choosing a session/ROI.
        %
        % @param string sessionPath
        % @param string ROIPath
        % @return void
        %
            obj.storeMethodsList(); % Store list of methods for use in help method
            if (~exist('sessionPath','var')), sessionPath = []; ROIPath = []; end
            if (~exist('ROIPath','var')), ROIPath = []; end
            
            if (obj.loadSession(sessionPath))
                obj.loadROI(ROIPath);
            else
                tellUser('Empty object initialized.');
            end

        end
        
        %%
        function bool = loadSession(obj, sessionPath)
        % bool = loadSession(sessionPath)
        %   Load a subject's data into the object.
        % 
        % @param string sessionPath
        % @return bool bool
        %
            % If no sessionPath given or it's empty, prompt user
            if (~exist('sessionPath','var') || isempty(sessionPath))
                [sessionPath] = uigetdir('', 'Select Session Path');
                if (sessionPath == 0), bool = false; return; end
            end
            
            if (~isempty(obj.sessionPath))
                    userMessage = sprintf(['\nA session has already been loaded:\n' ...
                        '%s\n\nReturn %d to cancel or %d to overwrite: '], ...
                        obj.sessionPath, obj.IN_CANCEL, obj.IN_OVERWRITE);
                    isOkToOverwrite = obj.promptUser(userMessage, ...
                        [obj.IN_CANCEL obj.IN_OVERWRITE]);
                
                if (isOkToOverwrite == obj.IN_CANCEL), bool = false; return; end
            end
            
            currentPath = pwd;
            cd(sessionPath);
            
            obj.resetFields('except','methodNames'); % keep this field - used in help method

            try
                obj.inplane = initHiddenInplane();
            catch
                cd(currentPath);
                tellUser('Failed to load inplane.');
                bool = false;
                return;
            end
            
            obj.loadDataTypes(); % load data types available in inplane
            obj.setDataType(obj.DEFAULT_DATATYPE); % set the data type to default (or attempt to)
            obj.sessionPath = sessionPath;
            bool = true;
            cd(currentPath);
        end
        
        %%
        function isROILoaded = loadROI(obj, ROIPath)
        % isROILoaded = loadROI(ROIPath)
        %   Loads an ROI from a path.  Lots of checks in place to ensure you
        %   don't overwrite other ROIs, load them without sessions, etc.
        %   Returns a bool reporting success or failure to load an ROI.
        %
        %   Run with no args to init a UI for selecting the file, run with
        %   arg 'local' to init a UI for specifically loading ROIs in the
        %   local path.
        %
        % @param string|cellarray<string> ROIPath
        % @return bool isROILoaded
        %
            
            if (isempty(obj.sessionPath))
                isROILoaded = false;
                tellUser('Cannot load ROI: No session loaded.');
                return;
            end
            
            if (~exist('ROIPath','var') || isempty(ROIPath))
                LOCAL = 'Local List';
                BROWSER = 'Full Browser';
                response = questdlg('Select with', 'Load ROI', LOCAL, BROWSER, LOCAL);
                switch (response)
                    case BROWSER
                        ROIPath = obj.browserSelectROI();
                    case LOCAL
                        ROIPath = obj.localSelectROI();
                end
                if (isempty(ROIPath)), isROILoaded = false; return; end
            end
            
            index = cellfind(obj.loadedROIPaths, ROIPath);
            if (~isempty(index))
                isROILoaded = false;
                tellUser(['Cannot load ROI (already exists):\n' ROIPath]);
                return;
            end
            
            ROIPath = obj.prepareROIForLoad(ROIPath);
            if (isempty(ROIPath)), isROILoaded = false; return; end

            [obj.inplane isROILoaded] = loadROI(obj.inplane, ROIPath, 1, [], 1);

            if (isROILoaded)
                ROIIndex = obj.inplane.selectedROI;
                obj.loadedROIPaths{ROIIndex} = ROIPath;
                obj.setROIName(ROIIndex, obj.inplane.ROIs(ROIIndex).name);

                if length(obj.loadedROINames) == 1
                    obj.setSelectedROI(ROIIndex);
                end
            else
                tellUser(['Cannot load ROI (error external to TimeSeriesData):\n' ROIPath]);
                return;
            end
        end
        
        %%
        function setROI(obj, ROIName)
        % setROI(ROIName)
        %   Selects an already-loaded ROI with a string input.
        %
        % @param string ROIName
        % @return void
        % 
            if (~exist('ROIName','var'))
                ROIName = [];
            end
            
            index = obj.selectROI(ROIName);
            
            if (isempty(index)), return; end
            
            obj.setSelectedROI(index);
        end
        
        %%
        function setDataType(obj, dataType)
        % setDataType(dataType)
        %   Attempts to set data type to the given string, prompting user to
        %   try again should it fail.
        %
        % @param string dataType
        % @return void
        %
            if (isempty(obj.dataTypes))
                tellUser('No data types to select from!  Load a session first.');
                return;
            end
            
            ind = [];
            
            if (exist('dataType','var'))
                ind = cellfind(lower(obj.dataTypes), lower(dataType));
                if (isempty(ind))
                    tellUser('No such data type!  Please select one from the menu.');
                end
            end
            
            if (isempty(ind))
                ind = listdlg('PromptString', 'Select a data type:', ...
                    'SelectionMode', 'single', ...
                    'ListString', obj.dataTypes);             
                if (isempty(ind))
                    tellUser('Couldn''t set data type.');
                    return;
                end
            end

            obj.inplane.curDataType = ind;
        end
        
        %%
        function renameROI(obj, ROIName)
        % renameROI(ROIName)
        %   Rename indicated ROI via a user prompt.
        %
        % @param string ROIName
        % @return void
        %
            if (~exist('ROIName','var'))
                ROIName = [];
            end
            
            index = obj.selectROI(ROIName);

            if (isempty(index)), return; end
            
            newROIName = obj.promptUser(sprintf('\nRename %s to: ', obj.loadedROINames{index}),'string');
            obj.setROIName(index, newROIName);
        end
            
        %%
        function removeROI(obj, ROIName)
        % removeROI(ROIName)
        %   Unload an ROI from object storage.
        %
        % @param string ROIName
        % @return void
        %
            if (~exist('ROIName','var'))
                ROIName = [];
            end
            
            index = obj.selectROI(ROIName);

            if (isempty(index)), return; end
            
            userMessage = sprintf(['You are about to unload the following ROI:\n'...
                '%s' '\t\t-\t' '%s' '\n'...
                'Return %d to cancel, or %d to confirm: '], ...
                obj.loadedROINames{index}, obj.loadedROIPaths{index}, ...
                obj.IN_CANCEL, obj.IN_SELECT);
            isOkToUnload = obj.promptUser(userMessage, ...
                [obj.IN_CANCEL obj.IN_SELECT]);
            if (isOkToUnload == obj.IN_SELECT)
                obj.unloadROI(index);
                if (obj.selectedROIIndex == index)
                    if (length(obj.inplane.ROIs) < 1)
                        obj.setSelectedROI([]);
                        fprintf(1,'No ROIs available following unload.  Please load one.\n\n');
                    else
                        obj.setSelectedROI(1);
                        fprintf(1,['Unloaded selected ROI.  Defaulting to ' ...
                            obj.loadedROINames{1} '\n\n']);
                    end
                end
            else
                fprintf(1,'Cancelling unload of ROI.\n\n');
            end
        end
        
        %%
        function display(obj)
            fprintf(1, '    Session Path:\n');
            if (~isempty(obj.sessionPath))
                fprintf(1,'        %s',obj.sessionPath);
            else
                fprintf(1,'        NONE');
            end
            fprintf(1,'\n\n');
            
            fprintf(1, '    Selected ROI:\n');
            if (~isempty(obj.selectedROIIndex))
                fprintf(1,'        %s (%s)', ...
                    obj.loadedROINames{obj.selectedROIIndex}, ...
                    obj.loadedROIPaths{obj.selectedROIIndex});
            else
                fprintf(1,'        NONE');
            end
            fprintf(1,'\n\n');
            
            fprintf(1,'    Available Methods:\n');
            fprintf(1,'        %s\n',obj.methodNames{:});    
        end
        
        %%
        function getLoadedROIs(obj)
        % listLoadedROIs()
        %   Print a list of loaded ROIs and their paths to console.
        %
        % @return void
        %
            fprintf(1, 'Loaded ROIs:\n');
            if (~isempty(obj.loadedROINames))
                for i = 1:length(obj.loadedROINames)
                    fprintf(1,'%s\t - %s\n', ...
                    obj.loadedROINames{i}, ...
                    obj.loadedROIPaths{i});
                end
            else
                fprintf(1,'NONE\n')
            end
            fprintf(1, '\n');
        end
        
        %%
        function loadTimeCourses(obj)
        % loadTimeCourses()
        %   Load time course data.
        %
        % @return void
        %
            obj.computeTimeCourses(obj.selectedROIIndex);
        end

        %%
        function getLocalROIs(obj)
        % listLocalROIs()
        %   Print a list of locally available ROIs to console.
        % 
        % @return void
        %
            obj.listROIsInPath([obj.sessionPath obj.INPLANE_ROI]);
            obj.listROIsInPath([obj.sessionPath obj.GRAY_ROI]);
            obj.listROIsInPath([obj.sessionPath obj.VOLUME_ROI]);
            obj.listROIsInPath([obj.sessionPath obj.ANAT3D_ROI]);
        end
        
        %%
        function clonedObject = clone(obj)
        % clonedObject = clone()
        %   Generate a deep copy of the object.
        % 
        % @return TimeSeriesData clonedObject
        %
            clonedObject = TimeSeriesData();
            classInfo = metaclass(obj);
            nProperties = length(classInfo.Properties);
            for i = 1:nProperties
                if (~classInfo.Properties{i}.Constant)
                    name = classInfo.Properties{i}.Name;
                    clonedObject.(name) = obj.(name);
                end
            end
        end
        
        %%
        function help(obj, method)
        % help()
        %   Access with no arguments to display list of available public
        %   methods.  Pass the method name into the function as a string to
        %   display the help text associated with it.
        %
        %   Usage:
        %       List all public methods:
        %           MyObjectName.help();
        %       Display help text on method loadROI:
        %           MyObjectName.help('loadROI');
        %
        % @return void
        %
        
            if (~exist('method','var'))
                help TimeSeriesData\help
            else
                eval(sprintf('help TimeSeriesData/%s',method));
            end
        end
        
    end
    
    methods (Access = private)
        %%
        function index = selectROI(obj, ROIName)
        % index = selectROI(ROIName)
        %   Function to take an ROIName (or empty string) and check if its
        %   valid, and if it's not present a prompt to allow them to select
        %   it from a list.
        %
        % @param string ROIName
        % @return int index
            if (isempty(obj.loadedROINames))
                tellUser('No ROIs to select from!  Load an ROI first.');
                index = [];
                return;
            end
            
            if (~isempty(ROIName))
                index = cellfind(obj.loadedROINames, ROIName);
                if (isempty(index))
                    tellUser('No such loaded ROI!  Please select one from the menu.');
                end
            else
                index = listdlg('PromptString', 'Select a loaded ROI:', ...
                    'SelectionMode', 'single', ...
                    'ListString', obj.loadedROINames);     
            end
        end
        
        %%
        function storeMethodsList(obj)
        % storeMethodsList()
        %   Store list of available public methods to a private cell array.
        %
        % @return void
        %
            meta = metaclass(obj);
            obj.methodNames = cell(length(meta.Methods),1);
            for i = 1:length(meta.Methods)
                if (strcmp(meta.Methods{i}.DefiningClass.Name,'TimeSeriesData'))
                    if (strcmp(meta.Methods{i}.Access,'public') && ~meta.Methods{i}.Hidden)
                        obj.methodNames{i} = meta.Methods{i}.Name;
                    end
                end
            end
            obj.methodNames = sort(obj.methodNames(cellfind(obj.methodNames)));
        end
        
        %%
        function resetFields(obj, varargin)
        % resetFields(varargin)
        %   Iterates over all non-constant fields and clears them, sparing
        %   those fields specified as strings in varargin.
        %
        %   Usage:
        %       resetFields(); - Resets all fields
        %       resetFields('except','field1','field2'); - Reset all fields
        %               EXCEPT field1 & field2
        %       resetFields('field1','field2'); - Reset only field1 & field2
        %
        % @param cellarray varargin 
        % @return void
        %
            if (isempty(varargin) || strcmpi(varargin{1},'except'))
                classInfo = metaclass(obj);
                except = (~isempty(varargin));
                nProperties = length(classInfo.Properties);
                
                for i = 1:nProperties
                    if (~classInfo.Properties{i}.Constant)
                        if (except)
                            if (isempty(cellfind(varargin, classInfo.Properties{i}.Name)))
                                obj.(classInfo.Properties{i}.Name) = [];
                            end
                        else
                            obj.(classInfo.Properties{i}.Name) = [];
                        end
                            
                    end
                end
            else
                nArgs = length(varargin);
                
                for i = 1:nArgs
                    try
                        obj.(varargin{i}) = [];
                    catch
                        fprintf(1,['\nresetFields: No field ''' varargin{i} ''' found.\n']);
                    end
                end
            end
                    
        end
        
        %%
        function loadDataTypes(obj)
        % loadDataTypes()
        %   Retrieve dataTYPES global and stores into dataTypes field.
        %
        % @return void
        %
            global dataTYPES;
            nDataTypes = length(dataTYPES);
            obj.dataTypes = cell(nDataTypes,1);
            for i = 1:length(dataTYPES)
                obj.dataTypes{i} = dataTYPES(i).name;
            end
        end
        
        %%
        function ROIPath = convertToInplane(obj, ROIFile, ROIPath)
        % ROIPath = convertToInplane(ROIFile, ROIPath)
        %   Given a loaded ROI file and an output path, convert/resave an
        %   ROI to inplane format.  Returns the final path.
        %
        % @param struct ROIFile
        % @param string ROIPath
        % @return string ROIPath
        %
            currentDir = pwd;
            cd(obj.sessionPath);
            volume = initHiddenVolume(cellfind(obj.dataTypes,obj.DEFAULT_DATATYPE)); % PROBABLY NEED TO CHANGE DATA TYPE SELECTION PROCEDURE
            ROI = vol2ipROI(ROIFile.ROI, volume, obj.inplane); %#ok<*NASGU>
            cd(currentDir);
            
            delimiters = findstr(ROIPath,'/');
            filename = ROIPath((delimiters(end) + 1):end);

            if (~exist([obj.sessionPath obj.INPLANE_ROI],'dir'))
                mkdir([obj.sessionPath obj.INPLANE_ROI]);
            end
            
            while (exist([obj.sessionPath obj.INPLANE_ROI filename],'file'))
                filename = obj.promptUser(sprintf(['\nAn ROI already possesses the '...
                    'filename: ' filename '\nPlease choose another name: ']), ...
                    'string');
                if (isempty(strfind(filename, '.mat')))
                    filename = [filename '.mat'];
                end
            end
            
            ROIPath = [obj.sessionPath obj.INPLANE_ROI filename];
            save(ROIPath,'ROI');
            tellUser(['ROI converted and saved successfully:\n' ROIPath ]);
        end
        
        %%
        function computeTimeCourses(obj, index)
        % computeTimeCourses(index)
        %   Compute and format time courses for a given ROI index.
        %
        % @param int index
        % @return void
        %
            obj.data = er_voxelData(obj.inplane,obj.inplane.ROIs(index));
            obj.analysis = er_chopTSeries2(obj.data.tSeries,...
                obj.data.trials, obj.data.params);
        end
        
        %%
        function setROIName(obj, index, newROIName)
        % setROIName(obj, index, newROIName)
        %   Set the name for an ROI at an index.
        %
        % @param int index
        % @param string newROIName
        % @return void
        %
            while (~isempty(cellfind(obj.loadedROINames,newROIName)))
                newROIName = obj.promptUser(sprintf(['\nAn ROI already possesses the '...
                    'name: ' newROIName '\nPlease choose another name: ']), ...
                    'string');

            end
            obj.loadedROINames{index} = newROIName;
        end
        
        %%
        function setSelectedROI(obj, index)
        % setSelectedROI(index)
        %   Set the selected ROI given an index.
        %
        % @param int index
        % @return void
        %
            if (obj.selectedROIIndex == index)
               tellUser('You''ve already selected this ROI!');
               return;
            end
            obj.resetFields('data','analysis');
            obj.selectedROIIndex = index;
            obj.selectedROIName = obj.loadedROINames{index};
        end
        
        %%
        function unloadROI(obj, index)
        % removeROI(index)
        %   Remove an ROI as well as any traces it might leave in fields.
        %
        % @param int index
        % @return void
        %
            obj.inplane.ROIs(index) = [];
            obj.data = obj.data([1:(index - 1) (index + 1):end]);
            obj.analysis = obj.analysis([1:(index - 1) (index + 1):end]);
            obj.loadedROIPaths = obj.loadedROIPaths([1:(index - 1) (index + 1):end]);
            obj.loadedROINames = obj.loadedROINames([1:(index - 1) (index + 1):end]);
        end
        
        %%
        function ROIPath = browserSelectROI(obj)
        % ROIPath = browserSelectROI()
        %   Brings up GUI dialogs to assist in selecting an ROI from a
        %   standard file system browser.  Returns an empty string if none
        %   selected.
        %
        % @return string ROIPath
        %
            ROIPath = [];
            [name, filepath] = uigetfile(obj.sessionPath, 'Select ROI');
            if (isequal(name, 0) || isequal(path, 0)), return; end
            ROIPath = [filepath name];
        end
        
        %%
        function ROIPath = localSelectROI(obj)
        % ROIPath = localSelectROI()
        %   Brings up GUI dialogs to assist in selecting an ROI from the
        %   local default directories.  Returns an empty string if none
        %   selected.
        %
        % @return string ROIPath
        %
            ROIPath = [];
            % Process all local ROIs
            localROIs = cell(1,length(obj.ROI_DIRS));
            for i = 1:length(obj.ROI_DIRS)
                localROIs{i} = obj.getROIsInPath([obj.sessionPath '/' obj.ROI_DIRS{i} '/ROIs']);
            end

            % If there aren't any local ROIs, return
            if (isempty(cellfind(localROIs)))
                tellUser('No local ROIs present.');
                return;
            end

            % Otherwise, prompt for what local directories they'd like
            % to select from
            DIRS = cellfind(localROIs);
            dirIndex = listdlg('PromptString', 'Select location(s):', ...
                        'SelectionMode', 'single', ...
                        'ListString', obj.ROI_DIRS(cellfind(localROIs)));

            % If no selection made, return
            if (isempty(dirIndex)), return; end

            % Generate list to populate selection dialog
            dirIndex = DIRS(dirIndex);
            ROIList = localROIs{dirIndex};

            % Prompt for which ROIs they'd like to load
            ROIIndex = listdlg('PromptString', 'Select ROI(s)', ...
                'SelectionMode', 'single', ...
                'ListString', ROIList);

            % If no selection made, return
            if (isempty(ROIIndex)), return; end

            % Generate paths given the local path names they selected
            ROIPath = [obj.sessionPath '/' obj.ROI_DIRS{dirIndex} '/ROIs/' ROIList{ROIIndex} '.mat'];
        end
        
        %%
        function [ROIPath] = prepareROIForLoad(obj, ROIPath)
        % ROIPath = prepareROIForLoad(ROIPath)
        %   Takes an ROIPath and performs a thorough series of checks and
        %   conversions to ensure the returned path is a safe to load
        %   inplane file.  Returns an empty string if it fails.
        %
        % @param string ROIPath
        % @return string ROIPath
        %
            ROIFile = load(ROIPath);
            if (isfield(ROIFile,'ROI'))
                if (isfield(ROIFile.ROI,'viewType'))
                    if (~strcmpi(ROIFile.ROI.viewType,'Inplane'))
                        userMessage = sprintf(['\nROI is not in Inplane format :\n' ...
                            '%s\n\nReturn %d to convert a copy or %d to cancel load: '], ...
                            ROIPath, obj.IN_SELECT, obj.IN_CANCEL);
                        response = obj.promptUser(userMessage, ...
                            [obj.IN_SELECT obj.IN_CANCEL]);

                        if (response == obj.IN_CANCEL), ROIPath = []; return; end

                        ROIPath = obj.convertToInplane(ROIFile, ROIPath);
                    end
                else
                    tellUser(['Cannot load ROI (it doesn''t have a viewType field):\n' ROIPath]);
                    ROIPath = [];
                    return;
                end
            else
                tellUser(['Cannot load ROI (it''s not an ROI):\n' ROIPath]);
                ROIPath = [];
                return;
            end
        end
    end
    
    methods (Hidden, Static)
        %%
        function ROIs = getROIsInPath(path)
        % listROIsInPath(path)
        %   Returns a list of ROIs available in the path in cell array
        %   format.
        %
        % @param string path
        % @return cellarray<string> ROIs
        %
            ROIs = [];
            if ~exist(path, 'dir'), return; end
            
            fileList = dir(path);
            nFiles = length(fileList);
            ROIs = cell(nFiles,1);
            
            for i = 1:nFiles;
                curFile = fileList(i).name;
                if (strfind(lower(curFile),'.mat'))
                    if (curFile(1) ~= '.')
                        temp = load([path '/' curFile]);
                        if (isfield(temp,'ROI'))
                            ROIs{i} = curFile(1:(end - 4));
                        end
                    end
                end
            end
            ROIs = ROIs(cellfind(ROIs));
        end
        
        %%
        function string = cellsToString(cells)
        % string = cellsToString(cells)
        %   Convert a cell array into a formatted string where rows are rows,
        %   and columns are tab separated.
        %
        % @param cellarray<string> cells
        % @return string string
        %
            string = '';
            [nRows nCols] = size(cells);
            for i = 1:nRows
                for j = 1:nCols
                    string = [string '\t' cells{i,j}]; %#ok<*AGROW>
                end
                string = [string '\n']; %#ok<AGROW>
            end
        end
                  
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
