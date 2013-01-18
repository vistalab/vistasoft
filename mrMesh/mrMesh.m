function [id,status,resp] = mrMesh(host, id, command, params)
%Client routine that communicates with mrMesh Server
%
%  [id,status,resp] = mrMesh(host, id, command, params)
%
% This function is a drop-in replacement for the mrMesh mex client.
% The main advantage of this function over the original mrMesh is that
% the core protocol logic is in a more accessible and readable form and
% the only mex file that it depends on (pnet) is *much* easier to
% compile (see pnet.c in Anatomy/mrMesh/tcpToolbox).
%
% For some help with the commands that the mrMesh server might
% respond to, see mrMesh_help.m.
%
% Note that you can run mrMeshSrv and matlab on different machines.
% For optimal performance, you'd want to run mrMeshSrv on your local
% machine while matlab is running on a remote compute server. The easiest
% way to do that is to forward port 3000 with ssh. From the local machine
% (the one running mrMeshSrv), run this command:
%
%   ssh username@remote.matlab.host -R 3000:localhost:3000
%
% DEPENDS ON:
%  the pnet TCP/IP toolbox from Peter Rydesäter (from the MathWorks file
%  exchange; a version is also included in Anatomy/mrMesh/tcpToolbox).
%
% HISTORY
% 2007.04.12 RFD wrote it.
% 2007.05.08 RFD: fixed it and renamed to mrMesh.m.
%
% (c) Stanford VISTA Team

%!/silver/scr1/cvs/VISTASOFT/Anatomy/mrMesh/mrMeshSrv.glx &

if(~exist('host','var') || isempty(host)), host = 'localhost'; end
if(~exist('id','var')   || isempty(id)),   id = -1;            end
sc = strfind(host,':');

if(isempty(sc)),    port = 3000;
else
    port = str2double(host(sc(1)+1:end));
    host = host(1:sc(1)-1);
end
maxPacketSize = 1024*1024;

if(~exist('params','var')),  params = []; end

con = pnet('tcpconnect',host,port);
if(pnet(con,'status') < 1)
    disp('Can''t establish connection to mrMeshSrv.');
    id = -1000;  % Indicator of a bad connection.
    status = 0;
    resp = 'oops';
    return;
end


%% Send the handshake and make sure we get the right response
%
% handshake.hello = zeros(1,32,'uint8');
% handshake.reserved = zeros(1,32,'uint8');
% handshake.id = int32(id);
msg = [zeros(1,32,'uint8'), zeros(1,32,'uint8'), typecast(int32(id),'uint8')];
if(~pnet_writeMsg(con,msg))
    pnet(con,'close');
    error('Error sending handshake.');
end

% Expected server reply: [(int) id, (int) status, char[24] reserved])
msg = pnet_readMsg(con);
if(length(msg)~=32)
    pnet(con,'close');
    error('Error receiving handshake reply.  Message length %d\n',length(msg));
end

id = typecast(msg(1:4),'int32');
srvReply.status = typecast(msg(5:8),'int32');
srvReply.reserved = char(msg(9:end));
if(srvReply.status<0)
    pnet(con,'close');
    error('Handshake status failure. Server reply status is %d\n',srvReply.status);
    % status = srvReply.status;
end

%% Send the client header, command and parameters
%
% Client header: [(int) cmd_len, (int) params_len, char[24] reserved]]
pMsg = mrMeshTcpSerializeParams(params);
pLen = length(pMsg);

% NULL-terminate the command string
command(end+1) = 0;

% Build & send the header bytestream
hdrMsg = [typecast(int32(length(command)),'uint8') typecast(int32(pLen),'uint8') zeros(1,24,'uint8')];
if(~pnet_writeMsg(con, hdrMsg))
    pnet(con,'close');
    error('Error sending client header.');
end

%% Now send the command as a simple string
if(~pnet_writeMsg(con, command))
    pnet(con,'close');
    error('Error sending command data.');
end

%% Send the serialized params, if there are any
if(pLen>0)
    % Do "send in parts" to avoid tcp/ip stack space issues
    nPackets = ceil(pLen./maxPacketSize);
    for(ii = (0:(nPackets-1)))
        indStart = (ii*maxPacketSize) + 1;
        nBytesLeft = pLen - (ii*maxPacketSize);
        if(nBytesLeft < maxPacketSize)
            indEnd = indStart + nBytesLeft - 1;
        else
            indEnd = indStart + maxPacketSize - 1;
        end
        if(~pnet_writeMsg(con, pMsg(indStart:indEnd)))
            pnet(con,'close');
            error('Error sending parameters.');
        end
    end
end

%% Read the server reply header
% Server header: [(int) status (int)data_length]
msg = pnet_readMsg(con);
if(length(msg) ~= 8)
    %pnet(con,'close');
    warning('Error receiving server reply header.');
    numDataBytes = 0;
else
    status = typecast(msg(1:4),'int32');
    numDataBytes = typecast(msg(5:8),'int32');
end
if(numDataBytes>0)
    % Do "receive in parts", if needed
    msg = pnet_readMsg(con);
    done = false;
    while(numDataBytes>maxPacketSize&&length(msg)<numDataBytes&&~done)
        tmp = pnet_readMsg(con);
        if(isempty(tmp))
            done = true;
        else
            msg = [msg tmp];
        end
    end
    % Apparently, numDataBytes is often wrong, but things parse OK anyway.
    %if(length(msg)~=numDataBytes)
    %  pnet(con,'close');
    %  error('Error receiving server data block.');
    %end
    resp = mrMeshTcpParseResponseData(msg);
else
    resp = [];
end

pnet(con,'close');

return

%% Some old debugging

%iCommandLen = length(command);
%iParamsLen = p->currentLength + 1;
%client_header.command_length = iCommandLen + 1;
%client_header.params_length = iParamsLen;
%memset(client_header.reserved, 0, sizeof(client_header.reserved));
%m_sock->WriteMsg (&client_header, sizeof(client_header));
%if (m_sock->Error()){ printf ("Error writing client header\n");break; }
%m_sock->WriteMsg(pCommand, client_header.command_length);
%if (m_sock->Error()){ printf ("Error sending command data\n"); break;}
%if (iParamsLen){
%     //m_sock->WriteMsg(p->data, client_header.params_length);
%     bool bRes = SendInParts(m_sock, p->data, client_header.params_length);
%     if (!bRes){ printf ("Error sending parameters\n"); break; }
%}
%m_sock->ReadMsg(&server_header, sizeof(server_header));
%if (m_sock->Error()){ printf ("Error getting server message header\n"); break;}
%if (verbose_out) printf ("Received status = %d\n", server_header.status);
%*status = server_header.status;
%if (server_header.data_length){
%   char *pData = new char[server_header.data_length + 8];
%   //m_sock->ReadMsg (pData, server_header.data_length);
%   bool bRes = ReceiveInParts(m_sock, pData, server_header.data_length);
% if (!bRes){
%   printf ("Error getting server data block\n");
%   delete[] pData;
%   break;
%}
%if (verbose_out) printf ("\nReceived data block:\n%s\n\n", pData);
%ProtocolParser::Parse (&plhs[2], pData);
%params_assigned = true;
%delete[] pData;
%}else{ if (verbose_out) printf ("No response data\n"); }
%if (!params_assigned)
%ProtocolParser::Parse (&plhs[2], "");



