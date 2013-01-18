function appendTextToReadme(comments, dlgFlag);
% function appendTextToReadme(<comments>, <dlgFlag=1>);
%
% Provides an interface for adding user com.ments to Readme file.
% If a string is entered for the 'comments' argument, uses that
% string as the default comments in the dialog. If the dialog flag 
% is set to 0 <default 1>, doesn't put up the dialog, and just writes the
% comments to the readme.
%
% djh, 9/4/01
% ras, 6/17/03 (from createReadmeAppendNotes)
% ras, 03/10/06: added input args
if notDefined('comments'),  comments = '';      end
if notDefined('dlgFlag'),   dlgFlag = 1;        end
    
if dlgFlag==1
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
    h = CreateCommentsField(labelPos, topH, 12, comments);
    
    
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
    comments = get(h,'String');
    close(topH);
end

% Append to Readme.txt
[fid, message] = fopen('Readme.txt','a');
if fid == -1
    warndlg(messsage);
    return
end

for line = 1:size(comments, 1)
    wcount = fprintf(fid,'%s\n', comments(line,:));
end

status = fclose(fid);
if status == -1
    warndlg(messsage);
    return
end

return
