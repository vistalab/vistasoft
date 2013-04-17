function M = rmEditStimulusParameters(view,update,hrfFlag)
% Edit and store stimulus and analysis parameters 
%
%   params = rmEditStimulusParameters(getCurView);
%
% The parameters are returned in the parameter M
%
% 2007/05 SOD: wrote it.
% 2007/06 RAS: small updates in the GUI.
% 2007/07 RAS: craziness involving global variables. Having this function
% return the view struct always broke the updating of the view's RM
% params. 
% 
% The refresh function updates the view by 
% running rmLoadParameters. But then the local 'view' variable returned
% by the main function overwrites the updated view, undoing what was done.
% After spending more time trying to fix this than it was worth, I realized
% that the current implementation of mrVista, plus using uiresume, simply
% don't cooperate. I used the 'updateGlobal' (hack) function to solve the
% dilemna (ras).
%
% It appears that this funciton is used in two ways.  First, it is used to
% create the window for the retinotopy model parameters and fill them with
% values.  These values are derived from the view.
%
% Once the window is created this same function is called to refresh the
% window after there is a change in the values.  It is called as a create
% or refresh window depending on the update flag.
%
% This causes a lot of trouble.
%
if notDefined('view'),    error('Need view struct');       end;
if notDefined('update'),  update  = false;                  end;
if notDefined('hrfFlag'), hrfFlag = false;                  end;
if update
    % Function called in update mode.
    rmEditStimulusParameters_update(view, [], hrfFlag); 
    return; 
end;

% If we are here, the function was called in window-create mode.
% TO create the window SOD/RAS built in a stimulus field definition for the
% stimulus parameters of the retinotopy model.  The field here could become
% out of sync with the definitions of the fields in dataTYPES and the
% retinotopy model structure.  If the definition here is the main, true,
% only one definition everyone should use then we should pull it out into a
% rmStimCreate() return that is the one place everyone calls to go an make
% the structure with the stimulus slot.
%---
% % stimulus params
% % add new ones here
% %    fieldName,         regular name,                                     editable, defaultValue
% stimulusFields = { ...
%     'stimType',        'Stimulus type',                                true,   1; ...
%     'stimSize',        'stimulus radius (deg)',                        true,   14; ...
%     'stimWidth',       'Stimulus width (deg)',                         true,   45; ...
%     'stimStart',       'Stimulus starting phase (deg)',                true,   0; ...
%     'stimDir',         'Stimulus direction (boolean)',                 true,   0; ...
%     'nCycles',         'Stimulus cycles (#)',                          true,   6; ...
%     'nStimOnOff',      'Mean-luminance blocks (#)',                    true,   0; ...
%     'nUniqueRep',      'Stimulus repetitions (#)',                     true,   1; ...
%     'prescanDuration', 'Removed time frames with stimuli (#)',         true,   8; ...
%     'nDCT',            'DCT frequency max for detrending (#)',         true,   0; ...
%     'hrfType',         'HRF type',                                     true,   1;...
%     'hrfParams',       'HRF parameters',                               true,   '';...
%     'framePeriod',     'Frame interval (sec)',                         false,   '';...
%     'nFrames',         'Time frames (#)',                              false,   '';...
% 	'flipLR',		   'Flip Stimuli Left/Right',					   true,	0;...
% 	'imFile',          'Image File (Stimuli/*image*.mat)',             true,    1;...
%     'paramsFile',      'Params File (Stimuli/*param*.mat)',            true,   1;...  
%     'imFilter',         'Image filter'                                 true,   1;...
%     };
% % initiate struct
% M = rmInitStimStruct(view, stimulusFields);

[M, stimulusFields] = rmStimCreate;

%--- now create the GUI
M = rmEditStimulus_GUI(M, view, stimulusFields);

% initialize the GUI graphics by performing an update:
rmEditStimulusParameters_update(view);

% now do the uiwait and let the user deal w/ the interface:
uiwait;

return;
%-------------------------------------------------------------


%-------------------------------------------------------------
function M = rmEditStimulus_GUI(M, view, stimulusFields)
% Create the Edit Stimulus GUI based on the M model
% structure and the view.

% *** STUPID GUM BECAUSE GLOBAL VARIABLES ARE RETARDED ***
% So, after an hour of messing around with the code, getting it
% to properly generate the new RM params if the 'OK' button is
% pressed, I realize there is no way to do this without relying on
% some global or persistent variable. This has to do with 
% a the 'uiresume' not returning any components, as well as the
% fact that after getting uiresume, this function updates based on
% the old local variable 'view' handed into it, with no reliable
% way for the code to grab the updated version of the view. Having
% the update function return the view doesn't work. So, here's an
% ugly hack:    (ras, 07/08/07):
persistent STATUS
STATUS = 0;

