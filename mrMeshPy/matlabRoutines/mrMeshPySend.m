function myOutput = mrMeshPySend(the_command, the_data)
% function myOutput = mrMeshPySend(the_command, the_data)
% 
% 
% This module interprets the commands sent from mrVista output to 
% mrMeshPy (python) through the mrMeshPyServer .. 
% 
% Matlab sends a string in one transaction giving a command to the 
% visualisation module. This command either performs an explicit
% function in the viewer (e.g. rotate the camera 90 degrees) or the
% commnd describes the configuration/content of a large data chunk to
% will be sent in the subsequent transaction so that we know how to
% unpack the data, and how to process it (e.g. 70,000 floating point
% numbers which are scalar values to show as an amplitude map. 
% 
% N.B. - currently command strings have a maximum length of 1024 bytes.
% 
% Commands are specifically ordered, semi-colon seperated strings which are 
% unpacked to describe what the user is trying to do / send from matlab.
% Commands have a MINIMUM LENGTH of 6 arguments and have the following 
% structure and item order (zero-indexed)
% 
% 0 - "cmd"  -- always this, identifies it as a cmd :)
% 1-3 -- place holders for later faetures
% 4 - commandName - should match a command in mp_Commands file
% 5 - theMeshInstance - integer pointing to the the mesh window that we
%             want to operate on
% 6 onwards - commandArgs - a list of comma-separated pairs of arguments 
%             to characterise the processing of the incoming data
%             blob or apply some settings to the viewport -
%             CAN BE EMPTY but must be set to []
% 
% 
% Andre' Gouws 2017

%% new mesh
if strcmp(the_command, 'sendNewMeshData') == 1
    
    % get the target mesh from the VOLUME
    VOLUME{1} = the_data(1);
    msh = VOLUME{1}.mesh{VOLUME{1}.meshNum3d}; % expects a mesh (msh) structure
    
    % send the new vertices as a vector ([x1 y1 z1 x2 y2 z2 ..... xn yn zn])
    verticesVector = reshape(msh.vertices,1,size(msh.vertices,1)*size(msh.vertices,2));
    verticesLength = size(verticesVector,2);
    
    % send the new vertices as a vector ([t1a t1b t1c t2a t2b t2c ..... tna tnb tnc])
    trianglesVector = reshape(msh.triangles,1,size(msh.triangles,1)*size(msh.triangles,2));
    trianglesLength = size(trianglesVector,2);
    
    
    currColors = uint8(msh.colors);
    
    % ---- set up the TCP command -- working example ----------------------
    
    % now that we have all the data we need lets generate a TCP command
    % that mrMeshPy can interpret - the server will be expecting the
    % command in a specific format that a wrapper script can generate for
    % us if we pass it a struct of commands/args as below
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'loadNewMesh'; % a command listed in mrMeshPyCommandsList.m
    theCommandStruct.TargetMeshSession = msh.mrMeshPyID; % function to create unique ID based on system clock
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want
    
    % set up the first extra arg: mrMeshPy will be expecting a data blob
    % called "vertices" of double type ("d") of length "verticesLength"
    % NB a command argument set is single string with commas to separate
    % different components of the argument
    theCommandStruct.Args{1} = ['vertices,d,',num2str(verticesLength)];
    
    % 3rd set of arguments- same logic as Arg1 above
    theCommandStruct.Args{end+1} = ['triangles,d,',num2str(trianglesLength)];
    
    % mrMeshPy will be expecting a data blob of R values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['r_rgb,B,',num2str(length(currColors(1,:)))];
    
    % mrMeshPy will be expecting a data blob of G values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['g_rgb,B,',num2str(length(currColors(2,:)))];
    
    % mrMeshPy will be expecting a data blob of B values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['b_rgb,B,',num2str(length(currColors(3,:)))];
    
    % mrMeshPy will be expecting a data blob of B values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['a_rgb,B,',num2str(length(currColors(4,:)))];
    
    % get our wrapper to generate our command for us
    initialTCPCommand = createMrMeshPySendTCPCommand(theCommandStruct)
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 20);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([initialTCPCommand]));
    
    % write the data that will be processed based on the previous command
    write(t,verticesVector);
    write(t,trianglesVector);
    write(t,currColors(1,:));
    write(t,currColors(2,:));
    write(t,currColors(3,:));
    write(t,currColors(4,:));
    
    mesh_reply = read(t);
    while isempty(mesh_reply)
        mesh_reply = read(t);
        disp 'waiting'
        pause(0.1);
    end
    
    disp(char(mesh_reply));


