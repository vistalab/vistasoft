function fg = dtiCinchGetFibersFromState(stateFile, pdbFile)
% 
% fg = dtiCinchGetFibersFromState(stateFile, pdbFile)
%
% Returns an array of fiber groups that were segmented in CINCH.
%
% HISTORY:
% 2008.03.06 RFD: wrote it.
%

fgAll = mtrImportFibers(pdbFile);
fid = fopen(stateFile,'rt');
% *** TO DO: make this more robust- let's actually read the header!
for(ii=1:11)
  hdStr{ii} = fgets(fid);
end
pathGroup = fscanf(fid,'%d\n',Inf);
fclose(fid);
if(numel(pathGroup)~=size(fgAll.fibers,1))
  error('State file does not match pdb file!');
end
groups = unique(pathGroup);
c = [127 127 127; 10 10 245; 245 10 245; 245 245 10; 10 245 10; 245 10 10; 127 127 10; 10 245 245; 64 64 10;];
for(ii=1:numel(groups))
  name = sprintf('Group %d',groups(ii));
  color = c(min(size(c,1),ii),:);
  fg(ii) = dtiNewFiberGroup(name,color,[],[],fgAll.fibers(groups(ii)==pathGroup));
end

return;
