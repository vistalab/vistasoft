function cmdStringTCP = createMrMeshPySendTCPCommand(cmdStruct)
% function returnOutput = createMrMeshPySendCommand(cmdStruct)
% This function will generate a TCP compatible command string for use
% with the mrMeshPy interface
% 
%It requires a structure as input, with the following attributes:
%   cmdStruct.CommandToSend should be on of hte possible commands listed in
%               mrMeshPyCommandsList.m
%   cmdStruct.TargetMeshSession should be an integer pointing to the mesh
%               instance the command is referenced to
%   cmdStruct.Args is a cell array with a number of string in it: each
%               string is a comma-separated set of values or descriptors
%               and describe the data / actions mrMeshpy should expect in
%               the subsequent transactions
% Andre' Gouws 2017

% the code below incrementally builds a TCP command string from different
% command components - it may appear overkill to do it this way but I just
% wanted to be transparent about how the command is constructed for future
% developers

cmdString = 'cmd';  % all commands start with a 'cmd' here 
cmdString = [cmdString, ';']; % seperator

cmdString = [cmdString, 'None']; % a placeholder - we almost certainly forgot something obvious so lets leave a gap ;)
cmdString = [cmdString, ';']; % seperator

cmdString = [cmdString, 'd']; % a dataType placeholder - for the placeholder above ;)
cmdString = [cmdString, ';']; % seperator

cmdString = [cmdString, 'None']; % a data counter for the place holder above
cmdString = [cmdString, ';']; % seperator

% Place holders done, lets actually add our data to the string
cmdString = [cmdString, cmdStruct.CommandToSend]; % the command to send - must be in mrMeshPyCommandsList
cmdString = [cmdString, ';']; % seperator

% major change here -  no longer an instance number but a unique string
% identifier
cmdString = [cmdString, num2str(cmdStruct.TargetMeshSession)]; % unique identifier of mrMesh sub-window
cmdString = [cmdString, ';']; % seperator

% Process the extra arg strings by looping through our Arg cell array

for i = 1:length(cmdStruct.Args)
    cmdString = [cmdString, cmdStruct.Args{i}]; % instance number of mrMesh sub-window
    cmdString = [cmdString, ';']; % seperator
end

cmdStringTCP = cmdString;
