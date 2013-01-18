function rtNewSession;
%
% rtNewSession: Make a new mrVista session,
% with inplanes but without any functional
% scans yet, for pseudo-realtime.
%
%
% ras 05/05
mrGlobals;
mrSESSION = mrvMakeEmptySession;
dataTYPES.name = 'Original';
mrSESSION.inplanes = rtGetInplanes;
    
return