function mrSESSION = mrvMakeEmptySession;
%
% mrSESSION = mrvMakeEmptySession: [no arguments]
%
% Create a mrSESSION struct without 
% any functionals assigned, for pseudo-realtime.
%
%
% ras 04/05.

[p f] = fileparts(pwd);

mrSESSION.mrLoadRetVersion = '3.10'; % I figure it's updated at to least that :)
mrSESSION.sessionCode = f;
mrSESSION.description = 'mrvTurbo';
mrSESSION.subject = '';
mrSESSION.examNum = '';
mrSESSION.inplanes = [];
mrSESSION.functionals = [];

dataTYPES.name = 'Original';

vANATOMYPATH = '';

save mrSESSION mrSESSION dataTYPES

return