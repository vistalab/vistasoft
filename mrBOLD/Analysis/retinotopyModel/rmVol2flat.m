function flat = rmVol2flat(gray,flat)
% flat = rmVol2flat(gray,flat)
%
% sd 04/2008 wrote it

% Don't do this unless gray is really a gray and flat is really a flat
if ~strcmp(gray.viewType,'Gray') || ~strcmp(flat.viewType,'Flat')
    myErrorDlg('vol2flatCorAnal can only be used to transform from gray to flat.');
end

% Check that both gray & flat are properly initialized
if isempty(gray)
  myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end
if isempty(flat)
  myErrorDlg('Flat view must be open.  Use "Open Flat Window" from the Window menu.');
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
checkTypes(gray,flat);

% get/load selected file
try
  rmFile = viewGet(gray,'rmFile');
catch
  disp(sprintf('[%s]:Please select file',mfilename));
  gray    = rmSelect(gray);
  rmFile  = viewGet(gray,'rmFile');
end;
load(rmFile,'model',  'params');
modelGray = model; %#ok<NODEF>

% Mask image for masking the flat map away from where we have data
mask = flat.ui.mask;

% Put up wait bar
waitHandle = mrvWaitbar(0,'Transforming retModel.  Please wait...');
% Intersect the coords from the gray view and the Flat view.
grayIndices=cell(1,2);
flatIndices=cell(1,2);
for h=1:2
    % Get the data corresponding to flat coordinates: coData,
    % ampData, and phData are each of size nVoxels x nScans where
    % nVoxels = size(flat.grayCoords,2).  First, find the
    % intersection of gray.coords and flat.grayCoords.  Then make
    % the data arrays by culling out the values from the
    % intersecting voxels.
    % Find gray nodes that are both in the inplanes and included
    % in the unfold.
    % gray.coords are the gray coords that lie in the inplanes.
    % flat.grayCoords are the gray coords in the unfold.
    % Note: this code segment is essentially identical to
    % code in getFlatCoords.
    [foo,grayIndicesTmp,flatIndicesTmp] = intersectCols(gray.coords,flat.grayCoords{h});
    grayIndices{h}=grayIndicesTmp;
    flatIndices{h}=flatIndicesTmp;
    % Error check on flatIndices.  Because the above code segment
    % is the same as that used to get the flat coords in
    % getFlatCoords, all of the flatIndices should be in the
    % intersection.  If not, something is busted.
    if length(flatIndicesTmp)~=size(flat.grayCoords{h},2)
        myWarnDlg('Ack!  Your flat maps do not appear to come from this segmentation!');
    end
end

ds = viewGet(flat,'datasize');
for m = 1:numel(model),  
    % get all model fields 
    fnames = fieldnames(model{m});
    for f = 1:numel(fnames),   % loop over model fields
        mrvWaitbar(((m-1).*length(model)+f) ./ (length(model).*length(fnames)))
        paramGray = rmGet(modelGray{m},fnames{f});
        % only xfm model fields that have data of a certain size
        if numel(paramGray)>1 && isnumeric(paramGray),  
            % reshape both left and right
            paramFlat = zeros(ds);
            for h=1:2
                % Corresponding coords on the flat map
                coords = flat.coords{h}(:,flatIndices{h});            
                switch lower(fnames{f})
                    case {'b',  'beta'}
                        for ii = 1:size(paramGray,1),  
                            paramFlat(:,:,h,ii) = ...
								myGriddata(coords, ...
                                           paramGray(ii,grayIndices{h}).',  ...
                                           mask(:,  :,h));
                        end;
                    otherwise,
                        paramFlat(:,  :,h) = ...
							myGriddata(coords, ...
                                       paramGray(grayIndices{h}).', ...
                                       mask(:, :,h));
                end;
            end
            model{m} = rmSet(model{m},fnames{f},paramFlat); %#ok<AGROW>
        end;
    end;
end;
close(waitHandle)

% Now save output 
[p outputname] = fileparts(rmFile);
pathStr        = fullfile(dataDir(flat),outputname);

% Overwrite?
if exist(pathStr,'file')
    saveFlag = questdlg([pathStr, ' already exists. Overwrite?'],  ...
						'Save model file?',  'Yes',  'No',  'No');
else
    saveFlag = 'Yes';
end

% Save
if strcmp(saveFlag, 'Yes')
    save(pathStr, 'model', 'params');
    flat = viewSet(flat, 'rmFile', pathStr);
    fprintf(1, '[%s]:Saved %s.\n', mfilename, pathStr);
else
    fprintf(1, '[%s]:Model not saved.\n', mfilename);
end

% If we transformed it, we probably want to view the data. Load the model.
flat = rmSelect(flat, 1, [pathStr '.mat']);
flat = rmLoadDefault(flat);

return;