M.fig = figure('Name', 'Define stimulus parameters');%, 'Color', [.9 .9 .9]);
M.pan  = uipanel('BorderType','none');
centerfig(M.fig, 0);
M.sF  = stimulusFields;

% make slider
callback = ['rmEditStimulusParameters(',view.name,',true);'];
M.ui.nScans = mrvSlider([.1 .9 .5 .08], 'Scan number', 'Parent', M.fig, ...
    'Range', [1 M.nScans], 'IntFlag', 1, 'Value', 1, ...
    'MaxLabelFlag', M.nScans, ...
    'Callback', callback);

% make
stepsize = linspace(0,0.85,size(stimulusFields,1)+2);
% stimulus type
% others
for n=1:size(M.sF,1),
    M.ui.([M.sF{n,1} 'text']) = uicontrol('Parent', M.pan, 'Style', 'text', ...
        'Units', 'norm', 'Position', [.1 .9-stepsize(n+1) .4 .06], ...
        'FontSize', 10, 'Horizontalalignment', 'left', ...
        'BackgroundColor', get(M.fig, 'Color'), ...
        'FontWeight', 'normal', 'String', M.sF{n,2});
    if M.sF{n,3},
        switch M.sF{n,1},
			case 'annotation'
				M.ui.(M.sF{n,1}) = uicontrol('Parent', M.fig, 'Style', 'text', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'bold', 'String', annotation, 'Callback', callback,...
                    'Value', M.stim(M.curScan).stimType);

            case 'stimType'
                stimDir   = fullfile(fileparts(which(mfilename)), 'StimulusDefinitions');
                stimFiles  = dir(fullfile(stimDir, 'make*.m'));
                myString  = {stimFiles.name};
                for ii=1:numel(myString),
                    myString{ii} = myString{ii}(numel('make')+1:end-numel('.m'));
                end
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', callback,...
                    'Value', M.stim(M.curScan).stimType);

            case 'stimDir'
                hrfcallback = ['rmEditStimulusParameters(',view.name,',true,true);'];

                myString = {'counterclockwise or out', 'clockwise or in'};
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', hrfcallback,...
                    'Value', M.stim(M.curScan).stimDir+1);
                
            case 'hrfType'
                hrfcallback = ['rmEditStimulusParameters(',view.name,',true,true);'];

                myString = {'one gamma (Boynton style)','two gammas (SPM style)'};
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', hrfcallback,...
                    'Value', M.stim(M.curScan).hrfType);
                
            case 'flipLR'
				M.ui.(M.sF{n,1}) = uicontrol('Parent', M.fig, 'Style', 'checkbox', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', 'Apply Flip', 'Callback', callback,...
                    'Value', M.stim(M.curScan).flipLR);
				
            case 'imFile'
                stimDir   = 'Stimuli';
                stimFiles  = dir(fullfile(stimDir, '*image*.mat'));
                myString  = {'none', stimFiles.name};
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', callback,...
                    'Value', M.stim(M.curScan).imFile);

            case 'paramsFile'
                stimDir   = 'Stimuli';
                stimFiles  = dir(fullfile(stimDir, '*param*.mat'));
                myString  = {'none', stimFiles.name};
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', callback,...
                    'Value', M.stim(M.curScan).paramsFile);

            case 'imFilter'               
                filterDir = fullfile(fileparts(which(mfilename)), 'FilterDefinitions');
                filterFiles  = dir(fullfile(filterDir, 'rmfilter_*.m'));
                myString  = {filterFiles.name};
                for ii=1:numel(myString),
                    myString{ii} = myString{ii}(numel('rmfilter_')+1:end-numel('.m'));
                end
                myString  = ['none' myString];
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'popup', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', myString, 'Callback', callback,...
                    'Value', M.stim(M.curScan).imFilter);

            otherwise,
                M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'edit', ...
                    'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
                    'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
                    'FontWeight', 'normal', 'String', '', 'Callback', callback);
        end
    else
        M.ui.(M.sF{n,1}) = uicontrol('Parent', M.pan, 'Style', 'text', ...
            'Units', 'norm', 'Position', [.5 .9-stepsize(n+1) .4 .06], ...
            'FontSize', 10, 'BackgroundColor', get(M.fig, 'Color'), ...
            'FontWeight', 'normal', 'String', '', 'Callback', callback);
    end;
end;

M.ui.buttonOK = uicontrol('Parent', M.pan, 'Style', 'pushbutton', ...
    'Units', 'norm', 'Position', [.2 .9-stepsize(end) .2 .06], ...
    'FontSize', 10, ...
    'FontWeight', 'normal', 'String', 'OK','CallBack', callback);

