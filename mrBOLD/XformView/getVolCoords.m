function vw = getVolCoords(vw, rootDir)
%
% vw = getVolCoords(vw);
%
% Transforms the coordinates of the inplane voxels to the volume
% coordinate frame.  Fills the view.coords field and saves the
% transformed coords in Volume/coords.mat.
%
% view: must be VOLUME
%
% coords: 3xN array of integer-valued (y,x,z) coordinates for the
% N volume voxels that correspond to the inplanes.
%
% First, transforms all of the volume coordinates to the inplane
% coordinate frame using a 4x4 homogeneous transform.  If the
% volume coords are (y',x',z'), then we will have a transformation
% to inplane coordinates (y,x,z) via
% 
%        y             y'
%        x             x'
%        z   = [ 4x4 ] z'
%        1             1
% 
% Second, finds those coordinates that are within the size bounds
% of the inplanes.  Finally, selects the corresponding subset of
% volume coordinates.
%
% djh, 7/98

global mrSESSION 
global HOMEDIR

if ~strcmp(viewGet(vw,'View Type'),'Volume') && ~strcmp(viewGet(vw,'View Type'),'Gray')
  myErrorDlg('getVolCoords only for Volume view.');
end

if ~exist('rootDir', 'var'), rootDir = HOMEDIR; end
pathStr = fullfile(rootDir, vw.viewType, 'coords');

if ~exist(fileparts(pathStr), 'dir')
    mkdir(fileparts(pathStr));
end 


if check4File(pathStr)  
  % Load 'em
  %
  load(pathStr);
  vw = viewSet(vw, 'coords', coords);

else

  % Compute the positions of the volume gray matter
  % data in the inplane coordinate frame.
  % 
  if(~isfield(mrSESSION,'alignment'))
      warndlg('You must load an alignment first...');
      return;
  end
  
  vol2InplaneXform = inv(mrSESSION.alignment);
  
  % We don't care about the last coordinate in (y,x,z,1), so we
  % toss the fourth row of vol2InplaneXform.  Then our outputs will
  % be (y,x,z).
  % 
  vol2InplaneXform = vol2InplaneXform(1:3,:);

  % Get volume and inplane sizes
  %     The function viewSize does not return the dimensions in the desired
  %     order because it does not apply the function mrAnatRotateAnalyze.
  %     Also, let's use viewGet calls when we can.
  volSize = viewGet(vw, 'Anat Size');
  ipView = initHiddenInplane;
  inplaneSize = viewGet(ipView,'Anat Size');

  % Use meshgrid to get volume coordinates
  % 
  [volx,voly]=meshgrid([1:volSize(2)],[1:volSize(1)]);
  totalImSize = volSize(1)*volSize(2);

  % Loop through the z dimension, consing up the volCoords that
  % fall into the inplanes.
  % 
  coords = [];
  % vol2InplanXform needs volCoords in order (y,x,z)
  volCoords = [voly(:),volx(:),zeros([totalImSize,1]),ones([totalImSize,1])];
  volCoords = volCoords';
  waitHandle = mrvWaitbar(0,'Computing volume coordinates.  Please wait...');
  for z = 1:volSize(3)
    mrvWaitbar(z/volSize(3))
    volCoords(3,:) = volCoords(3,:) + 1;
    ipCoords = vol2InplaneXform*volCoords;
    % Find ipCoords that are within the bounds of the inplanes.
    validIndices = ...
	find((ipCoords(1,:)>1) & (ipCoords(1,:)<inplaneSize(1))...
         & (ipCoords(2,:)>1) & (ipCoords(2,:)<inplaneSize(2))...
         & (ipCoords(3,:)>1) & (ipCoords(3,:)<inplaneSize(3)));
    newcoords = [volCoords(1,validIndices);
	volCoords(2,validIndices);
	volCoords(3,validIndices)]; 
    if ~isempty(newcoords)
      coords = [coords, newcoords];
    end
  end
  close(waitHandle)
  coords = round(coords);

  % Fill coords slot
  %
  vw.coords = coords;
  
  % Save to file
  %
  save(pathStr,'coords');
end

return;




%%%%%%%%%
% Debug %
%%%%%%%%%

% Compute coords and save
VOLUME{1} = getVolCoords(VOLUME{1});

% Save coords as an ROI.
ROI.name = 'inplanes';
ROI.viewType = 'Volume';
ROI.coords = VOLUME{1}.coords;
ROI.color = 'red';
saveROI(VOLUME{1},ROI);
VOLUME{1}=loadROI(VOLUME{1},'inplanes');

% Simple test to make sure x and y are correct
% coords here are in the order: (x y z 1)
loadSession
botLeftCoord = [1 mrSESSION.cropInplaneSize(1) 1 1]';
botRightCoord = [mrSESSION.cropInplaneSize(2) mrSESSION.cropInplaneSize(1) 1 1]';
topLeftCoord = [1 1 1 1]';
topRightCoord = [mrSESSION.cropInplaneSize(2) 1 1 1]';
Xform = mrSESSION.alignment(1:3,:);
Xform*botLeftCoord
Xform*botRightCoord
Xform*topLeftCoord
Xform*topRightCoord
