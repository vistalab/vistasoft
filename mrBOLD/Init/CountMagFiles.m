function [nFiles, fileList, seqNums] = CountMagFiles(dirName)
% [nFiles, fileList, seqNums] = CountMagFiles(dirName)
%
% Uses the generic Matlab DIR function to count all reconnned
% 'P?????.mag' files in the input directory [dirName].
%
% Outputs: nFiles      number of Pfiles
%          fileList    cell array of file names
%          seqNums     vector of mag-file sequence numbers
%
% 9/01  Ress
% 08/04 ras     sorts now by time of scan, which helps if the 
%               scan #s wrap around P64000 to 00000. Doesn't
%               help if the scans go around midnight (should
%               be easy to add though.)  

dS = dir(dirName);
fileList = {};
nList = length(dS);
if nList == 0, return; end

nFiles = 0;
for iList=1:nList
  fName = dS(iList).name;
  if strcmp(fName(1), 'P') & (length(fName) == 12)
    seqNo = str2num(fName(2:6)); % All files have to start with P and follow with a 5-digit sequence number
    if ~isempty(seqNo)
      if (seqNo - fix(seqNo)) == 0
        if strcmp(fName(7:12), '.7.mag') % Reconned files end in '.7.mag'
          fileList = [fileList {fName}];
          nFiles = nFiles + 1;
          seqNums(nFiles) = seqNo;
        end
      end
    end
  end
end

[seqNums, iSort] = sort(seqNums);
fileList = fileList(iSort);

return
