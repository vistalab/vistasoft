function mc_AddComments
% function mc_AddComments
%
% Provides an interface for adding user comments to Readme file
%
% djh, 9/4/01
% ras, 6/17/03 (from createReadmeAppendNotes)

    
% Dialog box to input comments
pos = [200 400 450 200];
topH = figure(...
    'MenuBar', 'none', ...
    'Name', 'Any other comments about this session?', ...
    'NumberTitle','off', ...
    'UserData', '', ...    
    'Position', pos ...
    );

% Create the comments field:
labelPos = [0.05 0.2 0.9 0.8];
h = CreateCommentsField(labelPos, topH, 12);

% if a Readme.txt already exists, read it to get existing comments:
if exist('Readme.txt');
    info = readReadme;
    set(h,'String',info.comments);
end

% install the file-control buttons
bpos = [0.1 0.05 0.2 0.1];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Accept', ...
    'Units','Normalized',...
    'HorizontalAlignment', 'center', ...
    'Callback', 'uiresume', ...
    'FontSize', 14, ...
    'Position', bpos ...
    );

% Wait until we get a uiresume, then perform an update. Repeat
% this cycle until the update reports no errors.
ok = 0;
while ~ok
  uiwait(topH);
    ok = 1;
end

% Get comments
A = get(h,'String');
close(topH);

% Append to Readme.txt
[fid, message] = fopen('Readme.txt','a');
if fid == -1
    warndlg(messsage);
    return
end

for line = 1:size(A,1)
    wcount = fprintf(fid,'%s\n',A(line,:));
end

status = fclose(fid);
if status == -1
    warndlg(messsage);
    return
end
