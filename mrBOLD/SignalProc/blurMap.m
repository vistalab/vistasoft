function view = blurMap(view,weightFlag,lambda)% view = blurMap(view, [weightFlag], [lambda])% Just like blurPh but operates on the parameter map rather than the ph% See blurPh% ARW 061004
if isempty(view)
  myErrorDlg('Volume window must be open to blur map.');
end
if ~strcmp(view.viewType,'Gray')
  myErrorDlg('Blur map only for gray views.');
end
if isempty(view.map)    myErrorDlg('Maps not loaded.  Load them from the File menu');end
if ~exist('weightFlag','var')	weightFlag = 0;   end
if ~exist('lambda','var')   lambda = 0.1;end
curScan = getCurScan(view);map = view.map{curScan}(:);
% RegularizationnewMap = regularizeGray(map,view.nodes,view.edges,lambda);
view.map{curScan}(:) = newMap;

return;
