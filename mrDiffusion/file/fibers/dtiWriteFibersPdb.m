function dtiWriteFibersPdb(fg, xformToAcpc, pdbFname)
%
% dtiWriteFibersPdb([fg=uigetfile], [xformToAcpc=eye(4)], [[pdbFname=uiputfile])
% 
% Writes the fiber group to disk in the specified file using the PDB format
% recognized by CINCH.
% * Note that .pdb extension will be added to pdbFname.
%
% Example usage: 
% dtiWriteFibersPdb(fg,dt.xformToAcpc,fullfile(fiberDir,'Lfibers'));
%
% Note that CINCH doesn't use the xformToAcpc, so you can safely skip it.
%
%
% HISTORY:
% 2008.07.02 LMP: wrote it.
% 2011.01.27 LMP: Now just uses mtrExport fibers.
%
%
disp([mfilename ' is now obsolete -- wrapping your inputs for mtrExportFibers...']);

if(~exist('fg','var')||isempty(fg))
    [fg,fgName] = dtiReadFibers;
    [p,f,e] = fileparts(fgName);
    fgName = fullfile(p,[f '.pdb']);
else
    fgName = fullfile(pwd,'fibers.pdb');
end

if(~exist('xformToAcpc','var')||isempty(xformToAcpc))
    xformToAcpc = [];
end

if(~exist('pdbFname','var')||isempty(pdbFname))
    [f,p] = uiputfile(fgName,'Save pdb file as...');
    if(isequal(f,0)), disp('user canceled.'); return; end
    pdbFname = fullfile(p,[f '.pdb']);
end
mtrExportFibers(fg, pdbFname);

return

% if(~exist('fg','var')||isempty(fg))
%     [fg,fgName] = dtiReadFibers;
%     [p,f,e] = fileparts(fgName);
%     fgName = fullfile(p,[f '.pdb']);
% else
%     fgName = fullfile(pwd,'fibers.pdb');
% end
% 
% if(~exist('xformToAcpc','var')||isempty(xformToAcpc))
%     xform = eye(4);
% else
%     % The xform that CINCH/dtiQuery wants assumes 1mm voxels:
%     [t,r,s,k] = affineDecompose(xformToAcpc);
%     xform = affineBuild(t,r,sign(s),k);
% end
% 
% if(~exist('pdbFname','var')||isempty(pdbFname))
%     [f,p] = uiputfile(fgName,'Save pdb file as...');
%     if(isequal(f,0)), disp('user canceled.'); return; end
%     pdbFname = fullfile(p,f);
% end
% 
% % add the .pdb file extension
% if(~strcmpi(pdbFname(end-3:end),'.pdb'))
%     pdbFname = [pdbFname,'.pdb'];
% end
% 
% dtiWritePDBHeader(xform, pdbFname);
% offsets = dtiAppendPathwaysToPDB(fg, pdbFname);
% dtiAppendFileOffsetsToPDB(offsets, pdbFname);
% 
% return
