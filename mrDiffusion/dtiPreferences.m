function prefs = dtiPreferences(newPrefs);
% Prompts user to adjust mrDiffusion preferences. Initializes defaults if ~exist.
% prefs = dtiPreferences
%
% USAGE:
% TO PROMPT FOR PREFERENCES: dtiPreferences; [no args]
% TO GET PREFERENCES WITHOUT PROMPTING: prefs = dtiPreferences;
% TO SET NEW PREFERENCES WITHOUT PROMPTING: dtiPreferences(newPrefs);
%
% The user will usually only be prompted if the preferences don't yet
% exist. However, if you call this function with no return arg, it will
% always prompt.
%
% HISTORY:
% 2007.09.26 RFD wrote it (based on mrmPreferences).

if nargin >= 1
    prefs = newPrefs;
    promptUser = false;
elseif(nargout==0)
    promptUser = true;
else
    promptUser = false;
end


prefNames = {'applyBrainMask', 'viewInterpMm', 'viewInterpMethod'};
prefHelp = {'Should the brain mask be applied? (yes or no)', ...
            'Slice-view interpolation resolution (in mm)', ...
            'Slice-view interpolation method (nearest,trilin,spline)'};
        
% layerMapMode values: 'all', 'layer1'
defaultVals = {'yes', 1, 'nearest'};
if (~ispref('mrDiffusion'))
    setpref('mrDiffusion', prefNames, defaultVals);
    promptUser = true;
    disp(['Initializing mrDiffusion preferences- run ' mfilename ' to change them in the future.']);
else
    % check if any new preferences were added or old preferences removed
    prefs = getpref('mrDiffusion');
    existingPrefs = fieldnames(prefs)';
    newPrefs = setdiff(prefNames, existingPrefs);
    for i = find(ismember(prefNames, newPrefs))
        % new preferences were added- try to keep this user's old values.
        % keep old vals by only adding new prefs.
        setpref('mrDiffusion', prefNames{i}, defaultVals{i});
        promptUser = true;
        disp(['New mrDiffusion preferences were added (remember- use ' ...
                mfilename ' to change prefs in the future).']);
    end
    
    if ~isempty(newPrefs)
        % need to shuffle order of fields in prefs struct to 
        % correspond to the order in prefNames. <sigh>
        prefs = getpref('mrDiffusion');
        rmpref mrDiffusion
        for i = 1:length(prefNames)
            setpref('mrDiffusion', prefNames{i}, prefs.(prefNames{i}));
        end
        prefs = getpref('mrDiffusion')
    end
    
    % these prefs may have been set before, but are no longer relevant.
    removedPrefs = setdiff(existingPrefs, prefNames);
    for name = removedPrefs(:)',  rmpref('mrDiffusion', name{1});  end
end

if(promptUser)
    prefs = getpref('mrDiffusion');
    for(ii=1:length(prefNames))
        prompt{ii} = [prefNames{ii} '- ' prefHelp{ii}];
    end
    defAns = struct2cell(prefs);
    wasNumeric = zeros(size(defAns));
    for(ii=1:length(defAns))
        if(~ischar(defAns{ii}))
            defAns{ii} = num2str(defAns{ii});
            wasNumeric(ii) = 1;
        end
    end
    resp = inputdlg(prompt, 'Adjust mrDiffusion preferences', 1, defAns);
    if(~isempty(resp))
        for(ii=find(wasNumeric(:)'))
            resp{ii} = str2num(resp{ii});
        end
        setpref('mrDiffusion', prefNames, resp);
    end
end

prefs = getpref('mrDiffusion');

return;