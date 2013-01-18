% script to incorporate bestrotvol.mat into mrSESSION for
% mrLoadRet-10.0
% 9/17/98 rmk
% 4/29/99 BTB: Removed Inpts and Volpts fields, added tests for mrSESSION
%    field and coords.mat & coranal.mat files.

eval(['load bestrotvol']);

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
            'coords.mat files from Volume, Gray, or Flat directories.'], 'Warning','warn'); drawnow
      return
   end
end

% If we've made it this far, go ahead an replace mrSESSION fields.
% This next line should be completely unnecessary because mrSESSION should already
% know its voxelSize (djh, 8/2001).
mrSESSION.voxelSize = 1./scaleFac(1,:); % Size of functional voxels in mm
mrSESSION.alignment.inplane2VolXform = inplane2VolXform(rot,trans,scaleFac);    % 4x4 homog transform
% These next two are not actually used by anyone; will be gone from now on. --BTB
%   mrSESSION.alignment.Inpts = inpts;    % Inplane points chosen by user in mrAlign
%   mrSESSION.alignment.Volpts = volpts;  % Corresponding volume points
save mrSESSION mrSESSION
disp('mrSESSION.voxelSize and mrSESSION.alignment have been updated and saved.');

%%% Delete (after confirmation) old files that were built using previous alignment. %%%

pathStrVolume  = [mrSESSION.homeDir,'/Volume/coords.mat'];
pathStrVolumeA = [mrSESSION.homeDir,'/Volume/coranal.mat'];
pathStrGray    = [mrSESSION.homeDir,'/Gray/coords.mat'];
pathStrGrayA   = [mrSESSION.homeDir,'/Gray/coranal.mat'];
pathStrFlat    = [mrSESSION.homeDir,'/Flat/coords.mat'];
pathStrFlatA   = [mrSESSION.homeDir,'/Flat/coranal.mat'];

if check4File(pathStrVolume) 
   RESP = questdlg(['Delete existing Volume/coords.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrVolume); end
end
if check4File(pathStrVolumeA) 
   RESP = questdlg(['Delete existing Volume/coranal.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrVolume); end
end

if check4File(pathStrGray) 
   RESP = questdlg(['Delete existing Gray/coords.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrGray); end
end
if check4File(pathStrGrayA) 
   RESP = questdlg(['Delete existing Gray/coranal.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrGray); end
end

if check4File(pathStrFlat) 
   RESP = questdlg(['Delete existing Flat/coords.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrFlat); end
end
if check4File(pathStrFlatA) 
   RESP = questdlg(['Delete existing Flat/coranal.mat?'], 'Question', 'Yes', 'No', 'Yes');
   if strcmp(RESP, 'Yes') delete(pathStrFlat); end
end

