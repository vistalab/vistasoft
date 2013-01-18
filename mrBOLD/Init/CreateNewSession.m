function mrSESSION = CreateNewSession(homeDir, inplanes, mrlVersion)
% Create default mrSESSION structure
%
%   mrSESSION = CreateNewSession(homeDir, inplanes, mrlVersion);
%
%
% DBR 4/99
%
% 7/16/02 djh, removed mrSESSION.vAnatomyPath

if notDefined('mrlVersion'), mrlVersion = 'unknown'; end

[parent, dir] = fileparts(homeDir);

mrSESSION.mrLoadRetVersion = mrlVersion;
mrSESSION.sessionCode = dir;
mrSESSION.description = '';
mrSESSION.subject = '';
mrSESSION.examNum = inplanes.examNum;
mrSESSION.inplanes = inplanes;

return