M.ui.buttonCancel = uicontrol('Parent', M.pan, 'Style', 'pushbutton', ...
    'Units', 'norm', 'Position', [.6 .9-stepsize(end) .2 .06], ...
    'FontSize', 10, ...
    'FontWeight', 'normal', 'String', 'Cancel', 'CallBack', 'close');


% store M in figure's UserData
set(M.fig, 'UserData', M);

return



%-------------------------------------------------------------
function status = rmEditStimulusParameters_update(view,M,hrfFlag)
% update 
if notDefined('M'), M = get(gcf, 'UserData'); end;
if notDefined('hrfFlag'), hrfFlag = false;    end;
if notDefined('view'), view = getCurView;     end;
mrGlobals;
status = 0;

scan = M.curScan;
newscan = round( get(M.ui.nScans.sliderHandle, 'Value') );
if newscan > M.nScans,
    set(M.ui.nScans.sliderHandle, 'Value',M.curScan);
    set(M.pan, 'UserData', M);
    axis off;
    return
end


% store data and load new ones
for n=1:size(M.sF,1),
    field = M.sF{n,1};
    switch field
        case {'stimType', 'imFile', 'paramsFile', 'imFilter'}
            data = get(M.ui.(field), 'Value');
            if ~isempty(data),
                M.stim(scan).(field) = data;
            end;
            set(M.ui.(field), 'Value', M.stim(newscan).(field));
            
            % TODO: update stimulus-type-sensitive labels, such as direction
   

        case {'hrfType'}
            data = get(M.ui.(field), 'Value');
            if ~isempty(data),
                hrfType = data; % store type for hrfParams
                M.stim(scan).(field) = data;
            else
                hrfType = [];
            end;
            set(M.ui.(field), 'Value', M.stim(newscan).(field));

        case {'hrfParams'}
            if ~hrfFlag, % if hrfType is updated update but not read hrfParams
                data = get(M.ui.(field), 'String');
                if ~isempty(data) && ~isempty(hrfType),   % do not change to str2double
                    M.stim(scan).(field){hrfType} = str2num(data); %#ok<ST2NM>
                end
            end
            % put in new data
            newHrfType = M.stim(newscan).hrfType;
            set(M.ui.(field), 'String', num2str(M.stim(newscan).(field){newHrfType}));
            
        case 'stimDir'  % parse stimulus direction (binary) based on popup value
            data = get(M.ui.(field), 'Value');
            if ~isempty(data),
                M.stim(scan).(field) =  data - 1; % vals 1-2 -> flag 0-1
            end;
            set(M.ui.(field), 'Value', M.stim(newscan).(field)+1);
			
		case 'flipLR'
			data = get(M.ui.(field), 'Value');
			M.stim(scan).(field) = data;	
			
			% redundancy: there is also a 'fliprotate' field which is more
			% general. This field may not be defined. Set this value as
			% well:
			if checkfields(M.stim(scan), 'fliprotate')
				M.stim(scan).fliprotate(1) = data;
			else
				% initialize: the values are:
				% [L/R flip, up/down flip, rotate degrees]
				% We can add GUI controls for the others later.
				M.stim(scan).fliprotate = [data 0 0];
			end
			 
        otherwise
            data = get(M.ui.(field), 'String');
            if ~isempty(data),% do not change to str2double
                M.stim(scan).(field) =  str2num(data); %#ok<ST2NM>
            end;
            set(M.ui.(field), 'String', num2str(M.stim(newscan).(field)));
    end
end;

M.curScan = newscan;

% if OK button is pushed
if get(M.ui.buttonOK, 'Value'),
    % set status to 1, so the parent function knows to 
    % update the view's pRF model params:
    persistent STATUS
    STATUS = 1;
    
    % put in string names of popup menus
    for scan=1:M.nScans,
        for n=1:size(M.sF,1),
            field = M.sF{n,1};
            
            switch field
                case {'hrfType'}
                    string = get(M.ui.(field), 'String');
                    id     = M.stim(scan).(field);
                    M.stim(scan).hrfId       = id;
                    M.stim(scan).(field) = string{id};
                case {'stimType', 'imFilter'}
                    string = get(M.ui.(field), 'String');
                    id     = M.stim(scan).(field);
                    M.stim(scan).(field) = string{id};
                case {'imFile', 'paramsFile'}
                    string = get(M.ui.(field), 'String');
                    id     = M.stim(scan).(field);
                    M.stim(scan).(field) = [pwd filesep 'Stimuli' filesep string{id}];
            end;
        end
    end
    
    
    % We (JW/BW) think that having duplicate copies of the stimulus
    % parameters in dataTYPES and in VOLUME{} is a bad idea.  They can get
    % out of sync.  We continue to follow the model because this might
    % break other people's code.  But we think we should eliminate the
    % dataTYPES copy of the rm stimulus params (that's all that's in there,
    % not the full model).  We should only have a copy in the VOLUME.rm...
    % field, and if we decide to save it we should save it explicitly with
    % a function (to be written).
    
    % update/save dataTYPES/rebuild stimuli and clean up
    dataTYPES(M.curDataType).retinotopyModelParams = [];
    dataTYPES(M.curDataType) = dtSet(dataTYPES(M.curDataType), ...
                                    'retinotopyModelParams', ...
                                    M.stim);
    view = rmLoadParameters(view);
    if ismember(view.name(1:4), {'INPL' 'VOLU'})  % global variable
        updateGlobal(view);
    end
    saveSession;
    close;
    return;
