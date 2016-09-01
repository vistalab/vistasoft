function dtiInitReorientBvecs(dwParams,dwDir,doResamp,doBvecs,bvecs,bvals)
% 
%  doRawResample = dtiInitResample(dwParams,dwDir)
% 
% Based on user selected params and the outputs of dtiInitAlign and
% dtiInitEddyCC we reorient and save bvecs and bvals files
% 
% WEB resources:
%   http://white.stanford.edu/newlm/index.php/DTI_Preprocessing
%   mrvBrowseSVN('dtiInitReorientBvecs');
% 
% (C) Stanford VISTA, 8/2011 [lmp]
% 

%%
% 
% If bvecs file was computed earlier doBvecs will = true. If clobber = true
% or the aligned BVs files do not exist we reorient and save.
if doBvecs || (doResamp && dwParams.clobber == -1) ...
           || dwParams.clobber == 1 ... 
           || ~exist(dwDir.alignedBvecsFile,'file') ...
           || ~exist(dwDir.alignedBvalsFile,'file') 
    % Reorient and save the b-vectors and bvals  
    dtiRawReorientBvecs(bvecs, dwDir.ecFile, dwDir.acpcFile, dwDir.alignedBvecsFile);
    dlmwrite(dwDir.alignedBvalsFile,bvals,' ');
else
    % If clobber = 'ask' prompt the user to overwrite
    if dwParams.clobber == 0 
        resp = questdlg([dwDir.alignedBvecsFile ' exists- would you like to overwrite it?'],...
            'Clobber Bvecs/bvals', 'Overwrite','Use Existing File','Abort','Use Existing File');
        if(strcmpi(resp,'Abort')), error('User aborted.'); end
        if(strcmpi(resp,'Overwrite'))
            % If the user selects to overwrite we reorient and save the
            % b-vectors and bvals 
            dtiRawReorientBvecs(dwDir.bvecsFile, dwDir.ecFile, dwDir.acpcFile, dwDir.alignedBvecsFile);
            dlmwrite(dwDir.alignedBvalsFile,bvals,' ');
        end
    end
end
