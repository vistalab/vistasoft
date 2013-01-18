function dtiQuenchSaveFibersState(fiberGroupInds, stateFile, fg, pdbFile)
% 
% dtiQuenchSaveFibersState(fiberGroupInds, stateFile, [fg], [pdbFile])
%
% Saves an array of fiber groups in QUENCH pdb/state format.
%
% HISTORY:
% 2009.09.22 ER: wrote it.
%

if(nargin>=4) %Dont save pdb if fg/pdb file name not supplied. 
    mtrExportFibers(fg, pdbFile);
    if(numel(fiberGroupInds)~=numel(fg.fibers))
        error('fiberGroupInds does not match pdb file!');
    end
end

fid = fopen(stateFile,'wt');
% 5 header lines:
fprintf(fid,'Camera Position: -290.0,-21.0,76.0\n');
fprintf(fid,'Camera View Up: 0.2,0.02,1.0\n');
fprintf(fid,'Camera Focal Point: 0,-15,15\n');
fprintf(fid,'Volume Section''s Position: 40,40,20\n');
fprintf(fid,'Volume Section''s Visibility: 1,1,1\n');
fprintf(fid,'%d\n',length(fiberGroupInds));
fprintf(fid,'%d\n',fiberGroupInds);
fclose(fid);

return;
