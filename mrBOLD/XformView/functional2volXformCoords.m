function volCoords = functional2volXformCoords(inplane, gray, preserveExactValues)
% Return coords from Volume view that correspond to coords in
% mrVista functional inplane coords
%
%  volCoords = functional2volXformCoords(inplane, gray, preserveExactValues)
%
% We first get a 3xn matrix of functional view coordinates, then find the
% corresponding inplane anatomical coordinates, and finally find the
% corresponding volume  coordinates. We use this transform when
% we want to convert functional data (e.g., a parameter map, coranal, or
% time series) from the volume view to the inplane view.
%
% INPUTS
%   inplane: mrVista view structure (must be an inplane view)
%   gray: mrVista view structure (must be a gray view)
%   preserveExactValues: boolean. If false, return integer coordinates. If
%                   true, return the calculated (non-integer values). If
%                   non-integer values are returned, then the parent
%                   function will have to deal with these, e.g., via
%                   interpolation.
% OUTPUTS
%   volCoords: 3xn matrix of coordinates in Volume space
%                   corresponding to 3xn matrix of inplane functional  coords
%
% Example:
%   volCoords = ip2volXformCoords(inplane, gray)
%
%
% CO & JW 2016.01.14

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(viewGet(inplane, 'viewType'),'Inplane')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(viewGet(gray, 'viewType'),'Volume') &&~strcmp(viewGet(gray, 'viewType'),'Gray')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end


% check inputs
if ~exist('preserveExactValues', 'var'), preserveExactValues = false; end

% we need mrSESSION for the alignment matrix
mrGlobals;

% The gray coords are the integer-valued (y,x,z) volume 
% coordinates that correspond to the inplanes.  Convert to
% homogeneous form by adding a row of ones.
preserveCoords = true;
functionalCoords  = ip2functionalCoords(inplane,    viewGet(inplane, 'coords'), ...
    [], preserveCoords, preserveExactValues);
nVoxels = size(functionalCoords, 2);
functionalCoords  = double([functionalCoords; ones(1,nVoxels)]);

% inplane2VolXform is the 4x4 homogeneous transform matrix that
% takes inplane (y',x',z',1) coordinates into Volume (y,x,z,1)
% coordinates.
inplane2VolXform = sessionGet(mrSESSION,'alignment');

% We don't care about the last coordinate in (y,x,z,1), so we
% toss the fourth row of Xform.  Then our outputs will be (y,x,z).
% 
inplane2VolXform = inplane2VolXform(1:3,:);

% Transform coord positions to the volume.  Hence, grayCoords
% contains the volume position of each of the inplane  voxels.  These
% will generally not fall on integer-valued coordinates, rather they will
% fall between voxels.  Other functions that rely on the output of this
% function will require interpolation to get the data at these
% between-voxel positions.
% 
volCoords = inplane2VolXform*functionalCoords; 

% % Convert coords from inplane anatomical space to inplane functional space.
% % We do this because the anatomical inplane is often higher resolution than
% % the functional data.  We preserve the number of coords so that the number
% % of output functional voxels is identical to the number of gray or volume
% % voxels. If requested, we preserve the exact (non-integer) values, which
% % means that the functional coordinates will lie in locations between the
% % actual functional data points.
% preserveCoords = true;
% volCoords   = ip2functionalCoords(inplane, ipAnatomicalCoords, ...
%     [], preserveCoords, preserveExactValues);

% Some confusion about zeros in the output coordinates. It seems best to
% leave the calculations as they are unless there is a problem that someone
% understands. See below.

% HH, 6/16/2012: If we use the code below, we elimintate some voxels
% and then nVoxels is different from the size of ipCoords, leading to a
% mismatch in the size of the expected time series (tSeries) and the
% size of interpolated tSeries, causing an error in  the line,
%  tSeries(frame,:) = interp3(subData, ...
%                                   ipFuncCoords(2,:), ...
%                                   ipFuncCoords(1,:), ...
%                                   ipFuncCoords(3,:), ...
%                                   method);
%
% Hence we comment out the lines below. Leaving in the values with 0
% did not produce an error, at least for the function we tested it on,
% ip2volTSeries.
% 
% % ras 12/20/04:
% % occasionally the xformed grayCoords will include a 0
% % coordinate. While it seems this should not happen,
% % I'm applying this band-aid for the time being:
% [badRows badCols] = find(ipFuncCoords==0); %#ok<ASGLU>
% goodCols = setdiff(1:nVoxels, badCols);
% ipFuncCoords = ipFuncCoords(:,goodCols);
% if length(badCols)>1
%     fprintf('%i voxels mapped to slice 0...\n',length(badCols));
% end


return
