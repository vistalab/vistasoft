function segmentInfo(view);
%
% AUTHOR:  Wandell
% DATE:    01.09.01
% PURPOSE:
%   Read the file paths for the current set of segmentation files.
% Then display this information to the user
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH
% 11/4/07 ras, added class files to Gray view; for Inplane/other views,
% looks for a gray/coords file and reports on that as well.

% Path to the anatomy data
global vANATOMYPATH

switch view.viewType
case 'Gray'
    msg = sprintf(['Anatomy\n  %s\n\nGray Graph:\n  left:   %s\n  right: %s' ...
				   '\n\nClassification Files:\n  left:   %s\n  right: %s\n'], ...
					vANATOMYPATH, view.leftPath, view.rightPath, ...
					view.leftClassFile, view.rightClassFile);
case 'Flat'
    msg = sprintf('Anatomy\n  %s\nFlat:\n  left:   %s\n  right: %s\n',...
        vANATOMYPATH, view.leftPath, view.rightPath);
otherwise
    msg = sprintf('Anatomy\n  %s\n', vANATOMYPATH);
	
	% check if the gray coords.mat file exists; if so, load it and report
	% on that info. Otherwise, tell the user it's not installed
	global HOMEDIR
	grayFile = fullfile(HOMEDIR, 'Gray', 'coords.mat');
	if check4File(grayFile)
		load(grayFile, 'leftPath', 'rightPath', 'leftClassFile', 'rightClassFile');
		
		m2 = sprintf(['Anatomy\n\n  %s\nGray Graph:\n  left:   %s\n  right: %s' ...
			   '\nClassification Files:\n  left:   %s\n  right: %s\n'], ...
				vANATOMYPATH, leftPath, rightPath, ...
				leftClassFile, rightClassFile);
			
		msg = [msg m2];
		
	else
		msg = [msg sprintf('\n\n ** No Segmentation Installed **')];
		
	end

end

% Popup the box with the information
msgbox(msg,'Segmentation Information')
disp(msg)
return;
