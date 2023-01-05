function createReadmeAppendNotes
% function createReadmeAppendNotes
%
% Appends notes file(s) to Readme file. Loops, prompting 
% user for file pathnames until Cancel is selected.
% Called by mrCreateReadme.m
%
% djh, 9/4/01

for i=1:5
    
    % Dialog box to get notes file
    pathStr = getPathStrDialog(pwd,'Select notes to append to Readme.txt','*.*');
    if isempty(pathStr)
        return
    end
    
    % Read contents of notes file
    [fid, message] = fopen(pathStr,'r');
    if fid == -1
        warndlg(messsage);
        return
    end
    [A,rcount] = fread(fid,inf);
    status = fclose(fid);
    if status == -1
        warndlg(messsage);
        return
    end
    
    % Append to Readme.txt
    [fid, message] = fopen('Readme.txt','a');
    if fid == -1
        warndlg(messsage);
        return
    end
    wcount = fwrite(fid,A);
    if wcount ~= rcount
        warning(['createReadmeAppendNotes failed to append entire notes file, ',pathStr]);
    end
    status = fclose(fid);
    if status == -1
        warndlg(messsage);
        return
    end
end
