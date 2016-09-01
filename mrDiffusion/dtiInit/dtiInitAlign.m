function [doAlign, doResamp] = dtiInitAlign(dwParams,dwDir,doResamp)
% 
%  doAlign = dtiInitAlign(dwParams,dwDir)
% 
% Based on user selected params decide if we align the raw dwi data to a
% reference image (t1).
% 
% WEB resources:
%   https://github.com/vistalab/vistasoft/wiki/DWI-Initialization
%   vistaBrowseGit('dtiInitAlign');
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%%
doAlign  = false;

% If we are overwriting or an alignment file does not exist then we signal
% to align and resample. 
if dwParams.clobber == 1 || ~exist(dwDir.acpcFile,'file') 
    doAlign  = true;
    doResamp = true;
else
    % Prompt the user to overwrite if clobber = 'ask'
    if dwParams.clobber == 0 
        resp = questdlg([dwDir.acpcFile ' exists- would you like to overwrite it?'],...
            'Clobber AcPc','Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            doAlign  = true;
            doResamp = true;
        end
    end
end

end
