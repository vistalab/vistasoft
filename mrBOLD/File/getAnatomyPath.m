function [anatPath,pathExists] = getAnatomyPath(subject, appendNameFlag)
%
% [anatPath,pathExists] = getAnatomyPath(subjectName, appendNameFlag)
%
% Gives the path to a given subject's anatomies.
%
% 2.26.99 - Written by Press
% djh, 2/15/2001 - modified to use fullfile
% huk 4/8/01 - fixed unix path (removed 'anatomy')
% pb 2/5/02 - added the last line to test (the function)
% 2003.09.02 RFD: nows checks global vANATOMYPATH and allows
% subject name to be inferred from mrSESSION.
% 2003.09.04 RFD: bug fix- return the path, *not* including
% the vAnatomy.dat filename, when using vANATOMYPATH.
% 2003.12.18  BW  Adjusted to use with mrFlatMesh, when no mrLoadRet
% exists.  Added defaultAnatomyPath internal call. Added check for
% existence of the anatomy directory and warning message if it does not
% exist.
%
% ras 10/06: recently we merged the process for getting paths between the
% various approaches that KGS lab, Alex, and others have taken. The
% solution is using the 'defaultAnatomyPath' preference. If you link to the
% directory (as we have done), we set this preference to the link name.
% However, one consequence of this is that we need to disable the
% whole 'defaultAnatomyPath/anatomy/subject' part. For one thing, a subject
% may have several segmentations; and the name the person enters during
% mrInitRet during the subject name shouldn't have to exactly match the
% name of the directory. Also, we happen not to use a directory named
% 'anatomy'; I don't think we should force all users to do this.
% ARW. 05/07 : But then why are we passing in a 'subject' at all? This
% function has now become a fancy way of checking the defaultAnatomyPath
% preference.
% The easiest way might be to return a path with no subject >if no subject name is passed in<.
% If you do pass a subject name in, we should assume that you want it appended to the output.
% I'm not going to implement that for now since I suspeect it would break other things in the VISTA codebase.
% But for some things I need a way of getting a subject's anatomy
% path so I've added in a flag in this function so that it >can< return the
% full path including the subject name and the 'anatomy' directory.
% I agree that there is still no way to cope with people who do not use the
% 'anatomy' directory convention. Oh well.
% examples:
% [anatPath]=getAnatomyPath('wade_newest')
% ans=/raid/MRI/
%[anatPath]=getAnatomyPath('wade_newest',1)
% ans=/raid/MRI/anatomy/wade_newest
if notDefined('subject'), subject = ''; end
if (ieNotDefined('appendNameFlag'))
	appendNameFlag=0; % By default, we will not append the name to the end.
end

global mrSESSION;
global vANATOMYPATH;

% When used outside of mrVista, we return a default value.
if isempty(mrSESSION)
	anatPath = defaultAnatomyPath(subject,appendNameFlag);
	pathExists = checkAnatomyPath(anatPath, nargout<2);
	return;
end

if notDefined('subject')
	if (isfield(mrSESSION, 'subject') && ~isempty(mrSESSION.subject))
		subject = mrSESSION.subject;
		%     else
		%         error('Can''t infer subject name from mrSESSION- please be more explicit.');
	end
end

if ~isempty(vANATOMYPATH)
	anatPath = fileparts(vANATOMYPATH);
else
	anatPath = '';
end

if ~exist(anatPath, 'dir')
	% try again, using the default value
	anatPath = defaultAnatomyPath(subject, appendNameFlag);
end

% We should check that the directory exists and print out a warning if it
% seems that there is trouble.
pathExists = checkAnatomyPath(anatPath, nargout<2);
return;

%--------------------------------------------
function anatPath = defaultAnatomyPath(subject,appendNameFlag)
%
% Set up the default anatomy paths, when no information is present, here
%
if (ispref('VISTA','defaultAnatomyPath'))
	anatPath=getpref('VISTA','defaultAnatomyPath');
	if ispref('VISTA', 'verbose') && getpref('VISTA', 'verbose')==1
		disp('Setting default anatomy base path to the one specified in the MATLAB preferences GROUP:VISTA, PREF: defaultAnatomyPath');
		disp(anatPath);
	end
else
    anatPath = '3DAnatomy'; %
end % endif preference is set

% ras 09/2006: see comments at top -- will remove this altogether if no one
% objects
if (appendNameFlag)
	anatPath = fullfile(anatPath,'anatomy',subject);
end

anatPath = fullpath(anatPath);

return;

%----------------------------------------------
function pathExists = checkAnatomyPath(anatPath,warnFlag)
pathExists = exist(anatPath,'dir')~=0;
if ~pathExists && warnFlag
	warnString=sprintf('Best guess at anatomy directory (%s) non-existent.',anatPath);
	warning(warnString);  %#ok<SPWRN,WNTAG>
end
return;
