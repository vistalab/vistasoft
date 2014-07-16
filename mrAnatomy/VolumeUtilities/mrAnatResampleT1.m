function [t1New, xformNew, bb] = mrAnatResampleT1(t1File, outT1FileName, outMm, bb, xform)
% Resample a t1 to a specified resolution
%
% [t1New, xformNew] = mrAnatResampleT1(t1File, outMm)
%
% Cropped out of mrGrayResampleNiftiClass, as we sometimes want to resample
% a t1 NIFTI without also resampling class files.
%
% Example:
%   nipath  = 't1-1.nii.gz';
%   outpath = 't1-1resliced.nii.gz';
%   outMm   = [1 1 1];
%   mrAnatResampleT1(nipath, outpath, outMm);
%
%
% 4/2009: JW
%

disp('resampling the t1...');

% Get the t1
t1 = niftiRead(t1File);

% Get the xform from the nifti struct
if notDefined('xform'), xform = t1.qto_xyz; end

if notDefined('bb')
    % Create a bounding box in image space
    bb = [1 1 1; t1.dim(1:3)+1];

    % Convert the bounding box to mm space
    bb = floor(mrAnatXformCoords(xform,bb));
end

% Reslice
[t1New,xformNew] = mrAnatResliceSpm(double(t1.data),inv(xform),bb,outMm,[0 0 0 7 7 7],0);

% Convert to single
t1New = single(t1New);

% Save it
disp('saving results...');
dtiWriteNiftiWrapper(t1New,xformNew,outT1FileName);

return
