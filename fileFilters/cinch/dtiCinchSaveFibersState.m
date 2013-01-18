function dtiCinchSaveFibersState(fiberGroupInds, stateFile, fg, pdbFile)
% 
% dtiCinchSaveFibersState(fiberGroupInds, stateFile, [fg], [pdbFile])
%
% Saves an array of fiber groups in CINCH pdb/state format.
%
% HISTORY:
% 2008.10.08 RFD: wrote it.
%

if(nargin>=4)
    dtiWriteFiberGroup(fg, pdbFile);
    if(numel(fiberGroupInds)~=numel(fg.fibers))
        error('fiberGroupInds does not match pdb file!');
    end
end

fid = fopen(stateFile,'wt');
% 11 header lines:
fprintf(fid,'%% dtivis software version: 0\n');
fprintf(fid,'Camera Position: -290.0,-21.0,76.0\n');
fprintf(fid,'Camera View Up: 0.2,0.02,1.0\n');
fprintf(fid,'Camera Focal Point: 0,-15,15\n');
fprintf(fid,'Query Mode: 0\n');
fprintf(fid,'Query String:\n');
fprintf(fid,'Units: 1\n');
fprintf(fid,'Tomo. Position: 40,40,20\n');
fprintf(fid,'Tomo. Visibility: 1,1,1\n');
fprintf(fid,'Pathway Min Length: 0\n');
fprintf(fid,'Pathway Max Length: 0\n');

fprintf(fid,'%d\n',fiberGroupInds);
fclose(fid);

return;
