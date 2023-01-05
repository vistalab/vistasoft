function [M, sF] = rmStimCreate(varargin)
%Create the retinotopy model stimulus parameter structure
%
%  sParams = rmStimCreate;
%
% We would like this one to be eliminated in the end.
%    
%Example:
%

mrGlobals

v = getCurView;

%% Basic definition of the slots in the structure.  
% This could be simplified and a better create process could be built

% These are the retinotopy model stimulus fields.
sF = { ...
    'stimType',        'Stimulus type',                                true,   1; ...
    'stimSize',        'stimulus radius (deg)',                        true,   14; ...
    'stimWidth',       'Stimulus width (deg)',                         true,   45; ...
    'stimStart',       'Stimulus starting phase (deg)',                true,   0; ...
    'stimDir',         'Stimulus direction (boolean)',                 true,   0; ...
    'nCycles',         'Stimulus cycles (#)',                          true,   6; ...
    'nStimOnOff',      'Mean-luminance blocks (#)',                    true,   0; ...
    'nUniqueRep',      'Stimulus repetitions (#)',                     true,   1; ...
    'prescanDuration', 'Removed time frames with stimuli (#)',         true,   8; ...
    'nDCT',            'DCT frequency max for detrending (#)',         true,   0; ...
    'hrfType',         'HRF type',                                     true,   1;...
    'hrfParams',       'HRF parameters',                               true,   '';...
    'framePeriod',     'Frame interval (sec)',                         false,   '';...
    'nFrames',         'Time frames (#)',                              false,   '';...
	'flipLR',		   'Flip Stimuli Left/Right',					   true,	0;...
	'imFile',          'Image File (Stimuli/*image*.mat)',             true,    1;...
    'paramsFile',      'Params File (Stimuli/*param*.mat)',            true,   1;...  
    'imFilter',         'Image filter'                                 true,   1;...
    };

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