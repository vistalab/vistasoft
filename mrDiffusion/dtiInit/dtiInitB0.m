function computeB0 = dtiInitB0(dwParams,dwDir)
% 
% function computeB0 = dtiInitB0(dwParams,dwDir)
% 
% Here we decide if we compute b0. If the user asks to clobber existing
% files, or if the mean b=0 ~exist we return a flag that will compute it in
% dtiInit. If clobber is set to 'ask', then the user is prompted. 
% 
% WEB resources:
%   http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%   mrvBrowseSVN('dtiInitB0');
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%%
% 
computeB0 = false;

if dwParams.clobber == 1 || ~exist(dwDir.mnB0Name,'file') 
    computeB0 = true;
else
    % If clobber is set to 'ask' (0) the user if we should overwrite the
    % existing mean b0.
    if dwParams.clobber == 0 
        resp = questdlg([dwDir.mnB0Name ' exists- would you like to overwrite it?'],...
            'Clobber mnB0', 'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            computeB0 = true;
        end
    end
end

return