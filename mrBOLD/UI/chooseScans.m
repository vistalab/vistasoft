function scanList = chooseScans(view)
% scanList = schooseScans(view);
%
%   Query the user for a sub-selection of scans.

%   This function uses numScans(view) to determine the number of scans to choose from. 
%   An alternate function, selectScans, actually checks for the existence of the tSeries files. 
%   Use selectScans if you will be analyzing the tSeries. 
%   Use chooseScans if your code does not depend on the presence/absence of the tSeries files.
%
% Output:
%  scanList: list of selected scans.
%
% djh, 3/2001, modified from selectScans

nScans = numScans(view);
scanList = 1:nScans;

for i=scanList
    scanNames{i} = ['Scan',num2str(i)];
end

%Check for zero:
if nScans == 0
  myErrorDlg('No scans!');
  return
end

% Which scans to analyze?
iSel = buttondlg('Choose scans', scanNames);
scanList = scanList(find(iSel));

return;
