function [pathStr] = getvAnatomyIfilePath(subject)

% getvAnatomyIfilePath - Returns the path of a given subject's vAnatomy Ifiles.
%
%   Usage: [pathStr] = getvAnatomyIfilePath(subjectName)
%
%   Sunjay Lad - 7.15.2002 (largley based on getvAnatomyPath by Press and DJH)

global HOMEDIR

% Based on the subject, tries to automatically locate the anatomy path 
prefixStr = getAnatomyPath(subject);
pathStr = fullfile(prefixStr,'Ifiles');

% If path doesn't exist then prompt user to find Ifile path by specifying the location of Ifile I.001
if ~exist(pathStr,'file')
    disp(['Select Ifile I.001 from ',subject,'''s vAnatomy']);
    [fname,pathStr] = uigetfile('*.*',['Select Ifile I.001 from ',subject,'''s vAnatomy']);
    
    % checks to make sure Ifile I.001 was specified
    if ~strcmp(fname,'I.001')
        error('Ifile I.001 not specified.  Unable to locate vAnatomy Ifiles.');
    end
    
    % checks to make sure the file specified was a vAnatomy Ifile and not an inplane Ifile   
    if strcmp(fullfile(pathStr,''), fullfile(HOMEDIR,'Raw','Anatomy','Inplane\'))
        error('Please specify the vAnatomy Ifiles not the inplane Ifiles.');
    end    
    
end

% If path still doesn't exist, then error
if ~exist(pathStr,'file')
    error('No vAnatomy Ifile directory found.')
end
