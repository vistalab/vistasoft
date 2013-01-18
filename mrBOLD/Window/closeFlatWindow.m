function closeFlatWindow
%
% closeFlatWindow()
%
% clears FLAT while closing the corresponding window.
%
% djh, 1/26/98
% aab,bw  We wanted to be able to avoid the empty FLAT{} cells because
% those get in the way in some calculations.  We started to remove the
% empty cells, but then we realized that this would mess up existing flat
% windows that already knew about their FLAT{} structure and used them in a
% callback.  If we could reset those numbers, we would do the removal.  Too
% hard for now.
%

mrGlobals

% Get the current figure
currentFigure = get(0,'CurrentFigure');

% Find and clear the corresponding FLAT structure
try
    for s = 1:length(FLAT)
        if checkfields(FLAT{s}, 'ui', 'figNum')
            if FLAT{s}.ui.figNum==currentFigure
                % let's try saving the prefs as we go, 
                % so we pick up where we left off... (ras 01/06)
                if ispref('VISTA', 'savePrefs')
                    flag = getpref('VISTA', 'savePrefs');
                    if flag==1                
                        savePrefs(FLAT{s});
                    end
                end                

                % if this was the selected FLAT, well, it ain't no more.
                if selectedFLAT == s
                    selectedFLAT = [];
                end

                % finally, clear the global variable
                FLAT{s} = [];
            end
        end
    end
end

% If there are no open Flat windows left, re-initialize it as empty
if isempty(cellfind(FLAT)), FLAT = {}; end

% Delete the window
delete(currentFigure);

% Check if there are no more open views: if not, clean the workspace
if isempty(cellfind(INPLANE)) & isempty(cellfind(VOLUME)) & ...
   isempty(cellfind(FLAT))
    mrvCleanWorkspace;
end

return;

% %------------------------------------------------
% function newView = removeEmptyCells(view)
% %
% %  newView = removeEmptyCells(view)
% %  
% % Author: Brewer, Wandell
% % Purpose:
% %   We wanted to get rid of those annoying empty FLAT{} cells.  We sure
% %   hope that doesn't screw anything else up.
% 
% nViews = length(view);
% count = 0;
% for ii=1:nViews
%     if ~isempty(view{ii})
%         count = count+1;
%         newView{count} = view{ii};
%     end
% end
% 
% return;
