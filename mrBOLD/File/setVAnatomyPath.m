function pth = setVAnatomyPath(vANATOMYPATH)
% Set the volume anatomy path for a mrVista session, either by passing in
% the path as an argument, or through a dialog.
%
% pth = setVAnatomyPath(vANATOMYPATH);
%
%
%
% ras, 06/2008.
global HOMEDIR

% if no path, ask the user to select it
if notDefined('vANATOMYPATH')
	ext = {'*.nii.gz', 'Compressed NIFTI files'; ...
            '*.dat' 'mrGray .dat files'; ...		
            '*.*' 'All files'};
	pth = mrvSelectFile('r', ext, 'Select a Volume Anatomy', pwd);
	
	% try to be smart (in just this one important case):
	% if the HOMEDIR variable is part of the path,~ trim that out. 
	% The reason is this: if you link from a mrVista session to an anatomy
	% path, this link can be stable whether you access it from, say, a
	% linux box or a Windows box (despite the different path name
	% conventions). We want to keep this path relative, so we trim the
	% first part, and only include the link part.
	if ~isempty(HOMEDIR) && ~isempty(strfind(pth, [HOMEDIR filesep]))
		ii = strfind(pth, HOMEDIR);
		vANATOMYPATH = pth(ii + length(HOMEDIR) + 1:end);
    else 
        vANATOMYPATH = pth;
	end
	
else
	pth = vANATOMYPATH;
	
end

% save the results in mrSESSION, if that file exists:
mrSessPath = fullfile(HOMEDIR, 'mrSESSION.mat');
if exist(mrSessPath, 'file')
	save(mrSessPath, 'vANATOMYPATH', '-append');
	if prefsVerboseCheck
		fprintf('Updated %s with new vANATOMYPATH value: %s.\n', ...
				mrSessPath, vANATOMYPATH);
	end
end

return
