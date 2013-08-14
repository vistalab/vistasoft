function [outFileName,imData] = mrAnatMakeNiftiFromIfiles(ifileDir, outFileName, options)
% [outFileName,imData] = mrAnatMakeNiftiFromIfiles(ifileDir, [outFileName], [options])
%
% ifileDir shall include the filename prefix- eg. 'spgr1/I' for I-files
% that look like 'I.001', 'I.002.dcm', etc...
%
% outFileName should not include '.nii'- just the base name.
% It defaults to a reasonable file name in the current working directory.
%
% options is a cell array specifying various little options. Currently 
% supported options:
%   'verbose' : displays various bits of information and progress (default).
%   'silent'  : opposite of verbose.
%   't1pd'    : separate every other slice into two volumes (useful
%               for the t2/pd acqusitions)
% 
% We will grab all suitable I-Files in ifileDir. If you did acquire multiple 
% anatomies using the same prescription, put them in separate folders.
%
% The data in the resulting NIFTI file will be oriented according to 
% our convention- 'transverse unflipped' (orient code '0' in Analyze-speak).
% That is, the image will be reoriented so that left-right is 
% along the x-axis, anterior-posterior is along the y-axis, superior-inferior 
% is along the z-axis, and the leftmost, anterior-most, superior-most point is 
% at 0,0,0 (which, for NIFTI/Analyze, is the lower left-hand corner of the 
% last slice). 
%
% To help you find the 0,0,0 point, a 4-pixel rectange is drawn there with a pixel
% value equal to the maximum image intensity.
%
% The reorientation involves only cannonical rotations and mirror flips- no
% interpolation is performed. Also, note that the reorientation depends on info
% in the GE I-file header- if this info is wrong, the reorientation will be wrong.
%
% REQUIRES:
%   * Stanford Anatomy and filter functions
%
% SEE ALSO: makeANalyzeFromIfiles, analyze2mrGray, mrGray2Analyze,
% makeAnalyzeFromRaw (that does all the hard work).
%
% HISTORY:
%   2005.08.17 RFD (bob@white.stanford.edu): wrote it, based on makeAnalyzeFromIfiles.


if(~exist('ifileDir','var') || isempty(ifileDir))
    [f,p] = uigetfile({'*.dcm;*.001';'*.*'}, 'Select the first data file...');
    if(isnumeric(f)) disp('User canceled.'); return; end
    ii = [strfind(f,'_') strfind(f,'.')];
    if(~isempty(ii)) f = f(1:ii(1)-1); end
    ifileDir = fullfile(p,f);
end
if(~exist('outFileName','var') || isempty(outFileName))
    [p,f] = fileparts(ifileDir);
    outFileName = fullfile(pwd, f);
    [f,p] = uiputfile('*.nii.gz','Select output file...',outFileName);
    if(isnumeric(f)) disp('User canceled.'); return; end
    outFileName = fullfile(p, f);
end
if(~exist('options','var'))
    options = {};
end

[img2std, ifileBaseName, mmPerVox, imDim, notes] = computeCannonicalXformFromIfile(ifileDir);
[scanner2img] = computeXformFromIfile(ifileDir);

% Get a default NIFTI struct
niftiIm = niftiRead;
if(length(outFileName)<7||~strcmpi(outFileName(end-6:end),'.nii.gz'))
  outFileName = [outFileName '.nii.gz'];
end
niftiIm.fname = outFileName;

% Load the image data 
disp(['Loading data from ', ifileDir, '...']);
img = int16(makeCubeIfiles(ifileDir, imDim([1,2]), 1:imDim(3))); %[startIndex:startIndex+imDim(3)-1]));

[niftiIm.data, niftiIm.pixdim] = applyCannonicalXform(img, img2std, mmPerVox);
sz = size(niftiIm.data);

img2phys = inv(scanner2img)*inv(img2std);
% extract image offset (in physical space)
offset = img2phys*[0 0 0 1]';
% Enforce some sane precision limits
offset = round(offset.*100)./100;
niftiIm.pixdim = round(niftiIm.pixdim.*100000)./100000;
% convert rotation to a quaternion (See nifti1.h for details).
% First, extract rotation matrix (we don't worry about shears-
% there should be none!).
rot = img2phys(1:3,1:3)/diag(niftiIm.pixdim);
% Keep things simple- zero should be 0 and not -9.1309e-17.
rot = round(rot.*1000)./1000;
qa = 0.5  * sqrt(1+rot(1,1)+rot(2,2)+rot(3,3));
qb = 0.25 * (rot(3,2)-rot(2,3)) / qa;
qc = 0.25 * (rot(1,3)-rot(3,1)) / qa;
qd = 0.25 * (rot(2,1)-rot(1,2)) / qa;

niftiIm.scl_slope = 0;
niftiIm.scl_inter = 0;
niftiIm.cal_min = 0;
niftiIm.cal_max = 0;
niftiIm.qform_code = 1;
niftiIm.sform_code = 0;
% *** TO DO: Set these using header data!
niftiIm.freq_dim = 0;
niftiIm.phase_dim = 0;
niftiIm.slice_dim = 0;
niftiIm.slice_code = 0;
niftiIm.slice_start = 0;
niftiIm.slice_end = 0;
niftiIm.slice_duration = 0;
niftiIm.qfac = 1;
niftiIm.quatern_b = qb;
niftiIm.quatern_c = qc;
niftiIm.quatern_d = qd;
niftiIm.qoffset_x = offset(1);
niftiIm.qoffset_y = offset(2);
niftiIm.qoffset_z = offset(3);
niftiIm.sto_xyz = eye(4);
niftiIm.toffset = 0;
niftiIm.xyz_units = 'mm';
niftiIm.time_units = 'sec';
niftiIm.intent_code = 0;
niftiIm.intent_p1 = 0;
niftiIm.intent_p2 = 0;
niftiIm.intent_p3 = 0;
niftiIm.intent_name = '';
niftiIm.descrip = '';
niftiIm.aux_file = 'none';

if(~isempty(strmatch('t1pd',lower(options))))
    fname = niftiIm.fname;
    img = niftiIm.data;
    for(ii=1:2)
        niftiIm.fname = sprintf('%s_%d ...', fname, ii);
        disp(sprintf('Saving %s ...', niftiIm.fname));
        niftiIm.data = img(:,:,[ii:2:end]);
        writeFileNifti(niftiIm);
    end
    if(nargout>1)
        imData = img;
    end
else
    disp(['Saving ' niftiIm.fname ' ...']);
    writeFileNifti(niftiIm);
    if(nargout>1)
        imData = niftiIm.data;
    end
end


return;
