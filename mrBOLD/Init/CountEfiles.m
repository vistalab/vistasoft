function [nFiles, fileList, seqNums, examNums, serNums] = CountEfiles(dirName)
% [nFiles, fileList, seqNums, examNums, sNums] = CountEfiles(dirName)
%
% Uses the generic Matlab DIR function to count all reconnned
% 'P?????.mag' files in the input directory [dirName].
%
% Outputs: nFiles      number of Pfiles
%          fileList    cell array of file names
%          seqNums     vector of mag-file sequence numbers
%
% 9/01  Ress

dS = dir(dirName);
fileList = {};
nList = length(dS);
if nList == 0, return; end

nFiles = 0;
for iList=1:nList
  fName = dS(iList).name;
  if strcmp(fName(1), 'E') && (length(fName) == 18) % All file names must 18 characters starting with E
    examNo = str2num(fName(2:6));
    if ~isempty(examNo)
      if (examNo - fix(examNo)) == 0 % All files must continue with a 5-digit integer exam number
        if strcmp(fName(7), 'S')
          seriesNo = str2num(fName(8:10));
          if (seriesNo - fix(seriesNo)) == 0 % Names continue with S followed by a 3-digit integer series number
            if strcmp(fName(11), 'P')
              seqNo = str2num(fName(12:16)); % Names continue with P followed by a 5-digit integer sequence number
              if ~isempty(seqNo)
                if (seqNo - fix(seqNo)) == 0 % Names continue with P followed by a 5-digit integer sequence number
                  if strcmp(fName(17:18), '.7') % Names end in '.7'
                    fileList = [fileList {fName}];
                    nFiles = nFiles + 1;
                    examNums(nFiles) = examNo;
                    serNums(nFiles) = seriesNo;
                    seqNums(nFiles) = seqNo;
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

[seqNums, iSort] = sort(seqNums);
examNums = examNums(iSort);
serNums = serNums(iSort);
fileList = fileList(iSort);

return
