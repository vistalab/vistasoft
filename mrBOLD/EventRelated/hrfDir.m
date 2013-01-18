function pth = hrfDir(subject);
%
% pth = hrfDir([subject]): 
%
% return the path to the directory where
% hemodyanmic response functions (HRFs) for
% the subject are stored.
%
% This is:
% [subject's anatomy path]/HRFs/
% 
% Makes it if it doesn't exist.
%
% ras, 06/05.
if ieNotDefined('subject')
    mrGlobals;
    if ~isempty(mrSESSION)
        subject = mrSESSION.subject;
    else
        subject = '';
    end
end

anatPath = fullpath(getAnatomyPath);
pth = fullfile(anatPath,'HRFs');

ensureDirExists(pth);

return
