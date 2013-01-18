function closeInplaneWindow()
%
% closeInplaneWindow()
%
% clears INPLANE while closing the corresponding window.
%
% djh, 1/26/98
mrGlobals

% Get the current figure
currentFigure = get(0,'CurrentFigure');

% Find and clear the corresponding INPLANE structure
try
    for s = 1:length(INPLANE)
        if checkfields(INPLANE{s}, 'ui', 'figNum')
            if INPLANE{s}.ui.figNum==currentFigure
                % let's try saving the prefs as we go, 
                % so we pick up where we left off... (ras 01/06)
                if ispref('VISTA', 'savePrefs')
                    flag = getpref('VISTA', 'savePrefs');
                    if flag==1
                        savePrefs(INPLANE{s});
                    end
                end

                % if this was the selected inplane, well, it ain't no more.
                if selectedINPLANE == s
                    selectedINPLANE = [];
                end

                % finally, clear the global variable
                INPLANE{s} = [];
            end
        end
    end
end

% Delete the window
delete(currentFigure);

% If there are no open Inplane windows left, re-initialize it as empty
if isempty(cellfind(INPLANE)), INPLANE = {}; end


% Check if there are no more open views: if not, clean the workspace
if isempty(cellfind(INPLANE)) & isempty(cellfind(VOLUME)) & ...
   isempty(cellfind(FLAT))
    mrvCleanWorkspace;
end

return
