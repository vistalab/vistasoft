function loadAlignment
% function loadAlignment
%
% loads bestrotvol.mat, converts it into a 4x4 homog transform matrix
% and incorporates it into mrSESSION.alignment.
%
% 9/17/98 rmk
% 4/29/99 BTB: Removed Inpts and Volpts fields, added tests for mrSESSION
%    field and coords.mat & coranal.mat files.
% 8/2001 djh: updated to mrLoadRet-3.0

global HOMEDIR mrSESSION

pathStr = fullfile(HOMEDIR,'bestrotvol.mat');
if ~exist(pathStr,'file')
    myErrorDlg('No bestrotvol file. Run mrAlign3.');
end
load(pathStr);

if isfield(mrSESSION, 'alignment')
    RESP = questdlg(['mrSESSION has an ''alignment'' field '...
            '(created when rotation was last saved).  '...
            'It was used to build any coords.mat and coranal.mat '...
            'files you may have in Volume, Gray, and Flat directories.'...
            'Permanently replace it with new alignment info?  '], ...
        'Question', 'Yes', 'No', 'Yes');
    if strcmp(RESP, 'Yes')
        rmfield(mrSESSION, 'alignment');
    else
        hmsgbox = msgbox(['Although you have updated the file bestrotvol.mat, ',...
                'you have NOT updated mrSESSION.alignment, nor deleted any old ', ...
                'coords.mat files from Volume, Gray, or Flat directories.'], 'Warning','warn'); 
        drawnow
        return
    end
end

% If we've made it this far, go ahead an replace mrSESSION.alignment field.   
% 4x4 homog transform
mrSESSION.alignment = inplane2VolXform(rot,trans,scaleFac); 
saveSession
disp('mrSESSION.alignment has been updated and saved.');

%%% Delete (after confirmation) old files that were built using previous alignment.
cleanAllFlats
cleanGray
cleanVolume
