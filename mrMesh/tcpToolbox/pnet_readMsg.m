function msg = pnet_readMsg(con)
%
%  msg = mrMeshTcpReadMsg(con)
%
% Simple wrapper to emulate the wxWidgets socket ReadMsg function,
% which expectes the sent bytes to be wrapped with a little header
% and trailer.
%
% con is a pnet connection
%
% DEPENDS ON the pnet TCP/IP toolbox from Peter Rydesäter (get it
% from the MathWorks file exchange).
%
% HISTORY
% 2007.04.12 RFD wrote it.
% 2010.06.21 RFB - with permission, commented out error checking code on
%                  the payload and trailer
%
% (c) Stanford VISTA Team

msg = [];

% Don't wait forever before aborting:
if ispc, pnet(con,'setreadtimeout',4);
else     pnet(con,'setreadtimeout',2);
end

% The header and trailer are each 8 bytes long
hdr = pnet(con,'read',8,'char');
if(length(hdr)~=8)
  warning('could not read msg header.  Header length %d\n',length(hdr));
  return;
end
sig = uint8(hdr(1:4));
numMsgBytes = typecast(uint8(hdr(5:8)),'uint32');
msg = pnet(con,'read',numMsgBytes,'uint8');
%if(length(msg)~=numMsgBytes)
%  warning('PNET:incompleteData', 'could not read entire msg- data is likely corrupt!');
%  return;
%end
tlr = pnet(con,'read',8,'char');
%if(length(tlr)~=8)
%  warning('could not read msg trailer- data might be corrupt.');
%  return;
%end
return;
