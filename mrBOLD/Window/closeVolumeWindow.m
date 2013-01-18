function closeVolumeWindow(fig)
%
% closeVolumeWindow(fig)
%
% clears VOLUME while closing the corresponding window.
%
% djh, 1/26/98
% ras, 03/06: checks if a mesh is attached to the view first, and if
% so, prompts user. Also: if you run setpref('VISTA', 'savePrefs', 1),
% will save preferences on close.
mrGlobals

% Get the current figure
if notDefined('fig')
	fig = gcf;
end

figure(fig);

try
    % Find and clear the corresponding VOLUME structure
    for s = 1:length(VOLUME)
        if checkfields(VOLUME{s}, 'ui', 'figNum')
            if VOLUME{s}.ui.figNum==fig
                % let's try saving the prefs as we go, 
                % so we pick up where we left off... (ras 01/06)
                if ispref('VISTA', 'savePrefs')
                    flag = getpref('VISTA', 'savePrefs');
                    if flag==1
                        savePrefs(VOLUME{s});
                    end
                end

                % if this was the selected volume, well, it ain't no more.
                if selectedVOLUME == s
                    selectedVOLUME = [];
                end

                % before clearing the view, check if a mesh is attached
                if isfield(VOLUME{s}, 'mesh') & ~isempty(cellfind(VOLUME{s}.mesh))
                    
                    q = ['A 3D Mesh is attached to this window. ' ...
                         'Close the mesh as well?'];
                    resp = questdlg(q, mfilename, 'Close Mesh(es)', ...
                                    'Close VOLUME window only', ...
                                    'Cancel', 'Cancel');
                    switch resp
                        case 'Close Mesh(es)', closeMeshes(VOLUME{s});                            
                        case 'Close VOLUME window only', % do nothing
                        otherwise, return;
                    end
                    
                end
                
                % finally, clear the global variable
                VOLUME{s} = [];
            end
        end
    end
end

% Delete the window
delete(fig);

% If there are no open Volume windows left, re-initialize it as empty
if isempty(cellfind(VOLUME)), VOLUME = {}; end

% Check if there are no more open views: if not, clean the workspace
if isempty(cellfind(INPLANE)) & isempty(cellfind(VOLUME)) & ...
   isempty(cellfind(FLAT))
    mrvCleanWorkspace;
end

return
% /----------------------------------------------------------------/ %





% /----------------------------------------------------------------/ %
function closeMeshes(view);
% Close all the meshes attached to a view. Then find any 3D Window
% GUIs open, which point to the view, and close them.
allMeshes = viewGet(view, 'allmeshes');
mrmSet(allMeshes, 'closeall');
h = findobj('Name', '3DWindow (mrMesh)');
close(h);
return