%% smooth existing mesh    
elseif strcmp(the_command, 'smoothMesh') == 1
    %simple smoothing routine
    
    %the_data
    
    targetMesh = the_data{1};
    iterations = the_data{2};
    relaxationfactor = the_data{3};
    
    VOLUME{1} = the_data{4}; %place in scope in case we need a re-synch
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'smoothMesh'; % a command listed in mrMeshPyCommandsList.m
    theCommandStruct.TargetMeshSession = targetMesh; % BIG change here - string identifier now
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want
    
    theCommandStruct.Args{1} = ['iterations,',num2str(iterations),',relaxationfactor,',num2str(relaxationfactor)];
    
    % get our wrapper to generate our command for us
    initialTCPCommand = createMrMeshPySendTCPCommand(theCommandStruct)
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 20);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([initialTCPCommand]));
    
    % done! - no extra data blob to send here!
    
    mesh_reply = read(t);
    while isempty(mesh_reply)
        mesh_reply = read(t);
        disp 'waiting'
        pause(0.1);
    end
    
    disp(char(mesh_reply));

    actionToTake = mrMeshReplyHandler(mesh_reply, targetMesh);
    
    if actionToTake == 101 %reload required
        mrMeshPySend('sendNewMeshData',VOLUME{1});
    end
    
    %% TODO - auto-remap the colour data?
    % we do however need to make sure we re-map the correct colors to their
    % corresponding vertices - this gets screwed up in the smoothing
    %mrMeshPySend('updateMeshData',currView);
    

%% update the currently displayed data on the mesh to reflect the VOLUME 
%  view
elseif strcmp(the_command, 'updateMeshData') == 1
    % TODO - description
    
    currView = the_data; % expects a View structure
    
    try
        newColors = uint8(currView.mesh{currView.meshNum3d}.currentColors);
    catch
        disp 'here'
        pause;
        newColors = uint8(currView.mesh{currView.meshNum3d}.colors);
    end
    
    currScanNum = currView.curScan; % TODO needed?
    currOverlayType = currView.ui.displayMode; % TODO needed?
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'updateMeshData'; % a command listed in mrMeshPyCommandsList.m
    currMesh = currView.meshNum3d; % keep track of current / apt / target mesh
    theCommandStruct.TargetMeshSession = currView.mesh{currMesh}.mrMeshPyID; % unique string id  for this mesh
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want
    
    % mrMeshPy will be expecting a data blob of R values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['r_rgb,B,',num2str(length(newColors(1,:)))];
    
    % mrMeshPy will be expecting a data blob of G values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['g_rgb,B,',num2str(length(newColors(2,:)))];
    
    % mrMeshPy will be expecting a data blob of B values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['b_rgb,B,',num2str(length(newColors(3,:)))];
    
    % mrMeshPy will be expecting a data blob of B values for the colour
    % lookup table
    theCommandStruct.Args{end+1} = ['a_rgb,B,',num2str(length(newColors(4,:)))];
    
    
    % get our wrapper to generate our command for us
    initialTCPCommand = createMrMeshPySendTCPCommand(theCommandStruct)
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 20);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([initialTCPCommand]));
    
    % write the data that will be processed based on the previous command
    write(t,newColors(1,:));
    write(t,newColors(2,:));
    write(t,newColors(3,:));
    write(t,newColors(4,:));
    
    mesh_reply = read(t);
    while isempty(mesh_reply)
        mesh_reply = read(t);
        disp 'waiting'
        pause(0.1);
    end
    
    actionToTake = mrMeshReplyHandler(mesh_reply, currView.mesh{currMesh}.mrMeshPyID);
    
    if actionToTake == 101 %reload required
        mrMeshPySend('sendNewMeshData',currView);
    end

    
%% get an roi drawn on the mesh back into matlab
elseif strcmp(the_command, 'checkMeshROI') == 1
    % extract a set of ROI vertices from mrMeshPy as long as one is ready
    
    currView = the_data % expects a View structure
    currMesh = currView.meshNum3d; % keep track of current / apt / target mesh
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'checkMeshROI'; % a command listed in mrMeshPyCommandsList.m
    theCommandStruct.TargetMeshSession = currView.mesh{currMesh}.mrMeshPyID; % unique string pointing to vtk session
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want
    
    % get our wrapper to generate our command for us
    initialTCPCommand = createMrMeshPySendTCPCommand(theCommandStruct);
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 10);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([initialTCPCommand]));
    
    % wait til the server returns something before moving on
    mesh_reply = read(t);
    while isempty(mesh_reply)
        mesh_reply = read(t);
        disp 'waiting'
        pause(0.1);
    end
    
    disp(char(mesh_reply));

    
    % TODO add timeout?
    
    disp(['Got response - ', mesh_reply]);
    assignin('base','reply',mesh_reply);
    
    % unpack the
    if strcmp(char(mesh_reply(1:8)),'RoiReady')
        replyStr = char(mesh_reply);
        replyArgs = strsplit(replyStr,',')
    else
        disp('Error: No ROI data received? ...')
        return
    end
    
    % get ready to receive data
    incomingDataType = replyArgs{2};
    incomingDataCount = str2num(replyArgs{3});
    
    if strcmp(incomingDataType, 'double')
        expectedBytes = incomingDataCount*8 % 8 bytes per double
    else
        disp('Error: No ROI data received? ...')
        return
    end
    pause(1.0);
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'sendROIVertices'; % a command listed in mrMeshPyCommandsList.m
    theCommandStruct.TargetMeshSession = currView.mesh{currMesh}.mrMeshPyID; % unique string pointing to vtk session
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want% tell meshPy we're ready for the vertices
    
    % get our wrapper to generate our command for us
    TCPCommand = createMrMeshPySendTCPCommand(theCommandStruct);
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 100);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([TCPCommand]));
    
 
    reply = read(t, expectedBytes)
    while isempty(reply)
        reply = read(t, expectedBytes);
        disp 'waiting'
        pause(0.1);
    end
    
    %debug
    assignin('base','reply',reply);
    
    vertices = typecast(uint8(reply), 'double');
    vertices = uint32(vertices) + 1;
    
    
    
    %% TODO layer 1 only code?
