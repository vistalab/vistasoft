function studies = studyLoad;
% Load a studies struct, specifying saved groupings of sessions for 
% mrVista 2.
% 
%  studies = studyLoad;
%
% STRUCTURE OF STUDIES VARIABLE:
%   studies is a struct array that is saved in the following path relative
%   to the root mrVista2 repository:
%       mrVista2/study/studies.mat
%   If this is not found, it creates and saves it, with a default "(Recent
%   Sessions)" study which keeps track of sessions viewed with the mrVista
%   2 session GUI.
%
%   Each entry in studies has the following fields
%       name: brief name of study.
%       sessions: set of paths to sessions contained within the study. Can 
%           be absolute paths, or relative to a parent directory (see
%           studyDir below). A cell array of strings.
%       studyDir: provides a parent directory for the study. If non-empty,
%           this could be a string that is evaluated. That is, it could be
%           a regular string, e.g., 'X:\myStudies\study1\', or a MATLAB
%           command that will evaluate to the path on the local machine,
%           e.g. 'fullfile(RAID, 'myStudies', 'study1');'. This allows
%           sessions to be accessed from multiple machines. If empty, 
%           will assume the sessions field contains absolute paths.
%           The studyDir field may also be useful for saving the results of
%           study-level analyses, across sessions.
%       params: a struct of parameters relevant to analyses specific to
%       this study. The details can vary depending on the study.
%       comments: string containing any comments about the study.
%
%
% ras 07/03/06.
parentDir = fileparts(which(mfilename)); % parent directory of this M-file.
studyPath = fullfile(parentDir, 'studies.mat');

if ~exist(studyPath, 'file')
    fprintf('Creating file %s which will contain saved study information...', ...
            studyPath);

    studies(1) = studyCreate('(Recent Sessions)');
    studies(1).sessions = {pwd};
    
    save(studyPath, 'studies');
    disp('Done.')
else
    load(studyPath, 'studies');
end

return


