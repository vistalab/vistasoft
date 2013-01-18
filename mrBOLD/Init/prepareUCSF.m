% This script now does a lot of stuff:
% renames dicom files, 
% Converts to analyze 4D
% runs MC-FLIRT and then FLIRT to do within and between-scan MC
% Then continues recon (or completes recon - we can skip stuff like cropping
% which we never do any more. And we should get more info from the DB -
% things like subject name etc...
% See also mrInitRetDICOM - that might be a better place to start since it
% begins with the DB query that we need for other stuff.
% Note: IN the db we want some other info that is not currently entered:
% TRs, skipped frames, nSlices. Also possibly nCycles. 
% 
!mkdir RawDicom
!mv [1-9]* ./RawDicom
!mkdir Inplane
!mkdir Volume
!mkdir Gray
disp('Now run mrInitRetDicom...');
