function DICOM_fixMatlabBug
% When a DICOM I/O bug comes up, run this code once to fix.
% 
% Details: Matlab's own DICOM toolbox is obviously written for Siemens
% scanner images. When running on GE images, it occassionally comes up with
% bugs. However, because the matlab source code is hidden in a private
% directory, we have to copy the file in VISTASOFT folder into that private
% directory, in order to overwrite the Matlab's problematic source code.
%
% Hence, this fixbug code may need to be expanded in the future if more
% bugs come up.
% 
% Junjie Liu 2004/01/23
% 2004.04.08 Bob Dougherty: added check for pc- otherwise, this throws an
% error on linux due to file permissions.
% 2006.05.05 RFD: now politely backs up the original file. Is this patch
% still needed?
% 2006.05.22 RFD: disabled this fix- it's probably not needed and actually
% causes problems on newer matlabs.

matlabDir = fileparts(which('dicomread'));
if isempty(matlabDir);
    disp('Matlab version needs to be >6.5 to get DICOM toolbox');
    disp('In Linux please run matlab651 manually');
    error('dicomread function not found in Matlab. Your Matlab version is too old!');
end
% if(ispc)
%     matlabDir = fullfile(matlabDir,'private');
% 
%     fixedDir = fileparts(which('DICOM_fixMatlabBug'));
% 
%     disp('Overwritting your Matlab DICOM toolbox to fix possible bugs...');
% 
%     fixedFile = fullfile(fixedDir,'dicom_read_attr.m');
%     matlabFile = fullfile(matlabDir,'dicom_read_attr.m');
%     [success message] = copyfile(matlabFile, fullfile(matlabDir,'dicom_read_attr_ORIGINAL.m'));
%     if(~success) warning(message); return; end;
%     [success message] = copyfile(fixedFile,matlabFile);
%     if ~success, warning(message); return; end;
%     disp('Overwritting Successful!');
% else
%     disp('Please ensure that your installation of matlab has been patched.');
% end
return;

