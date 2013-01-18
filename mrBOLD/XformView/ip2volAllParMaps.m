function ip2volAllParMaps(inplane, volume, method);
% ip2volAllParMaps(inplane, volume, method);
% OR
% ip2volAllParMaps(dataTypeName, 'Volume' or 'Gray', [method='nearest']);
%
% Convert all parameter maps in a data type from inplane to volume, using
% the selected interpolation method.
%
% This code looks in the data directory of the selected inplane/data type,
% and finds .mat files which contain the 'map' variable saved, and xforms
% them into the appropriate volume directory.
%
% ARGUMENTS
% The first argument can either be an inplane structure, or the name of 
% the data type from which to xform maps.
%
% The second argument can either be a volume structure, or the name of the
% view type to save the maps: 'Volume' or 'Gray'.
%
% The third argument, 'method', specifies the method to use when xforming.
% defaults to 'nearest', but can also be 'linear'. 
%
% ras, 11/2006.
if nargin<2, error('Not enough input args.'); end
if notDefined('method'), method = 'nearest'; end

if ischar(inplane)  % data type name
    inplane = initHiddenInplane(inplane);
end

if ischar(volume)   % target view type
    if isequal(lower(volume), 'gray')
        volume = initHiddenGray(inplane.curDataType);
    else
        volume = initHiddenVolume(inplane.curDataType);
    end
end

%% check data types
[inplane volume] = checkTypes(inplane, volume);


%% find and xform the maps 
w = what(dataDir(inplane));

for f = w.mat'
    mapPath = fullfile(dataDir(inplane), f{1});
    test = load( mapPath );
    if isfield(test, 'map')   % has a param map
        inplane = loadParameterMap(inplane, mapPath);
        ip2volParMap(inplane, volume, 0, 1, method);
    end
end

fprintf('Done xforming scans.\n');

return
