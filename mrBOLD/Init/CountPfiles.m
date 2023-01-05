function [nFiles, fileList] = CountPfiles(dirName)
% [nFiles, fileList] = CountPfiles(dirName)
%
% Uses the generic Matlab DIR function to count all Pfiles in the
% input directory [dirName].
%
% Outputs: nFiles      number of Pfiles
%          fileList    cell array of file names
%
% 3/99  DBR

dS = dir(dirName);
fileList = {};
nFiles = 0;
nList = length(dS);
if nList == 0, return; end

for iList=1:nList
  fName = dS(iList).name;
  if strcmp(fName(1), 'P')
    nf = length(fName);
    if nf == 8
      good = strcmp(fName(7:8), '.7');
    else
      good = (nf == 6);
    end
    if good
      seqNo = str2num(fName(2:6));
      if length(seqNo) > 0
        if isreal(seqNo)
          fileList = {fileList{:}, fName};
          nFiles = nFiles + 1;
        end
      end
    end
  end
end

fileList = sort(fileList);
