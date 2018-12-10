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
%  vAnatPath = mrtInstallSampleData('anatomy/anatomyV','vAnatomy', ...
%   [], [], 'filetype', 'dat');
%  outFileName = [];
%  vAnatFileName = sprintf('%s.dat', vAnatPath);
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
    p = fileparts(vAnat);
    outFileName = fullfile(p,'vAnatomy.nii.gz');    
end

[vData,mmPerVox] = readVAnat(vAnat);

% Convert mrgray sagittal format to our preferred axial format for NIFTI
vData = flip(flip(permute(vData,[3 2 1]),2),3);
mmPerVox = mmPerVox([3 2 1]);
xform = [diag(1./mmPerVox), size(vData)'/2; 0 0 0 1];

% Modern version - BW, October 2012
ni = niftiCreate('fname',outFileName,'qto_xyz',inv(xform), 'data', vData);

% ni.qto_xyz = inv(xform);
% ni.qto_ijk = xform;
% ni.sto_xyz = inv(xform);
% ni.sto_ijk = xform;

niftiWrite(ni);

return

end

function [vData,mmPerVox] = readVAnat(vFile)

% set this to nan's in case the vAnatomy is old-style, in which
% case it won't have mmPerPix in the header.
mmPerVox = [nan,nan,nan];
volSize = [nan,nan,nan];

fid = fopen(vFile);
% read header: volSize and mmPerPix (if available)
tmp = fscanf(fid,'rows %f (%f mm/pixel)\n');
volSize(1) = tmp(1);
if length(tmp)>1, mmPerVox(1) = tmp(2); end
tmp = fscanf(fid,'cols %f (%f mm/pixel)\n');
volSize(2) = tmp(1);
if length(tmp)>1, mmPerVox(2) = tmp(2); end
tmp = fscanf(fid,'planes %f (%f mm/pixel)\n');
volSize(3) = tmp(1);
if length(tmp)>1, mmPerVox(3) = tmp(2); end

% Check that this is a valid header for a vAnatomy file. The next line should be '* \n'
endOfHeader = '*';
nextLine = fgets(fid);
if ~(length(nextLine)>=2 && nextLine(1)==endOfHeader)
    myErrorDlg(['vAnatomy file: ',vFile,' has invalid header']);
end

% If mmPerPix was not in the vAnatomy header, try to get it from UnfoldParams
if(isnan(mmPerVox(1)) || isnan(mmPerVox(2)) || isnan(mmPerVox(3)))
    % Try to get the voxel size from the old UnfoldParams.mat file.
    % warning('volume_pix_size not available. Try to get it from the old UnfoldParams file.');
    eval('ufp = load(fullfile(fpath,''UnfoldParams.mat''));', 'ufp = [];');
    if(isfield(ufp, 'volume_pix_size'))
        mmPerVox = 1./ufp.volume_pix_size;
    else
        % Error: can't find mmPerPix
        %myErrorDlg('Can not determine volume voxel size. You need to create an UnfoldParams file.');
        % Display a warning and carry on:
        disp('Warning : Can not determine volume voxel size. Setting to 1x1x1mm.');
        mmPerVox=[1 1 1];
    end
end

% read volume
vData = fread(fid,prod(volSize),'uint8');
fclose(fid);

% *** HACK!  Sometimes the vAnatomy is missing the last byte (???)
if length(vData) == prod(volSize)-1
    vData(end+1) = 0;
end

% Return vData permuted to maintain correct orientations. The old way was
% very inefficient.
vData=reshape(vData,[volSize(2),volSize(1),volSize(3)]);
vData=double(permute(vData,[2,1,3])); % This double cast is required for routines that expect readVolAnat to return a double.

end