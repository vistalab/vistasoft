function map3 = computeOverlapMap(view,map1,map2,varargin);
% map3 = computeOverlapMap(view,map1,map2,[options]);
%
% Computes the overlap between any 2 maps, outputting a parameter
% map the same size as the first map, with the following values:
%
%   0: both maps are below their specified thresholds for this voxel
%   1: map1 but not map2 is above its specified threshold for this voxel
%   2: map2 but not map1 is above its specified threshold for this voxel
%   3: both maps are above their specified thresholds for this voxel
%
% Options are specified as string pairs of the form 'paramName','paramValue'. They include:
%
% 'th1',[value],'th2',[value]: set thresholds for map1 and map2, respectively. 
% They default to 2 (since I'm using contrast maps of -log10(p)). If either
% of these is entered as a 2-value array, the code will interpret these as
% lower and upper bounds, respectively. Values in a map above or below its
% bounds will be considered as not satisfying threshold.
%
% 'ROIs',[#]: select ROIs to lay on top of maps (for visualization). In the
% output map, this is the value:
%   4: ROI is here, regardless of what was beneath.
%
% 'outPath',[path]: set the path for the output contrast map. If
% unspecified, will pop up a dialog.
%
% 'mapName',[name]: set the name for the map. If unspecified, defaults to
% the file name of the outPath.
%
% 'whichType',[#]:  specify the data type under which to save the file.
% Defaults to current data type.
%
% 'whichScanNum',[#]: specify the scan # to store the map in. Defaults to
% view's current scan.
%
%
% 12/15/03 ras.
global dataTYPES;

if nargin < 3
    help computeOverlapMap
    error('Need 3 input arguments, at least.');
end

%%%%% params
th1 = 2;
th2 = 2; 
outPath = [];
mapName = [];
whichType = view.curDataType;
whichScanNum = view.curScan;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parse the option flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:2:length(varargin)
    if (i < length(varargin)) & (ischar(varargin{i}))
		if (isnumeric(varargin{i+1}))
            if length(varargin{i+1})==1
		        cmd = sprintf('%s = %i;',varargin{i},varargin{i+1})
            else
                x = varargin{i+1};
		        cmd = sprintf('%s = deal(x);',varargin{i})
            end
		elseif ischar(varargin{i+1})
	        cmd = sprintf('%s = ''%s'';',varargin{i},varargin{i+1})
		elseif iscell(varargin{i+1});
			tmp = unNestCell(varargin{i+1});
	        cmd = sprintf('%s = {',varargin{i});			
			for j = 1:length(tmp)-1
				cmd = [cmd '''' tmp{j} ''','];
			end		
			cmd = [cmd '''' tmp{end} '''};']
	    end
        eval(cmd);
	end
end

%%%%% if either input map is a string, load that map and find first value
if ischar(map1)
    tmp = load(map1);
    cnt = 1;
    while ~isempty(tmp.map{cnt})
        cnt = cnt + 1;
    end
    map1 = tmp.map{cnt};
end

if ischar(map2)
    tmp = load(map2);
    cnt = 1;
    while ~isempty(tmp.map{cnt})
        cnt = cnt + 1;
    end
    map2 = tmp.map{cnt};
end


map3 = zeros(size(map1));

%%%%% set overlap values b/w two maps, values 1-3
if length(th1)==1
    ok1 = (map1 >= th1);
else
    ok1 = (map1 >= th1(1) & map1 < th1(2));
end

if length(th2)==1
    ok2 = (map2 >= th2);
else
    ok2 = (map2 >= th2(1) & map2 < th2(2));
end    
    
map3(ok1 & ~ok2) = 1;
map3(ok2 & ~ok1) = 2;
map3(ok1 &  ok2) = 3;

%%%%% set location of ROIs to be value 4, if any are selected
if exist('ROIs','var')
    for i = ROIs
        roi = view.ROIs(i);
        switch view.viewType
            case 'Inplane', % not yet tested
                ind = sub2ind(size(view.anat),roi.coords(1,:),roi.coords(2,:),roi.coords(3,:));
                map3(ind) = 4;
            case {'Volume','Gray'},
                [junk,nodeInds] = ismember(roi.coords', view.coords', 'rows');
                nodeInds = nodeInds(nodeInds>0);
                map3(nodeInds) = 4;
            otherwise
                error('Sorry, only works with Inplane, Volume, and Gray Views right now.');
        end
    end
end

if isempty(outPath)
	[fileName,pathName] = myUIPutFile(dataDir(view),'*.mat','Select a Name for the overlap map...');
	outPath = fullfile(fileName,pathName);
end

if isempty(mapName)
    [ignore fileName] = fileparts(outPath);
	mapName = fileName;
end

N = length(dataTYPES(whichType).scanParams);
map = cell(1,N);
map{whichScanNum} = map3;
save(outPath,'mapName','map');
fprintf('Saved overlap map %s.\n',outPath);

return