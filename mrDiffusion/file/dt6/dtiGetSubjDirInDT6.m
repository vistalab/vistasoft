function subjDir = dtiGetSubjDirInDT6(dt6File)
%
%  subjDir = dtiGetSubjDirInDT6(dt6File)
%
%Author: AJS
%Purpose:
%   Get subject directory that every filename in the dt6 file is based off
%   of.  
%
%   Notes: We assume right now that the subject directory is just the level
%   above the dt6 file.  This is a cheap method for platform independence
%   and needs to be fixed.
%
% HISTORY:
%  2007.07.20 AJS: wrote it.
% 2008/11/04 DY: we now have "mrvdirup" which can strip off parts of the
% path without needing to cd. Using cd+pwd is bad, because if you are working
% with softlinks on certain platforms, cd+pwd will either let you "keep"
% the softlink path, or instead give you the "real" path (where the
% softlink silently points). This causes the while loop in
% dtiGetSubjDirInDT6 to proceed infinitely (as it tries to compare a
% "real" and "softlink" path and never find a match). Tony's worry about
% assuming that the subject directory is a level above the dt6 directory
% still stands. 

% We are going to let the system do directory name matching for us,
% otherwise we would have to handle special conditions, e.g. if a relative
% filename was given.

subjDir = mrvDirup(dt6File,2);


return;
