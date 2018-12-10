function doRawResample = dtiInitResample(dwParams,dwDir,doResamp)
% 
%  doRawResample = dtiInitResample(dwParams,dwDir)
% 
% Based on user selected params and the outputs of dtiInitAlign and
% dtiInitEddyCC decide if we are resampling the data. 
% 
% WEB resources:
%   http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%   mrvBrowseSVN('dtiInitResample');
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%%
% 
doRawResample = false;

% If doResamp was set earlier in the code or there is no aligned raw data
% file we trigger data resampling. 
if (doResamp && dwParams.clobber == -1) ...
        || dwParams.clobber == 1 ...
        || ~exist(dwDir.dwAlignedRawFile,'file')    
    doRawResample = true;
else
    % If clobber = 'ask' prompt user to overwrite resampled data
    if dwParams.clobber == 0 
        resp = questdlg([dwDir.dwAlignedRawFile ' exists- would you like to overwrite it?'],...
            'Clobber Resampled Data', 'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            doRawResample = true;
        end
    end
end

return