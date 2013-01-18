function view = rmInitView(viewPointer,roiFileName)
% rmInitView - initiate view struct from key pointers
% 
% view = rmInitView(view,roiFileName);
%
% These key pointers now are: 
%         pointer(1): viewType
%         pointer(2): dataType
%         roiFileName: if defined roi will be loaded
%
% SOD: wrote it.

if ~exist('viewPointer','var') || isempty(viewPointer), error('Need viewPointers'); end;
if ~exist('roiFileName','var'), roiFileName = []; end;

% default vista stuff
mrGlobals;
loadSession;

% set viewType
if viewPointer(1)==1
    view=initHiddenGray;
else
    view=initHiddenInplane;
end

% set dataType
view = viewSet(view,'curdatatype',viewPointer(2));
fprintf(1,'[%s]:DataType: %s\n',mfilename, ...
    dataTYPES(view.curDataType).name);

% if roiFileName load roi
if ~isempty(roiFileName)
    if ~strcmp(roiFileName,'0')
        view = loadROI(view,roiFileName,[],[],[],1);
    end
end

return;
