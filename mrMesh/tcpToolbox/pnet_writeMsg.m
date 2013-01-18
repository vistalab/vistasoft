function success = pnet_writeMsg(con, msg)
%
%    success = mrMeshTcpWriteMsg(con, msg)
%
% con: a pnet connection, message is an array of bytes(uint8).
%    connection is a pnet connection, message is an array of bytes (uint8).
% msg: the message to be sent to the connection
%
% Wrapper to emulate the wxWidgest WriteMsg function, which wraps the data
% bytes to be sent with a little header (hdr) and trailer (tlr)
%
% DEPENDS ON the pnet TCP/IP toolbox from  Peter Rydesäter(get it
% from the MathWorks file exchange).
%
% HISTORY
% 2007.04.12 RFD wrote it.

% Message
nb = typecast(uint32(length(msg)),'uint8');

% Header
hdr = [uint8(173) uint8(222) uint8(237) uint8(254) nb];
% Trailer
tlr = [uint8(237) uint8(254) uint8(173) uint8(222) uint8(0) uint8(0) uint8(0) uint8(0)];

pnet(con,'Write',[hdr msg tlr]);
if(pnet(con,'status')<=0)
  disp('ERROR connecting');
  success = 0;
else
  success = 1;
end

return

%% Bob notes

% Code snippet from wxWidgets/src/common/socket.cpp:
%  msg.sig[0] = (unsigned char) 0xad;
%  msg.sig[1] = (unsigned char) 0xde;
%  msg.sig[2] = (unsigned char) 0xed;
%  msg.sig[3] = (unsigned char) 0xfe;
%  msg.len[0] = (unsigned char) (nbytes & 0xff);
%  msg.len[1] = (unsigned char) ((nbytes >> 8) & 0xff);
%  msg.len[2] = (unsigned char) ((nbytes >> 16) & 0xff);
%  msg.len[3] = (unsigned char) ((nbytes >> 24) & 0xff);
%  _Write(&msg, sizeof(msg))
%  total = _Write(buffer, nbytes);
%  msg.sig[0] = (unsigned char) 0xed;
%  msg.sig[1] = (unsigned char) 0xfe;
%  msg.sig[2] = (unsigned char) 0xad;
%  msg.sig[3] = (unsigned char) 0xde;
%  msg.len[0] = msg.len[1] = msg.len[2] = msg.len[3] = (char) 0;
%  _Write(&msg, sizeof(msg))

