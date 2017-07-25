function volume = ip2volCorAnal(inplane, volume, selectedScans, forceSave)
%
% function volume = ip2volCorAnal(inplane, volume, [selectedScans], [forceSave=0])
%
% Uses point sampling and nearest neighbor interpolation to map
% co, amp, and ph from inplane view to volume view.  inplane and
% volume views must already be open.  inplane corAnal must 
% be loaded.
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via chooseScans dialog
% forceSave: 1 = true (overwrite without dialog)
%            0 = false (query before overwriting)
%           -1 = do not save
%
% Output co, amp, and ph are nVoxels x nScans in size where
% nVoxels is the number of volume voxels that correspond to the
% inplanes, i.e., size(volume.coords,2)
%
% If you change this function make parallel changes in:
%    ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% djh, 7/98
%
% Modifications:
% djh, 2/2001
% - Replaced globals with local variables
% - Data are no longer interpolated to the inplane size
% Ress, 2/2004 -- Now performing linear interpolation using myCInterp3
% ras, 08/2007 -- removed method flag, since this seems to be comitted
% to using linear interpolation (is there a rationale to introduce
% a nearest-neighbor option as well, as per ip2volParMap?). Added forceSave
% flag.

if notDefined('forceSave'), forceSave = 0; end

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(inplane.viewType,'Inplane')
    myErrorDlg('ip2volCorAnal can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(volume.viewType,'Volume') && ~strcmp(volume.viewType,'Gray')
    myErrorDlg('ip2volCorAnal can only be used to transform from inplane to volume/gray.');
end

% Check that both inplane & volume are properly initialized
if isempty(inplane)
  myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(volume)
  myErrorDlg('Gray/volume view must be open.  Use "Open Gray/Volume Window" from the Window menu.');
end
if isempty(inplane.co)
  inplane = loadCorAnal(inplane, '', true);
end

nScans = viewGet(inplane, 'numScans');

% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = chooseScans(inplane);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[inplane volume] = checkTypes(inplane, volume);

% Allocate space for the volume data arrays.
% If empty, initialize to cell array. 
% If non-empty, grab it so that it can be updated.
%

if isempty(volume.co)
    try
        loadCorAnal(volume);
    catch %#ok<CTCH>
        volume.co  = cell(1,nScans);
        volume.ph  = cell(1,nScans);
        volume.amp = cell(1,nScans);
    end    
end

if ~isempty(volume.co),    co = volume.co;
else                       co = cell(1,nScans); end

if ~isempty(volume.amp),   amp = volume.amp;
else                       amp = cell(1,nScans); end

if ~isempty(volume.ph),    ph = volume.ph;
else                       ph = cell(1,nScans); end

% put up a wait handle if it's consistent with the VISTA verbose pref:
verbose = prefsVerboseCheck;
if verbose,
	waitHandle = mrvWaitbar(0,'Interpolating CorAnal.  Please wait...');
end

% Tranform gray coords to inplane functional coords. Previously, the code
% to do this xform was duplicated in many functions, including this one.
% It is now a separate routine. The third argument when set to true returns
% the precise (non-integer) functional coords, which are interpolated
% below.
coordsXformed = ip2volXformCoords(volume, inplane, true);


% Loop through the scans and use interp3 to transform the values
% from the inplanes to the volume.
%
for curScan = selectedScans
	if verbose,     mrvWaitbar((curScan-1)/nScans);  end

    % rsFactor is assumed to be the same in all scans, so we do not need
    % this step. (see upSampleFactor)
    %     % Scale the coords as explained above.
    %     rsFactor = upSampleFactor(inplane,curScan);
    %     if length(rsFactor)==1 % isometric upSampleFactor
    %         coordsXformed(1:2,:)=coordsXformedTmp(1:2,:)/rsFactor;
    %     else                    % x,y,and z scales are not isometric
    %         coordsXformed(1,:)=coordsXformedTmp(1,:)/rsFactor(1);
    %         coordsXformed(2,:)=coordsXformedTmp(2,:)/rsFactor(2);
    %     end
    
    if ~isempty(viewGet(inplane, 'scanco', curScan)) 
        
        % Pull out the correlations, phases, and amplitudes of the
        % inplane data for this scan and all anatomical slices.
        % 
        coInplane = viewGet(inplane, 'scanco', curScan);
        zInplane  = viewGet(inplane, 'scanamp', curScan) .* exp(1i*viewGet(inplane, 'scanph', curScan));
        
        % recast as double for interp
        coInplane = double(coInplane);
        zInplane  = double(zInplane);
        
        % Use the inplane data set values to assign (using linear 
        % interpolation) values to the volume voxels in coInterpVol
        % and zInterpVol.
        dims = size(coInplane);
        newCoords = [coordsXformed(2, :); coordsXformed(1, :); coordsXformed(3, :)]';
        coInterpVol = myCinterp3(coInplane, dims(1:2), dims(3), newCoords);      
        zInterpVol = complex(myCinterp3(real(zInplane), dims(1:2), dims(3), newCoords), ...
          myCinterp3(imag(zInplane), dims(1:2), dims(3), newCoords));
                
        co{curScan} = coInterpVol;
        
        % Pull out amp and ph, wrapping the phases to be all positive.
        %
        amp{curScan} = abs(zInterpVol);
        tmp = angle(zInterpVol);
        indices = find(tmp<0);
        tmp(indices) = tmp(indices) + (2*pi);
        ph{curScan} = tmp;
        clear tmp coInplane zInplane coInterpVol zInterpVol indices
    end 					
end

if verbose, close(waitHandle); end

% Set the fields in volume
%
volume = viewSet(volume, 'co', co);
volume = viewSet(volume, 'amp', amp);
volume = viewSet(volume, 'ph', ph);


% Save the new co, amp, and ph arrays in the Volume
% subdirectory.  if a corAnal file already exists, query user
% about over-writing it.
%
if forceSave >= 0, saveCorAnal(volume, [], forceSave); end

return
