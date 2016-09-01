function [doECC doResamp] = dtiInitEddyCC(dwParams,dwDir,doResamp)
% 
%   doECC = dtiInitEddyCC(dwParams,dwDir)
% 
% Based on user selected params decide if we do eddy current correction and
% resampling. The two flags [doECC doResamp] are then returned to dtiInit
% where the actual computation functions are called. 
%
% If eddyCorrect is 1 (the default), motion and eddy-current correction are done. 
%                   0, then only motion correction is done
%                  -1 then nothing is done
% 
% WEB resources:
%   http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%   mrvBrowseSVN('dtiInitEddyCC');
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%%
% 
doECC = false;
doResamp = false;

% If the user has elected not to do ECC then set doECC to false and go on.
if dwParams.eddyCorrect == -1 
    dwDir.ecFile = [];
    doECC        = false;
else
    % Compute the eddy-current correction for all the DWIs if we are
    % overwriting or an ECC file does not exist.
    if dwParams.clobber == 1 || ~exist(dwDir.ecFile,'file') 
        doECC    = true;
        doResamp = true; 
    else
        if dwParams.clobber == 0 
            resp = questdlg([dwDir.ecFile ' exists- would you like to overwrite it?'],...
                'Clobber EddyCorrect','Overwrite','Use Existing File','Abort','Use Existing File');
            if(strcmpi(resp,'Abort')), error('User aborted.'); end
            if(strcmpi(resp,'Overwrite'))
                doECC    = true;
                doResamp = true; 
            end
        end
    end
end

return