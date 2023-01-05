function [nFiles, aSize, anat] = CheckAnatomy(dirName)

% [nFiles, size] = CheckAnatomy(dirName);
%
% Looks at the files in the specified directory and finds all files
% with names of form I.*. Counts the number of files that continuously
% run in the sequence I.001, I.002, etc., and have the same non-zero
% size. Outputs the number of files found and their size.
%
% DBR  4/99

nFiles = 0;
aSize = [0 0];
anat = [];

if ~exist(dirName, 'dir'); return; end

dS = dir(fullfile(dirName, 'I.*'));
nList = length(dS);
if nList == 0; return; end

% Create a subset of files that match our filename criterion: I.nnn 
nFList = 0;
for iList=1:nList
  fName = dS(iList).name;
  if length(fName) == 5 & strcmp('I.', upper(fName(1:2)))
    seqNo = str2num(fName(3:5));
    if length(seqNo)
      nFList = nFList + 1;
      fileList{nFList} = fName;
      seqNos(nFList) = seqNo;
    end
  end
end

% Sort the matching files in ascending numerical order.
[seqNos, sortInds] = sort(seqNos);
fileList = fileList(sortInds);


% Check the files for unbroken sequence and matching image size.
%
% Put up a status bar if there is more than a single file:
if nFList > 1
  hBar = mrvWaitbar(0, 'Scanning MRI files');
end
% Begin the second pass. Break if sequence or size isn't right.
for iList=1:nFList
  if seqNos(iList) ~= iList; break; end
  img = ReadMRImage(fullfile(dirName, fileList{iList}));
  imSize = size(img);
  if exist('firstSize', 'var')
    if ~all(firstSize == imSize); break; end
    nFiles = nFiles + 1;
    anat = cat(3, anat, img);
  else
    firstSize = imSize;
    nFiles = 1;
    anat = img;
  end
  if nFList > 1
    mrvWaitbar(iList/nFList)
  end
end
% Get rid of any status bar
if nFList > 1
  close(hBar)
end

aSize = firstSize;
