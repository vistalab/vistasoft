function val = viewGetSession(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'homedir'
        % Return full path to directory.
        %   homedir = viewGet(vw, 'Home Directory');
        val = HOMEDIR;
    case 'sessionname'
        % Retrun name of session, such as 'BW090616-8Bars-14deg'.
        %   sessionName = viewGet(vw, 'session name');
        val = mrSESSION.sessionCode;
    case 'subject'
        % Return name of subject, such as 'Wandell'
        %   subject = viewGet(vw, 'subject')
        val = mrSESSION.subject;
    case 'name'
        % Return name of view, such as 'INPLANE{1}'
        %    name = viewGet(vw, 'view name');
        val = vw.name;
    case 'annotation'
        % Return description of currently selected scan (string, such as
        % '14 Deg 8 Bars with blanks')
        %       annotation = viewGet(vw, 'annotation');
        if length(varargin) >= 1,   scan = varargin{1};
        else                        scan = viewGet(vw, 'CurScan'); end
        dt = viewGet(vw, 'DTStruct');
        val = dt.scanParams(scan).annotation;
    case 'annotations'
        % Return a cell array with descriptions of each scan in current
        % dataType
        %   annotations = viewGet(vw, 'annotations');
        dt  = viewGet(vw, 'DT Struct');
        val = {dt.scanParams.annotation};
    case 'viewtype'
        % Return the view type ('Gray', 'Volume', 'Inplane', 'Flat', etc)
        %   viewType = viewGet(vw, 'View Type');
        val = vw.viewType;
    case 'subdir'
        % Return the sub directory name (not the full path) with data for
        % current view
        %   subdir = viewGet(vw, 'sub directory');
        val = vw.subdir;
    case 'viewdir'
        % Return the complete path combination of homedir and subdir
        % Will then try to create them if not already created
        val = fullfile(viewGet(vw,'Home Directory'),viewGet(vw,'Sub Directory'));
        if ~exist(val,'dir')
            fprintf('Trying to make %s...',str);
            try
                [~, message] = mkdir(val);
            catch
                fprintf('Whoops, didn''t succed. Maybe a permissions problem?');
                fprintf('\n Message: %s',message);
            end
            fprintf('\n');
        end
    case 'curscan'
        % Return the currently selected scan number
        %   curscan = viewget(vw, 'Current Scan');
        if checkfields(vw,'curScan')
            val = vw.curScan;
        else
            if checkfields(vw,'ui','scan','sliderHandle')
                val = round(get(vw.ui.scan.sliderHandle,'value'));
            else
                % Sometimes there is no window interface (it is hidden).  Then, we have
                % to find another way to determine the current scan.  Here, we ask the
                % user.  It would be possible to store this information in the VIEW
                % structure.  But we don't.  Ugh.
                val = 1; ieReadNumber('Enter scan number');
            end
        end
        
        
    case 'curslice'
        % Return the current slice number. This is the actual slice number
        % if we are in the Inplane view. It is the plane number (sag, cor,
        % or axi) of the currently selected plane if we are in the Volume
        % view. And it is 1 or 2 in the Flat view (for left or right).
        %   curslice = viewGet(vw, 'Current Slice');
        if isequal(vw.name,'hidden')
            % no UI or slider -- use tSeries slice
            curSlice = vw.tSeriesSlice;
            if isnan(curSlice) | isempty(curSlice), val = 1; end
            return
        end
        switch vw.viewType
            case 'Inplane'
                val = vw.tSeriesSlice; % err on the side of not needing a UI
                if isnan(val) && checkfields(vw, 'ui', 'slice')
                    val = get(vw.ui.slice.sliderHandle,'val');
                end
            case {'Volume','Gray','generalGray'}
                sliceOri=getCurSliceOri(vw);
                val=str2double(get(vw.ui.sliceNumFields(sliceOri),'String'));
            case 'Flat'
                if isfield(vw,'numLevels') % test for levels view
                    % flat-levels view (older, but still supported)
                    val = getFlatLevelSlices(vw);
                    val = val(1);
                else
                    % regular flat view: slice is hemisphere, slice 3 means both
                    val = findSelectedButton(vw.ui.sliceButtons);
                end
        end
    case 'nscans'
        % Return the number of scans in the currently selected dataTYPE
        %   nscans = viewGet(vw, 'Number of Scans');
        if length(varargin) < 1, dataType = vw.curDataType;
        else dataType = varargin{1}; end
        if ischar(dataType)
            dataType = existDataType(dataType);
        end
        if dataType==0
            error('Invalid data type specified: %i', dataType);
        end
        val = length(dataTYPES(dataType).scanParams); %TODO: Use dtGet
    case 'nslices'
        % Return the number of slices in the current view struct
        %   nslices = viewGet(vw, 'Number of Slices');
        switch vw.viewType
            case 'Inplane'
                if ~checkfields(vw, 'anat'), vw = loadAnat(vw); end
                val = niftiGet(viewGet(vw,'Anatomy Nifti'),'num slices');
            case {'Volume' 'Gray'}
                val = 1;
            case 'Flat'
                if isfield(vw,'numLevels') % acr levels view
                    val = 2 + sum(vw.numLevels);
                else
                    val = 2;
                end
        end
    case 'montageslices'
        % Return the current subset of slices that are visible in the GUI.
        %   montageSlices = viewGet(vw, 'Montage Slices');
        %
        % only for some view types: inplane montage, flat level
        % Well, this seems not to be true since it returns a value in the
        % Volume view.
        val = viewGet(vw, 'Current Slice');
        if viewGet(vw, 'ishidden') || ~ismember(vw.refreshFn,...
                {'refreshMontageView' 'refreshFlatLevelView'})
            warning('vista:viewError', 'MontageSlices View does not apply to this view type');
            return  % return current slice
        end
        nSlices = get(vw.ui.montageSize.sliderHandle, 'Value');
        val = val:val+nSlices-1;
        val = val(val <= viewGet(vw, 'numSlices'));
        
    case 'dtname'
        % Return the name of the currently selected dataTYPE
        %   dtName = viewGet(vw, 'Data TYPE Name', [dtnum]);
        if ~isempty(varargin), dtnum = varargin{1};
        else dtnum =  viewGet(vw, 'curdt') ; end
        val = dataTYPES(dtnum).name;
    case 'curdt'
        % Return the number of the currently selected dataTYPE
        %   dtNum = viewGet(vw, 'Current Data TYPE');
        if isfield(vw, 'curDataType')
            val = vw.curDataType;
        else
            val = 0;
        end
    case 'dtstruct'
        % Return the currently selected dataTYPE struct
        %   dtStruct = viewGet(vw, 'DT struct');
        curdt = viewGet(vw, 'Current Data TYPE');
        val   = dataTYPES(curdt);
        
    case 'size'
    
        switch viewGet(vw,'View Type')
            case 'Inplane'
                val = viewGet(vw,'anatsize');
            case {'Volume','Gray','generalGray'}
                if isfield(vw, 'anat')
                    % In the GUI this field is populated so we get it
                    if ~isempty(vw.anat), val = viewGet(vw,'Anat Size'); end
                end
                % If it is a hidden volume view then this field is not
                % populated so we need to load the anatomy image in order
                % to calculate it's size
                if ~exist('val','var') || isempty(val)
                    pth = getVAnatomyPath; % assigns it if it's not set
                    % Here we load the volume anatomy - Note that we need
                    % to apply this transform between the dimensions of the
                    % raw image and the mrvista coordinates
                    val = size(readVolAnat(pth));
                    
                    % This was the original call but we note that the
                    % function nifti2mrVistaAnat applies a transform to the
                    % data that makes the data dimensions different from
                    % those in the header. 
                    % [~, val] = readVolAnatHeader(pth);
                end
            case 'Flat'
                val = [vw.ui.imSize,2];
        end
        
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
