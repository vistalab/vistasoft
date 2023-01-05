function iktGray2mrGrayClass(niftiClassFile);
% Convert a NIFTI classification file into a set of mrGray-compatible class
% files, along with the mrGray directory structure.
%
%   iktGray2mrGrayClass([niftiClassFile=dialog]);
%
% This is an unfortauntely necessary step until the MEX code which grows gray
% matter from classification is fully debugged on all of the working MATLAB
% versions and OSes. (Some versions which run into problems are 2006a and
% 2006b on Windows, as well as sometimes 2008a on linux.)
%
% ras, 03/2009.
if notDefined('niftiClassFile')
	niftiClassFile = mrvSelectFile('r', 'nii.gz', 'Select a NIFTI classification file');
end

if ~exist(niftiClassFile, 'file')
	error('File %s not found.', niftiClassFile);
end

%% create the directory structure if needed
anatPath = fileparts(niftiClassFile);

ensureDirExists( fullfile(anatPath, 'Left') );
ensureDirExists( fullfile(anatPath, 'Right') );

ensureDirExists( fullfile(anatPath, 'Left', '3DMeshes') );
ensureDirExists( fullfile(anatPath, 'Right', '3DMeshes') );


%% create left .class file
left = readClassFile(niftiClassFile, 0, 0, 'left');
left.header.minor = 1;
writeClassFile(left, fullfile(anatPath, 'Left', 'Left.Class'));

%% create right .class file
right = readClassFile(niftiClassFile, 0, 0, 'right');
right.header.minor = 1;
writeClassFile(right, fullfile(anatPath, 'Right', 'Right.Class'));

%% TODO: try creating .gray graphs...

return
