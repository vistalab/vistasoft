function scanList = selectScans(vw,title,~)
% scanList = selectScans(vw,[title],[scanDir]);
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
%if ~exist('scanDir','var'), scanDir = tSeriesDir(vw,0); end;
%We will no longer use scanDir

scanNum = viewGet(vw,'N Scans');

scanList = 1:scanNum;

scanNames = cell(length(scanList),1);
for i=scanList
    scanNames{i} = num2str(i); 
end

% Which scans to analyze?
iSel = buttondlg(title, scanNames);
scanList = scanList(find(iSel));

return;
