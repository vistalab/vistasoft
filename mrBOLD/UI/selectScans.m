function scanList = selectScans(view,title,scanDir)
% scanList = selectScans(view,[title],[scanDir]);
%
%   Gather a list of scans available in Inplane/TSeries
%   and query the user for a sub-selection.
%
%   An alternate function chooseScans uses numScans(view)
%   to determine the number of scans to choose from
%   Use selectScans if you will be analyzing the tSeries. 
%   Use chooseScans, if your code does not depend on the 
%   presence/absence of the tSeries files.
% 
% Input:
%  scanDir (optional): specify the dir that contains
%    'Scan*' subdir. Default is tSeriesDir(view).
% Output:
%  scanList: list of scans selected.
%
% 4/16/99  dbr Initial code
% 3/30/2001, djh, added optional title string
% 10/21/2004, MA, added optional scanDir
% 11/3/04, JL, make scanDir really optional

if ~exist('title','var'), title = 'Choose scans'; end;
if ~exist('scanDir','var'), scanDir = tSeriesDir(view,0); end;

scanList = [];
[nFiles, fileNames] = countDirs('Scan*',scanDir);
nameInds = [];

for i=1:nFiles
  name = fileNames{i};
  nChar = length(name);
  if nChar > 4
    if strcmp(name(1:4), 'Scan');
      % Get the scan numbers from the scan names:
      scanList = [scanList, str2num(name(5:nChar))];
      nameInds = [nameInds, i];
    end
  end
end

nScans = length(scanList);

%Check for zero:
if nScans == 0
  myErrorDlg('No scans found!');
  return
end

scanNames = fileNames(nameInds);
% Sort the scans by number:
[scanList, iSort] = sort(scanList);
scanNames = scanNames(iSort);

% Which scans to analyze?
iSel = buttondlg(title, scanNames);
scanList = scanList(find(iSel));

return;
