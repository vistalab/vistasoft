function rxSaveMrVistaAlignment(rx,mrSessPath)
%
% rx = rxSaveMrVistaAlignment([rx],[mrSessPath])
%
% Save a mrRx alignment to a mrSESSION.mat file 
% in the specified path. 
%
% If an existing alignment has already been
% saved, prompts the user and, if the old alignment
% is saved over, cleans all gray, volume, and 
% flat directories.
%
% ras 03/05.
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if notDefined('mrSessPath')
    mrSessPath = fullfile(pwd,'mrSESSION.mat');
end

if ~exist(mrSessPath,'file')
    msg = sprintf('%s not found.',mrSessPath);
    myErrorDlg(msg);
end

mrGlobals;
loadSession;

% check if an alignment already exists
if isfield(mrSESSION, 'alignment')
    msg = ['An existing alignment has been loaded into this '...
          'mrVista session. If you proceed, you will permanently ' ...
          'delete this alignment, and need to rebuild any Volume, ' ...
          'Gray, and Flat views you''ve made with the old alignment. ' ...
		  'Do you want to save over this alisngment? '];
      
    response = questdlg(msg,'Existing Alignment Found', ...
						'Yes, delete existing files', ...
						'Save Alignment but don''t delete files', ...
						'No, Cancel', 'No, Cancel');
    switch response
        case 'Yes, delete existing files'
            % delete (after confirmation) old files that were built
            % using previous alignment.
            cleanAllFlats
            cleanGray
            cleanVolume
        case 'Save Alignment but don''t delete files'
            % proceed without deleting stuff --
            % I learned about this option the very hard way. :(
        otherwise
            % abort
            disp('Did not save new alignment.')
            return
    end
    
end

% If we've made it this far, go ahead and replace mrSESSION.alignment field.   
% first account for x,y -> y,x change
newXform = rx.xform;
newXform([1 2],:) = newXform([2 1],:);
newXform(:,[1 2]) = newXform(:,[2 1]);

% now add to mrSESSION struct and save
mrSESSION.alignment = newXform; 
saveSession


disp('mrSESSION.alignment has been updated and saved.');


return