end;

% store structure in figure
set(M.fig, 'UserData', M);

% funny bug
%axis off;

return;
%-------------------------------------------------------------

%-------------------------------------------------------------
function M = rmInitStimStruct(v,sF)
mrGlobals;
M.nScans      = viewGet(v,'numscans');
M.curDataType = viewGet(v,'curdatatype');
M.curScan = 1;
try
    M.stim = dtGet(dataTYPES(M.curDataType),'retinotopyModelParams');
catch
    M.stim = [];
end;

if isempty(M.stim),
    for n=1:M.nScans,
        M.stim(n).(sF{1,1}) = sF{1,4};
    end;
end

% get stimulus names for comparison
stimDir   = fullfile(fileparts(which(mfilename)), 'StimulusDefinitions');
stimFiles  = dir(fullfile(stimDir, 'make*.m'));
myString  = {stimFiles.name};
for ii=1:numel(myString),
    myString{ii} = myString{ii}(numel('make')+1:end-numel('.m'));
end

stimDir   = 'Stimuli';

stimFiles  = dir(fullfile(stimDir, '*image*.mat'));
imString  = {'none', stimFiles.name};

stimFiles  = dir(fullfile(stimDir, '*param*.mat'));
paramsString  = {'none', stimFiles.name};

filterDir = fullfile(fileparts(which(mfilename)), 'FilterDefinitions');
filterFiles  = dir(fullfile(filterDir, 'rmfilter_*.m'));
imFilterString  = {filterFiles.name};
for ii=1:numel(imFilterString),
    imFilterString{ii} = imFilterString{ii}(numel('rmfilter_')+1:end-numel('.m'));
end
imFilterString  = ['none' imFilterString];


% For each scan populate the data in M using the structured field (sF)
% default parameters defined at the top.  
for s=1:M.nScans,
    for n=1:size(sF,1),
        if ~isfield(M.stim(s),sF{n,1}) || isempty(M.stim(s).(sF{n,1})),
            switch sF{n,1},
                case 'framePeriod',
                    M.stim(s).framePeriod = viewGet(v,'frameperiod',s);
                case 'nFrames',
                    M.stim(s).nFrames     = viewGet(v,'nframes',s);
                case 'hrfParams',
                    M.stim(s).hrfParams{1} = [1.68 3 2.05];
                    M.stim(s).hrfParams{2} = [5.4 5.2 10.8 7.35 0.35];
                otherwise,
                    M.stim(s).(sF{n,1})   = sF{n,4};
            end
        else
            switch sF{n,1},
                case {'stimType'}
                    name     = M.stim(s).(sF{n,1});
                    id = 1;
                    for ii=1:numel(myString),
                        if strcmpi(name,myString{ii}),
                           id = ii; 
                        end
                    end
                    M.stim(s).(sF{n,1}) = id;
                case {'imFile'}
                    name     = M.stim(s).(sF{n,1});
                    id = 1;
                    for ii=1:numel(imString),
                        if findstr(name, imString{ii}),
                           id = ii; 
                        end
                    end
                    M.stim(s).(sF{n,1}) = id;
                case {'paramsFile'}
                    name     = M.stim(s).(sF{n,1});
                    id = 1;
                    for ii=1:numel(paramsString),
                        if findstr(name,paramsString{ii}),
                           id = ii; 
                        end
                    end
                    M.stim(s).(sF{n,1}) = id;
                case {'hrfType'}
                    M.stim(s).(sF{n,1}) = M.stim(s).hrfId;

                case {'imFilter'}
                    name     = M.stim(s).(sF{n,1});
                    id = 1;
                    for ii=1:numel(imFilterString),
                        if findstr(name,imFilterString{ii}),
                           id = ii; 
                        end
                    end
                    M.stim(s).(sF{n,1}) = id;
                otherwise,
                    % nothing
            end
        end
    end
end

return;
%-------------------------------------------------------------

