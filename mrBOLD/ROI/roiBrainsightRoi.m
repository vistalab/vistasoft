function roiBrainsightRoi(roi,t1,outDir)
%
% function roiBrainsightRoi([roi],[t1],[outDir])
%
% This function will take a mrVista ROI, which has been converted to a
% nifti file (1) change the xForm and offset to match the xForm and offset
% in the t1 file (2) gunzip the new roi nifti file and (3) save it to the outDir.
%
% Brainsight is a software tool that we use for co-registering functional
% and anatomical MRI data to a subject's headspace for TMS.
%
% HISTORY:
% 12.16.2009 LMP wrote the thing.
% Aug 1, 2010  AMR took out gzip command-- looks like brainsight supports
% .nii.gz files now
%


if notDefined('outDir')
    outDir = pwd;
end

if notDefined('roi')
    [fname, p] = uigetfile({'*.nii*';'*.*'}, 'Choose ROI NIFTI File...', pwd);
    roi = fullfile(p,fname);
    if sum(fname==0) && sum(p==0)  % user cancelled
        fprintf('User cancelled.\n');
        return
    end
end

if notDefined('t1')
    [f, p] = uigetfile({'*.nii*';'*.*'}, 'Choose T1 NIFTI File...', pwd);
    t1 = fullfile(p,f);
end


roi = niftiRead(roi);
t1 = niftiRead(t1);

roi.data = uint16(roi.data);

roi.qoffset_x = t1.qoffset_x;
roi.qoffset_z = t1.qoffset_z;
roi.qoffset_y = t1.qoffset_y;

roi.qto_ijk = t1.qto_ijk;
roi.qto_xyz = t1.qto_xyz;
roi.sto_ijk = t1.sto_ijk;
roi.sto_xyz = t1.sto_xyz;

roi.fname = ['brainsight_' fname];
roi.descrip = ['xForm: ' t1.fname];

cd(outDir)

writeFileNifti(roi);

%system (['gunzip ' roi.fname]);  % brainsight can take .nii.gz files

disp('ROI saved. Brainsight: Use Manual mode to import, range [0 1].');
fprintf('%s\n',roi.fname);

end
