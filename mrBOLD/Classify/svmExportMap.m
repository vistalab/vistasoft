function map = svmExportMap(svm, models, groups, varargin)
% map = svmExportMap(svm, models, groups, varargin)
% SUPPORT VECTOR MACHINE - EXPORT MAP
% ---------------------------------------------------------
% Exports an Inplane or Gray view parameter map of the weights the SVM
% assigned to each voxel in distinguishing the conditions.
%
% INPUTS
%   svm - Structure retrieved from svmInit.
%   models - Models structured computed by svmRun.
%   groups - Vector of two conditions you'd like to compare in the map.
%	OPTIONS
%       'SaveToView' - View you'd like the map stored to. DEFAULT: 'Gray'
%           'Inplane' - Inplane view
%			'Gray' - Gray view
%           'Volume' - Volume view
%
%		'MapName' - Name you'd like tacked onto the parameter map. DEFAULT:
%           'SVM_01v02' (in the case of 1v2)
%	
%		'SaveToFile' - Full path to where you'd like to save the map.
%           DEFAULT: Prompt user.
%
% OUTPUTS
%   map
%
% USAGE
%   Generate a Gray view map with weights for conditions one versus two.
%   Don't return it as a variable, but let it be saved to disk.
%       svm = svmInit(...);
%       [accuracy models] = svmRun(svm, ...);
%       svmExportMap(svm, models, [1 2], 'MapName', 'UpVsDown', ...
%           'SaveToFile', '/myexperiment/subject1/Weights_UpVsDown.mat');
%
% See also SVMINIT, SVMRUN, SVMBOOTSTRAP, SVMRELABEL, SVMREMOVE,
% SVMRUNOPTIONS, SLINIT.
%
% renobowen@gmail.com [2010]
%

    if (~iscell(svm)), svm = {svm}; end % ensures compatibility even when people only pass in one
    if (~iscell(models)), models = {models}; end
    
    currentDir = pwd;
    
    sessionPath = svm{1}.sessionPath;
    cd(sessionPath);
   	inplane = initHiddenInplane();
    
	mrGlobals;
    functionalData = mrSESSION.functionals(1);
	mapSize = [functionalData.cropSize, length(functionalData.slices)];
    
    saveToView = 'Gray';
	saveToFile = [];
	mapName = [];
    normalize = false;
    grayModeMask = false;
    volumeDat = [];
	for i = 1:2:length(varargin)
		switch (lower(varargin{i}))
			case {'savetofile'}
				saveToFile = varargin{i + 1};
			case {'mapname'}
				mapName = varargin{i + 1};
            case {'savetoview'}
                switch (lower(varargin{i + 1}))
                    case {'gray'}
                        saveToView = 'Gray';
                    case {'volume'}
                        saveToView = 'Volume';
                    case {'inplane'}
                        saveToView = 'Inplane';
                    otherwise
                        fprintf('Unrecognized view: ''%s''\n', varargin{i + 1});
                        return;
                end
            case {'normalize'}
                normalize = varargin{i + 1};
            case {'graymodemask'} % only use if you have gray ROIs available for subject
                grayModeMask = varargin{i + 1};
            otherwise
				fprintf('Unrecognized option: ''%s''\n', varargin{i});
				return;
        end
    end
    
    % Need same # of svms and models
    if (length(svm) ~= length(models))
        fprintf('# of svm/models doesn''t match.\n');
        return;
    end
    % Perhaps insert check to ensure if there are multiple svms, they all
    % have same conditions!
    
	map{1} = zeros(mapSize);
    for i = 1:length(svm)
        meanW = ComputeMeanW(svm{i}, models{i}, groups);
%         if (normalize)
%             absMeanW    = abs(meanW);
%             normalizeBy = max(absMeanW);
%             meanW = meanW / normalizeBy;
%         end
        map = PopulateMap(svm{i}, map, meanW);    
    end
    
	if (isempty(mapName))
		mapName = sprintf('%s_%sv%s', svm{1}.selectedROI, svm{1}.grouplabel{groups(1)}, svm{1}.grouplabel{groups(2)});
    end
    
    if (strcmp(saveToView, 'Gray') || strcmp(saveToView, 'Volume'))
        [map volCoords] = InplaneToVolume(inplane, map, 'linear');
        volCoords = volCoords(1:3, :); % eliminate 4th row, don't know what it's for and it messes up later computation
        volumeDat.volCoords = volCoords;
    end
    
    if (grayModeMask)
        coords = [];
        for i = 1:length(svm)
            tmp = load(fullfile(svm{i}.sessionPath, 'Gray', 'ROIs', svm{i}.selectedROI));
            coords = [coords tmp.ROI.coords];
            if (normalize)
                [c roiInds] = intersectCols(volCoords, tmp.ROI.coords);
                normalizeBy = max(abs(map{1}(roiInds)));
                map{1}(roiInds) = map{1}(roiInds) / normalizeBy;
            end
        end
        volumeDat.dataCoords = coords;
        maskedMap{1} = nan(size(map{1}));
        [vals indices] = intersectCols(volCoords, coords);
        maskedMap{1}(indices) = map{1}(indices);
        map = maskedMap;
    end
    
    absMap          = abs(map{1});
    clipBoundary    = max(max(max(absMap)));
    clipMode        = [-clipBoundary clipBoundary];
    co{1}           = absMap./max(absMap(:));
    
	if (isempty(saveToFile))
        dir = fullfile(svm{1}.sessionPath, saveToView, 'GLMs', 'SVM');
        if (~exist(dir, 'dir'))
            mkdir(dir);
        end
		uisave({'map', 'mapName', 'clipMode', 'co', 'volumeDat'}, fullfile(svm{1}.sessionPath, saveToView, 'GLMs', 'SVM', mapName)); 
    else    
        save(saveToFile, 'map', 'mapName', 'clipMode', 'co', 'volumeDat');
    end
    
    cd(currentDir);
    