% % %     verts = adjustPerimeter(vertices, [], currView)';
% % %     msh = currView.mesh{currMesh}
% % % 
% % %     vert = meshGet(msh,'initialVertices');
% % %     coords = vert([2 1 3],vertices);
% % %     for ii=1:3,
% % %         coords(ii,:) = coords(ii,:)./msh.mmPerVox(ii); 
% % %     end
% % %     coords = round(coords);
    
    
    %% currently support "all layers" mode only
    verts = adjustPerimeter(vertices, [], currView)';
    
    msh = currView.mesh{currMesh}    
    grayInds = msh.vertexGrayMap(1,verts);
    curLayer = unique(grayInds(grayInds>0));
    allLayers = curLayer;
    nodes = viewGet(currView, 'nodes');
    edges = viewGet(currView, 'edges');
    curLayerNum = 1;
    while(~isempty(curLayer))
        nextLayer = [];
        curLayerNum = curLayerNum+1;
        for ii=1:length(curLayer)
            offset = nodes(5,curLayer(ii));
            if offset>length(edges), continue; end
            numConnected = nodes(4,curLayer(ii));
            neighbors = edges(offset:offset+numConnected-1);
            nextLayer = [nextLayer, neighbors(nodes(6,neighbors)==curLayerNum)];
        end
        nextLayer = unique(nextLayer);
        allLayers = [allLayers, int32(nextLayer)];
        curLayer = nextLayer;
    end
    coords = currView.coords(:,allLayers);

    % user dialog to name the incoming ROI
    
    prompt={'Enter a name for the ROI:'};
    name='Incoming ROI name';
    numlines=[1,100];
    defaultanswer={'ROI_new'};
    options.Resize='on';
    options.WindowStyle='normal';
    options.Interpreter='tex';
    
    roiName = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(roiName)
        roiName = 'ROI_new';
    else
        roiName = roiName{1};
    end
    
    currView = newROI(currView,roiName,1,[],coords);
    [currView,~,~,~,currView.mesh{currView.meshNum3d}] = meshColorOverlay(currView,0);
    mrMeshPySend('updateMeshData',currView);
    
    % return
    myOutput = currView;
    

%% a simple animation test
elseif strcmp(the_command, 'rotateMeshAnimation') == 1
    
    
    %data - rotate 90 steps, 4 degrees at a time
    rotations = ones(1,90.0)*4;
    
    % ---- set up the TCP command
    
    theCommandStruct = struct('cmdIdentifier','cmd'); %always start a command with this
    theCommandStruct.CommandToSend = 'rotateMeshAnimation'; % a command listed in mrMeshPyCommandsList.m
    theCommandStruct.TargetMeshSession = the_data - 1; % integer pointing to target mrMeshypy sub-window, minus one for zero-index in python
    theCommandStruct.Args = {}; % we will use a cell array to pass all the extra arguments we want
    
    % set up the first extra arg: mrMeshPy will be expecting a data blob
    % called "vertices" of double type ("d") of length "verticesLength"
    % NB a command argument set is single string with commas to separate
    % different components of the argument
    theCommandStruct.Args{1} = ['rotate,d,',num2str(length(rotations))];
    
    % get our wrapper to generate our command for us
    initialTCPCommand = createMrMeshPySendTCPCommand(theCommandStruct);
    
    %open the port
    t = tcpclient('localhost', 9999, 'Timeout', 20);
    
    % write our initial setup / staging command that explains what's coming
    % in the following transactions
    write(t,uint8([initialTCPCommand]));
    
    % write the data that will be processed based on the previous command
    write(t,rotations);
    
    %% wait til the server returns something before moving on - TODO - get some useful info back from server not just junk
    y = read(t);
    while isempty(y)
        y = read(t);
        disp 'waiting'
        pause(0.1);
    end
    y

%% or else the command is not recognised
else 
    disp 'ERROR: Matlab generated a command that is not recognised - not sending!!'

end


