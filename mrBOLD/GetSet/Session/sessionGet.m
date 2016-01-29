function val = sessionGet(s,param,varargin)
% Get values from a mrSESSION structure (mrVista)
%
%   val = sessionGet(s,param,varargin)
%
% This function along with sessionSet and sessionCreate should become the
% way we interact with the mrSESSION structure.  There is a long way to go
% to get these functions deeply inserted into the mrVista routines.
%
% For the new mrVista2 code, use sessGet/sessSet instead.
%
% See also: CreateNewSession (should become obsolete), sessionCreate,
% sessionSet, saveSession (should become obsolete), sessionSave (not yet
% written);
%
% Examples:
%   s = mrSESSION;
%   v = sessionGet(s,'functionals');
%   v = sessionGet(s,'alignment');
%
%%%%%%%%%%%%%%%%%%%%%%%%%
% Dump of mrSESSION example:
%
% mrLoadRetVersion: 3.0100
%                title: ''
%             subject: 'pn'
%              examNum: []
%             inplanes: [1x1 struct]
%          functionals: [1x10 struct]
%       screenSaveSize: [512 512]
%            alignment: [4x4 double]
%          sessionCode: 'sCode'
%          description: 'sDesc'
%

%TODO: Fix the comment above

if notDefined('s'), error('mrSESSION variable required'); end


if ischar(s)
    %This means that we are using the new functionality to list the
    %parameter set
    
    s = mrvParamFormat(s);
    
    %Check to see if we are asking for just one or all parameters:
    if ~exist('param','var'), sessionMapParameterField(s, 1);
    else sessionMapParameterField(s,1,mrvParamFormat(param));
    end
    %Using the new functionality
    return %early since we don't want to go through the rest
end %if

if notDefined('param'), error('Parameter field required.'); end

% make lower case and remove spaces
param = mrvParamFormat(param);

param = sessionMapParameterField(param);

