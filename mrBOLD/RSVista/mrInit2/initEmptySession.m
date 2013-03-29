function mrSESSION = initEmptySession;
%
% mrSESSION = initEmptySession: [no arguments]
%
% Create a mrSESSION struct without 
% any functionals assigned, for pseudo-realtime.
%
%
% ras 04/05.

[p f] = fileparts(pwd);

mrSESSION.mrVistaVersion = '2.0'; 
mrSESSION.sessionCode = f;
mrSESSION.description = '';
mrSESSION.subject = '';
mrSESSION.examNum = '';
mrSESSION.inplanes = [];
mrSESSION.functionals = [];
mrSESSION.coil = '';
mrSESSION.operator = '';
mrSESSION.inplanes.inplanePath = '';
%mrSESSION.functionals.functionalsPath = []; %TODO: Think about how to
%store multiple paths

dataTYPES.name = 'Original';

vANATOMYPATH = '';

save mrSESSION mrSESSION dataTYPES %TODO: Add vANATOMYPATH to save here?

return