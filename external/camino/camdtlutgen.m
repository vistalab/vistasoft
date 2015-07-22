function camdtlutgen(schemefile, snrpico, picotablefile)
% 
% camdtlutgen(schemefile, [snrpico=20], picotablefile)
% 
% Generating a PICo lookup table by calling dtlutgen in CAMINO.
% 
% INPUTS:
%   schemefile:     The full path to scheme file
%   snrpico:        The snr setting used for this function; the default is 
%                   20 here.
%   picotablefile:  The file name for PICo lookup table
% 
% (C) Hiromasa Takemura, CiNet HHS/Stanford VISTA Team, 2015

if notDefined('snrpico');
    snrpico = 20;
end

% Execute conversion
cmd = sprintf('dtlutgen -schemefile %s -snr %s > %s', schemefile, num2str(snrpico), picotablefile);
display(cmd);
system(cmd,'-echo');

return