val = [];
switch param
    case {'alignment'}
        if isfield(s,'alignment'), val = s.alignment;
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'description'}
        if isfield(s,'description'),val = s.description; end
        
    case {'eventdetrend'}
        if checkfields(s,'event','detrendFrames')
            val = s.event.detrendFrames;
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'examnum'}
        if isfield(s, 'examNum'), val = s.examNum; end
        
    case {'functionalinplanepath'}
        if checkfields(s, 'functionals','inplanePath')
            if isempty(varargin), val = s.functionals(:).inplanePath;
            else val = s.functionals(varargin{1}).inplanePath;
            end
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'functionalsslicedim'}
        if checkfields(s, 'functionals','cropSize')
            if isempty(varargin), error(['No scan dim defined when ',...
                    'attempting to get functional slice dimensions.']);
            else val = s.functionals(varargin{1}).cropSize;
            end
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'functionalvoxelsize'}
        if checkfields(s, 'functionals','voxelSize')
            if isempty(varargin), val = s.functionals(:).voxelSize;
            else val = s.functionals(varargin{1}).voxelSize;
            end
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'functionals'}
        % sessionGet(s,'functionals',3);  % Third scan parameters
        % sessionGet(s,'functionals');    % All
        if isfield(s, 'functionals')
            if isempty(varargin), val = s.functionals;
            else val = s.functionals(varargin{1});
            end
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'functionalorientation'}
        % orientation = sessionGet(s,'functional orientation'); 
        if isfield(s, 'functionals') && isfield(s.functionals, 'orientation')
            val = s.functionals(1).orientation;
        else
            % warning('Functional orientation has not been defined')
            val = [];
        end
            
    case {'inplane'}
        % pth = sessionGet(s, 'inplane path');
        % Return the structure of the inplanes data
        
        if isfield(s, 'inplanes'), val = s.inplanes;
        else error('The field relevant to %s was not found in the session.', param);
        end
        
        if isempty(val), warning('Inplane is returning empty'); end %#ok<WNTAG>
        
    case {'inplanepath'}
        % Return the path to the nifti for the
        % inplane anatomy (underlay for the functional data)
        % pth = sessionGet(s, 'inplane path');
        
        if ~isfield(s.inplanes,'inplanePath')
            %This session has not been updated. Let's warn the user
            error(sprintf(['No path has been specified or found in mrSESSION.\n', ...
                'You may need to migrate your session to accommodate code updates.\n', ...
                'Please migrate the session by typing mrInit_sessionMigration at\n', ...
                'the Matlab prompt, and then open your session.\n', ...
                'More information can be found here: http://white.stanford.edu/newlm/index.php/Initialization#Updating_old_sessions.\n']));
        end
        
        val = s.inplanes.inplanePath;
        
        if ~exist(val,'file')
            %We cannot find the file, let's ask the user to 'browse' for it
            warning('The file that has been specified in the inplane path does not exist. Please select a new file.');
            dlgTitle = 'Select inplane nifti to open...';
            [val,pthName] = uigetfile({'*.nii.gz', 'gzipped nifti (*.nii.gz)';'*.nii', 'nifti (*.nii)'},dlgTitle);
            if isempty(val), error('Inplane path not found'); end
            val = fullfile(pthName,val);
            
            % We need to also ensure that we save down this new path to the
            % session:
            mrGlobals;
            loadSession;
            
            mrSESSION = sessionSet(mrSESSION,'Inplane Path', val);
            saveSession;
        end
        
    case {'interframetiming'}
        % This is the proportion of a TR that separates each frame
        % acquisition. This is NOT a real number in seconds.
        % sessionGet(mrSESSION,'interframedelta',2)
        
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        % When we use multiple shots, the ordering is
        % [1a 2a 3a ... 1b 2b 3b ...] where a and b are two shots.
        % So the effective spacing between the acquisition times for slice
        % 1 and 2 is reduced by the number of shots.
        val = 1 / sessionGet(s,'nslices',scan) / sessionGet(s,'nShots',scan);
        
    case {'nsamples'}
        % sessionGet(mrSESSION,'nframes',2)
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        if checkfields(s.functionals(scan),'nFrames')
            val = s.functionals(scan).nFrames;
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'nshots'}
        % sessionGet(mrSESSION,'nShots',2)
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        if checkfields(s.functionals(scan),'reconParams','nshots')
            val = s.functionals(scan).reconParams.nshots;
        else
            val = 1; % NOTE: this means that we are defaulting to a specific
            % value if the field does not exist. This can be dangerous
            % as it may introduce bugs. Do we want to change this?
        end
        
    case {'nslices'}
        % I don't understand slquant and slices.  Older mrSESSION files
        % don't have slquant.  Newer ones appear to use it to get the
        % number of slices.  Ask for an explanation, then put it here.
        % sessionGet(mrSESSION,'nSlices')
        % sessionGet(mrSESSION,'nSlices',2)
        if isempty(varargin), scan = 1;
        else scan = varargin{1};
        end
        if checkfields(s.functionals(scan),'reconParams','slquant')
            val = s.functionals(scan).reconParams.slquant;
        elseif checkfields(s.functionals(scan),'slices')
            % I don't understand slquant and this ... we should use one but
            % not the other.  Which one?
            val = length(s.functionals(scan).slices);
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'pfilelist'}
        % Return indices into the functional scans corresponding to the
        % cell array of pFile names
        % sessionGet(s,'pFileList',{'name1','pFile2.mag'})
        if isempty(varargin), error('PFile names required');  end
        allPFiles = sessionGet(s,'pFileNames');
        pFiles = varargin{1};
        val = cell(1, length(varargin));
        for ii=1:length(varargin)
            val(ii) = cellfind(allPFiles,pFiles{ii});
        end
        
    case {'pfilenames'}
        nScans = length(s.functionals);
        val = cell(1, nScans);
        for ii=1:nScans
            if checkfields(s.functionals(ii),'PfileName')
                val{ii} = s.functionals(ii).PfileName;
            else error('The field relevant to %s was not found in the session.', param);
            end %if
        end %for
        
    case {'refslice'}
        % sessionGet(mrSESSION,'refslice',2)
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        if checkfields(s.functionals(scan),'slices')
            l   = s.functionals(scan).slices;
            val = mean(l);
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'screensavesize'}
        if isfield(s, 'screenSaveSize'), val = s.screenSaveSize; 
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'sessioncode'}
        if isfield(s,'sessionCode'),  val = s.sessionCode; 
        else error('The field relevant to %s was not found in the session.', param);
        end;
        
    case {'sliceorder'}
        if isempty(varargin), scan = 1;
        else scan = varargin{1};
        end
        if checkfields(s.functionals(scan),'sliceOrder')
            val = s.functionals(scan).sliceOrder;
        else
            val = [];
        end
        
    case {'subject'}
        if isfield(s, 'subject'), val = s.subject; 
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'title'}
        if isfield(s, 'title'), val = s.title; 
        else error('The field relevant to %s was not found in the session.', param);
        end
        
    case {'tr'}
        % sessionGet(mrSESSION,'TR',2)
        if isempty(varargin), scan = 1;
        else                  scan = varargin{1};
        end
        if isfield(s.functionals(scan),'framePeriod')
            val = s.functionals(scan).framePeriod;
        else error('The field relevant to %s was not found in the session.', param);
        end
        % Time series processing parameters for block and event analyses

    case {'version'}
        if isfield(s, 'mrVistaVersion'), val = s.mrVistaVersion; 
        else val = 0;
        end
        
    otherwise
        error('Unknown parameter %s',param);
        
end
return;
