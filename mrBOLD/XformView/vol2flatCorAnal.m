function flat = vol2flatCorAnal(gray,flat,selectedScans)
%
% flat = vol2flatCorAnal(gray,flat,[selectedScans])
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via chooseScans dialog
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatParMap, vol2flatTSeries
%
% djh, 2/2001, mrLoadRet-3.0
% Don't do this unless gray is really a gray and flat is really a flat
if ~strcmp(gray.viewType,'Gray') | ~strcmp(flat.viewType,'Flat')
    myErrorDlg('vol2flatCorAnal can only be used to transform from gray to flat.');
end
% Check that both gray & flat are properly initialized
if isempty(gray)
  myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end
if isempty(flat)
  myErrorDlg('Flat view must be open.  Use "Open Flat Window" from the Window menu.');
end
if isempty(gray.co)
    myErrorDlg('corAnal must be loaded.  Use "Load Correlation Matrices" from the File menu (in the gray window)');
end
nScans = numScans(gray);
% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = chooseScans(gray);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[gray flat] = checkTypes(gray, flat);

% Initialize co, amp, and ph.
% If empty, initialize to cell array.
% If non-empty, grab it so that it can be updated
if isempty(flat.co)
    loadCorAnal(flat);
end
if ~isempty(flat.co)
    co = flat.co;
else
    co = cell(1,nScans);
end
if ~isempty(flat.amp)
    amp = flat.amp;
else
    amp = cell(1,nScans);
end
if ~isempty(flat.ph)
    ph = flat.ph;
else
    ph = cell(1,nScans);
end
% Mask image for masking the flat map away from where we have data
mask = flat.ui.mask;
% Put up wait bar
waitHandle = mrvWaitbar(0,'Transforming CorAnal.  Please wait...');
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
% Loop through the scans
for scan = selectedScans
    co{scan} = zeros(size(mask));
    amp{scan} = zeros(size(mask));
    ph{scan} = zeros(size(mask));
    %Loop through the hemispheres
    for h=1:2
        mrvWaitbar((h-1)/(2*length(selectedScans)) + (scan-1)/length(selectedScans));
        if ~isempty(gray.co{scan})
            % Get data from gray corresponding to the grayCoords
            coData = gray.co{scan}(grayIndices{h});
            zData = gray.amp{scan}(grayIndices{h}) .* exp(i*gray.ph{scan}(grayIndices{h}));
            % Corresponding coords on the flat map
            coords = flat.coords{h}(:,flatIndices{h});
            
            % JL 200705 NaNs in griddata will ruin flat. remove them.
            nonans = find(~isnan(coData)); coords = coords(:,nonans);
            coData = coData(:,nonans); zData = zData(:,nonans);
            
            % Map the data
            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            coIm = myGriddata(coords, coData.', mask(:,:,h));
            zIm = myGriddata(coords, zData.', mask(:,:,h));
            % pull amp and phase out of the complex z values
            ampIm = abs(zIm);
            phIm = angle(zIm);	
            % Wrap the phases > 0
            phIm(phIm<0) = phIm(phIm<0) + (2*pi);
            
            % Fill the corAnal matrices
            co{scan}(:,:,h) = coIm;
            amp{scan}(:,:,h) = ampIm;
            ph{scan}(:,:,h) = phIm;
        end
    end
end
close(waitHandle)
% Fill the field
disp('Setting co, amp, and ph fields in flat.');
flat.co = co;
flat.amp = amp;
flat.ph = ph;
% Save the new co, amp, and ph arrays in the flat subdirectory.
% if a corAnal file already exists, query user about over-writing
% it.
saveCorAnal(flat);
return;