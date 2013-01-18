function closeAllFlatWindows(flatSubdir)
%
% function closeAllFlatWindows([flatSubdir])
%
% Loop through FLAT, closing all the flat windows
%
% flatSubdir: Default is to close all flat windows. If flatSubdir is specified
% then close only those flat views such that view.subdir == flatSubdir
%
% Called by installUnfold
%
% djh, 2/14/2001

mrGlobals

disp('Closing flat windows');
if ~exist('flatSubDir','var'), flatSubdir = []; end

for s = 1:length(FLAT)
    if ~isempty(FLAT{s})
        % In a new segmentation installation, we don't yet have a sub
        % directory name.  So, in that case, we don't close anything
        if ~checkfields(FLAT{s},'subdir')
            return;
        else
            % OK, we have flatSubDir, we have a name, check they match, and
            % if so, close the damn window.
            if strcmp(FLAT{s}.subdir,flatSubdir)
               close(FLAT{s}.ui.windowHandle);
           end
        end
    end
end

return;
