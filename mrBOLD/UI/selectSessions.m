function sessions = selectSessions(studyDir,nSessions);
%
% sessions = selectSessions(studyDir,[nSessions]);
%
% Select multiple sessions. studyDir is the path
% to the "study", i.e., the path where most sessions
% are kept. Defaults to the parent of pwd. Also provides
% the option to manually select different sessions, if
% they're located all over the place, using uigetmanydirs.
%
% Returns a cell containing full path to each session.
%
% I wrote this on top of uigetmanydirs b/c I found that
% interface to be pretty slow and annoying (the default
% uigetdir for windows is always low and cut-off on my 
% machine), plus I usually keep my session folders in one
% place anyway.
%
% nSessions: optional argument specifying # of 
% sessions to select. If omitted or 0, takes
% all selected. Otherwise, takes first nSessions.
%
% ras 03/05
if notDefined('studyDir')
    studyDir = fileparts(pwd);
end

if notDefined('nSessions')
    nSessions = 0;
end

sessions = [];

% get names of directories
w = dir(studyDir);
names = {w.name};
dirCheck = [w.isdir];
names = names(dirCheck==1); % only dirs
names = setdiff(names,{'.' '..'});

% first option will be to manually locate sesions
% outside the guessed study dir
names = [{'(Find Other Session)'} names];

[whichSessions, ok] = listdlg('PromptString','Use coords from which sessions?',...
                        'ListSize',[400 600],...
                        'ListString',names,...
                        'InitialValue',1,...
                        'OKString','OK');
if ~ok  return;  end

% if subject requested to find other session, allow to
% add that to list:
if ismember(whichSessions,1)
    if nSessions==1
        while 1
            sess = uigetdir(pwd, 'Select a session to import');
            if exist(fullfile(sess, 'Gray', 'coords.mat'), 'file')
                sessions = {sess};
                break;
            else
                h = warndlg(['Selected session doesn''t have a ' ...
                           'Gray/coords.mat file. Please choose again.']);
                set(h, 'CloseRequestFcn', 'uiresume; closereq; ');
                uiwait
            end
        end
    else
        sessions = uigetmanydirs('Gray/coords.mat');
    end
end

% also get any selected from the listdlg, and add the 
% parent dir to get a full path:
sessInds = whichSessions(whichSessions>1);
tmpSessions = names(sessInds);
for i = 1:length(tmpSessions)
    tmpSessions{i} = fullfile(studyDir,tmpSessions{i});
end
sessions = [sessions tmpSessions];

if nSessions > 0
    nSessions = min(length(sessions),nSessions);
    sessions = sessions(1:nSessions);
end

return