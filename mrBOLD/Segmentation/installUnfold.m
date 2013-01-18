function installUnfold(flatSubdir,query)
%
% function installUnfold([flatSubdir],[query])
%
% Rebuild coords after a new unfold.
%
%    flatSubdir: used to specify the flat subdirectory in case there is
%    more than one unfold available. Default: prompt user to choose from a menu.
%
% Note: could automatically rebuild Gray/corAnals by xforming from inplane, but we
% would have to do this for each dataType.
%
% 12/8/00 Wandell and Huk
% djh, 2/14/2001
%    updated to use hiddenFlat instead of opening a window

if ~exist('flatSubdir','var')
	flatSubdir = getFlatSubdir;
end

if ~exist('query','var')
    query = 1;
end

if query
    resp = questdlg(['Delete ',flatSubdir,'/anat, coords, corAnal, ' ...
                     'and parameter map files and close flat window(s)?']);
else
    resp = 'Yes';
end

%delete coords and rebuild
if strcmp(resp,'Yes')
    closeAllFlatWindows(flatSubdir);
    cleanFlat(flatSubdir);
    
    % Open hidden gray structure because we need the gray coords
    hiddenGray = initHiddenGray;
    
    % Load flat file, compute & save coords
    hiddenFlat = initHiddenFlat(flatSubdir);
    
    % Compute and save flat anat file
    hiddenFlat = loadAnat(hiddenFlat);
    disp('Rebuilt Flat coords and anat files. Deleted old corAnals.');
    
else
    disp('Coords and corAnals not deleted.');
    
end

return
