function mrAnatConvertVAnatToT1Nifti(vAnat,outFileName)
%
%  mrAnatConvertVAnatToT1Nifti([vAnat],[outFileName])
%
% This function takes a vAnatomy.dat file converts it to a NIFTI and saves
% that NIFTI struct as vAnatomy.nii.gz by default.
%
% vAnat is a file name to a vAnatomy.dat
% outFilenmae defaults to 'vAnatomy.nii.gz'.
%
% Example:
%  vAnatFileName='Z:\data\reading_longitude\dti_y2\am051014\t1\vAnatomy.dat';
%  outFileName = [];
%  mrAnatConvertVAnatToT1Nifti(vAnatFileName,outFileName);
%
% HISTORY:
% 4/20/2009 LMP wrote the thing
%
% LMP (c) Stanford VISTALAB

if(~exist('vAnat','var') || isempty(vAnat))
    [f,p] = uigetfile({'*.dat';'*.*'},'Select a vAnatomy.dat file for input...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    vAnat = fullfile(p,f);
end

if(~exist('outFileName','var') || isempty(outFileName))
    [p,f] = fileparts(vAnat);
    outFileName = fullfile(p,'vAnatomy.nii.gz');
    [f,p] = uiputfile('*.nii.gz','Select output file...',outFileName);
    if(isnumeric(f)) disp('User canceled.'); return; end
    outFileName = fullfile(p,f);
end

[vData,mmPerVox] = readVolAnat(vAnat);

% Convert mrgray sagittal format to our preferred axial format for NIFTI
vData = flipdim(flipdim(permute(vData,[3 2 1]),2),3);
mmPerVox = mmPerVox([3 2 1]);
xform = [diag(1./mmPerVox), size(vData)'/2; 0 0 0 1];

% Modern version - BW, October 2012
ni = niftiCreate('fname',outFileName,'qto_xyz',inv(xform));

% ni.qto_xyz = inv(xform);
% ni.qto_ijk = xform;
% ni.sto_xyz = inv(xform);
% ni.sto_ijk = xform;
% This should be replaced by ni = niftiCreate( ... args ... )
% ni = niftiGetStruct(vData, inv(xform));
% ni.fname = outFileName;

writeFileNifti(ni);
return