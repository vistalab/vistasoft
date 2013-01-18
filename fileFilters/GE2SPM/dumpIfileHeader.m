function dumpIfileHeader(ifileName)
% dumpIfileHeader(ifileName)
%
% Displays some of the GE header fields for the given I-file 
% (eg. 'I.001') in human-readable format. 
%
% REQUIRES:
%  GE2SPM tools- eg. addpath /usr/local/matlab/toolbox/mri/filters/GE2SPM/
%   -or-
%  matlab's DICOM tools (part of the image processing toolbox in matlab
%  version >= 6.5)
% 
% HISTORY:
%  2002.06.07 RFD (bob@white.stanford.edu) wrote it.
%  2004.07.01 RFD: we now use Junjie's readImageHeader, so that this
%  function will work with either GE I-files or DICOM files.

if(nargin<1)
    help(mfilename);
    return;
end

[su_hdr,ex_hdr,se_hdr,im_hdr] = readImageHeader(ifileName);

disp(sprintf('Exam #: %d', ex_hdr.ex_no));
% GE timestamp is a unix timestamp- # of seconds since 1970.01.01 00:00:00
% eg. yr = round(1970+ex_hdr.ex_datetime/60/60/24/365.25); ...
disp(sprintf('Exam timestamp: %d', ex_hdr.ex_datetime));
disp(sprintf('Hospital name: %s', char(ex_hdr.hospname')));
disp(sprintf('Field strength: %0.1f Tesla', ex_hdr.magstrength/10000));
disp(sprintf('Patient ID: %s', char(ex_hdr.patid')));
disp(sprintf('Patient name: %s', char(ex_hdr.patname')));
disp(sprintf('Patient weight: %0.1f Kg', ex_hdr.patweight/1000));
disp(sprintf('Patient age: %0.0f years', ex_hdr.patage));
disp(sprintf('History: %s', char(ex_hdr.hist')));
disp(sprintf('Exam description: %s', char(ex_hdr.ex_desc')));

disp(sprintf('PSD iname: %s', char(im_hdr.psd_iname')));
disp(sprintf('Scan Time: %0.1f minutes', im_hdr.sctime/1000000/60));
disp(sprintf('FOV: %0.1f', im_hdr.dfov));
disp(sprintf('X,Y dim: %d, %d', im_hdr.dim_X, im_hdr.dim_Y));
disp(sprintf('X,Y pixels: %d, %d', im_hdr.imatrix_X, im_hdr.imatrix_Y));
disp(sprintf('nSlices: %d @ %0.4f mm thickness', im_hdr.slquant, im_hdr.slthick));
disp(sprintf('in-plane voxel size: x=%0.4f mm, y=%0.4fmm', im_hdr.pixsize_X, im_hdr.pixsize_Y));
disp(sprintf('TR: %0.1f ms', im_hdr.tr));
disp(sprintf('TI: %0.1f ms', im_hdr.ti));
disp(sprintf('TE: %0.1f ms (%d echos)', im_hdr.te, im_hdr.numecho));
disp(sprintf('flip: %d deg', im_hdr.mr_flip));
disp(sprintf('NEX: %f', im_hdr.nex));
disp(sprintf('SAR average: %f, peak: %f', im_hdr.saravg, im_hdr.sarpeak));

return;