end

function [map coords] = InplaneToVolume(inplane, map, method)
% InplaneToVolume
%   Convert map from inplane to gray view format.
%
    volume = initHiddenGray();
    mrGlobals;
    
    % Compute the transformed coordinates (i.e., where does each gray node fall in the inplanes).
    % The logic here is copied from ip2volCorAnal.
    nVoxels = size(volume.coords, 2);
    coords = double([volume.coords; ones(1, nVoxels)]);
    vol2InplaneXform = inv(mrSESSION.alignment);
    vol2InplaneXform = vol2InplaneXform(1:3, :);
    coordsXformedTmp = vol2InplaneXform * coords;
    coordsXformed = coordsXformedTmp;
    
    curScan = 1;
    rsFactor = upSampleFactor(inplane, curScan);
    if (length(rsFactor) == 1)
        coordsXformed(1:2, :) = coordsXformedTmp(1:2, :) / rsFactor;
    else
        coordsXformed(1, :) = coordsXformedTmp(1, :) / rsFactor(1);
        coordsXformed(2, :) = coordsXformedTmp(2, :) / rsFactor(2);
    end
    
    if (~isempty(map{1}))
        mapInplane = map{1}(:, :, :);
        mapInterpVol = interp3(mapInplane, ...
            coordsXformed(2, :), ...
            coordsXformed(1, :), ...
            coordsXformed(3, :), ...
            method);
        map = {reshape(mapInterpVol, dataSize(volume))};
    end
end


function [map] = PopulateMap(svm, map, values)
% PopulateMap
%	Given an svm containing a coords field, a mapSize, and the relevant values,
%	will fill a map in the correct locations.
%
	coords = svm.coordsInplane;
	for i = 1:length(coords)
		map{1}(coords(1, i), coords(2, i), coords(3, i)) = values(i);
	end
end

function [meanW] = ComputeMeanW(svm, models, groups)
% ComputeMeanW
%	Computes the mean of the model variable 'w' (referred to in a large comment
%	below) across all of the models given between the two groups specified. 
%

	nModels = length(models);
	w		= zeros(nModels, length(svm.coordsInplane));
	for i = 1:nModels
		w(i,:) 	= ComputeW(models(i).output, groups); 
	end
	meanW = mean(w);
end

function [w] = ComputeW(model, groups)
% ComputeW
%	Computes the model variable 'w' (referred to in a large comment below)
%	between the two groups specified.
%

	rows_group1 = GetRowsToAccess(model, groups(1));
	rows_group2 = GetRowsToAccess(model, groups(2));
	col_group1 	= GetColumnToAccess(groups); 		
	col_group2	= GetColumnToAccess([groups(2) groups(1)]);

	coef	= [ model.sv_coef(rows_group1, col_group1); ...
				model.sv_coef(rows_group2, col_group2)];
	SVs		= [ model.SVs(rows_group1, :); ...
				model.SVs(rows_group2, :)];
	w 		= SVs' * coef;
end

% [RETRIEVED FROM LIBSVM FAQ]
%
% On computing difference variable 'w' with output:
%
% sv_coef is like:
% 
% 		+-+-+--------------------+
% 		|1|1|                    |
% 		|v|v|  SVs from class 1  |
% 		|2|3|                    |
% 		+-+-+--------------------+
% 		|1|2|                    |
% 		|v|v|  SVs from class 2  |
% 		|2|3|                    |
% 		+-+-+--------------------+
% 		|1|2|                    |
% 		|v|v|  SVs from class 3  |
% 		|3|3|                    |
% 		+-+-+--------------------+
% 
% so we need to see nSV of each classes.
% 
% 		> model(1).nSV 
%			3
%			21
%			18
% 
% Suppose the goal is to find the vector w of classes 1 vs 3. Then y_i alpha_i of training 1 vs 3 are
% 
% 		> coef = [m.sv_coef(1:3,2); m.sv_coef(25:42,1)];
% 
% and SVs are:
%   
% 		> SVs = [m.SVs(1:3,:); m.SVs(25:42,:)];
% 
% Hence, w is
% 
% 		> w = SVs'*coef;
%

function [rows] = GetRowsToAccess(model, group)
% GetRowsToAccess
%	Retrieves the rows necessary to access a particular group within the nSV
%	and coef fields of the model struct.
%

	rows = (sum(model.nSV(1:(group - 1))) + 1):(sum(model.nSV(1:(group)))); 
end

function [column] = GetColumnToAccess(groups)
% GetColumnsToAccess
%	Retrieves the column to access within nSV field of the model struct to get
%	the values for groups(1) v groups(2). 
%

	if (groups(2) < groups(1))
		column = groups(2);
	else
		column = groups(2) - 1;
	end
end
