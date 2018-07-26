function replyAction = mrMeshReplyHandler(mesh_reply, mrMeshPyID)
%function replyAction = mrMeshReplyHandler(mesh_reply, mrMeshPyID)
%
% This function processes replies from the mrMeshPy TCP server and takes
% action according to the response received

disp('running reply handler');

if strcmp(char(mesh_reply), 'Mesh smooth failed')
    choice = questdlg(['No mesh with ID ',mrMeshPyID,'? - shall I try reloading it?'], ...
        'Missing Mesh ', ...
        'Yes - try reload','No - Cancel','No - Cancel');
    % Handle response
    switch choice
        case 'Yes - try reload'
            replyAction = 101; %TODO 101 indicates a reload??
        case 'No - Cancel'
            replyAction = 0;
    end

elseif strcmp(char(mesh_reply), 'Mesh update failed')
    choice = questdlg(['No mesh with ID ',mrMeshPyID,'? - shall I try reloading it?'], ...
        'Missing Mesh ', ...
        'Yes - try reload','No - Cancel','No - Cancel');
    % Handle response
    switch choice
        case 'Yes - try reload'
            replyAction =  101; %TODO 101 indicates a reload??
        case 'No - Cancel'
            replyAction = 0;
    end
else
    disp('No handler for this reply yet.. continuing.');
    replyAction = 0;
end