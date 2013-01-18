function vw = getCurView
%Returns the selected mrVista view.
%
%    vw = getCurView;
%
% If it can't find a selected one, it initializes a hidden inplane. A sort
% of super-function to getSelectedInplane, getSelectedGray, etc.
%
% How it looks: first, it checks if any views are open in the global
% INPLANE, VOLUME, or FLAT variables. If not, opens a hidden inplane.
% If there are open views, it checks if the current figure is the handle to
% one of the views. If this fails, then tries to find the selected inplane; 
% then the selected volume; then the selected flat.
%
% ras, 05/01/06.
mrGlobals;

vw = [];

if isempty(cellfind(INPLANE)) && isempty(cellfind(VOLUME)) && ...
        isempty(cellfind(FLAT))
    disp('No open mrVista UIs. Initializing a hiddden inplane...')
    try
        vw = initHiddenInplane;
    catch
        disp('Couldn''t start a hidden inplane -- not in a mrVista session!')
    end
    return
end

% check if gcf is a view handle
for i = cellfind(INPLANE)
    if checkfields(INPLANE{i}, 'ui', 'windowHandle') && ...
            isequal(INPLANE{i}.ui.windowHandle, gcf)
        vw = INPLANE{i};
        return
    end
end
for i = cellfind(VOLUME)
    if checkfields(VOLUME{i}, 'ui', 'windowHandle') && ...
            isequal(VOLUME{i}.ui.windowHandle, gcf)
        vw = VOLUME{i};
        return
    end
end
for i = cellfind(FLAT)
    if checkfields(FLAT{i}, 'ui', 'windowHandle') && ...
            isequal(FLAT{i}.ui.windowHandle, gcf)
        vw = FLAT{i};
        return
    end
end

% None of the above worked; try to get selected inplane/volume/flat
if isempty(vw), vw = getSelectedInplane; end
if isempty(vw), vw = getSelectedVolume;  end
if isempty(vw), vw = getSelectedFlat;    end

% Report on failure
if isempty(vw)
    disp('Failed to find any views ... returning empty')
end

return
