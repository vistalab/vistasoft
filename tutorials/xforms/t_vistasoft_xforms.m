% TODO: Search for Upsample / rsFactor and replace it with calls to the
% appropriate function, such as ip2functionalCoords
%   
dataDir = fullfile(mrvDataRootPath,'functional','mrBOLD_01');
cd(dataDir);

ip = mrVista;

%% Data formats:
%
% (1) Inplane anatomical (conforms to slab of acquired data, but at resolution
% of inplane anatomy)
%   Only used for alignment to volume and inplane ROIs.
%   Not used ever for functional data
%
%   Example:
disp(size(viewGet(ip, 'anat')))
%  256   256    32
disp(viewGet(ip, 'mmpervox'))
%0.6250    0.6250    2.5000

%% (2) Functional data (resolution and size of EPI)
%
%   Example 1:
disp(viewGet(ip, 'data size'))
%   64    64    32
%
%   Example 2: get mean map from scan 1 (x,y,z)
ip = loadMeanMap(ip);

disp(size(viewGet(ip, 'map scan', 1)))

%%   Example 3: time series 
[~, ni] = loadtSeries(ip, 1);
disp(size(niftiGet(ni, 'data')))
% 64    64    32    96
disp(niftiGet(ni, 'pixdim'))
%     2.5000    2.5000    2.5000    2.0000


% ***************************************
% ******* CONVERSIONS BETWEEN FORMATS ***
% ***************************************

%% -------------------------------
% Inplane anatomical to functional
% --------------------------------
x = 1:20; 
y = ones(size(x)) + 117;
z = ones(size(x)) + 8; % slice dim
ipAnatCoords = [x; y; z];
preserveCoords = 1;preserveExactValues=0;
[ipFuncCoords, inds] = ip2functionalCoords(ip, ipAnatCoords, ...
    1, preserveCoords, preserveExactValues);

% Put these anatomical coords into an ROI
ip = newROI(ip);
ip = viewSet(ip, 'ROI coords', ipAnatCoords);

% Get functional data from the coords
[subdata, indices] = getCurDataROI(ip, 'map', 1);

% Visualize functional / inplane voxel agreement
par_map = zeros(viewGet(ip, 'data size'));
par_map(indices) = 1;
ip = viewSet(ip, 'mapscan', par_map, 1);
ip = viewSet(ip, 'mapclip', [0 1]);
ip = viewSet(ip, 'current slice', 9);
ip = setDisplayMode(ip,'map');
ip = refreshScreen(ip);

%% -------------------------------
% Inplane anatomical to volume
% --------------------------------
ipVoxSize   = viewGet(ip, 'voxel size');
volVoxSize  = viewGet(ip, 'mm per vol vox');
xform       = sessionGet(mrSESSION, 'alignment');
volCoords   = xformROIcoords(ipAnatCoords, xform, ipVoxSize, volVoxSize);

%% -------------------------------------
% Volume coords to gray coords/indices
% --------------------------------------
gr = mrVista('3'); %initHiddenGray;
[grayCoords, indROI, val] = intersectCols(volCoords, viewGet(gr, 'gray coords')); %#ok<*ASGLU>
[tmp, inds] = sort(indROI);
grayIndices = val(inds);
grayCoords  = grayCoords(:,inds);

% Create ROI with these coords
gr = newROI(gr);
gr = viewSet(gr, 'ROI coords', grayCoords);

% find ROI
gr = selectCurROISlice(gr); 
gr=refreshScreen(gr);

%% -------------------------------------
% Volume coords to inplane anatomical
% --------------------------------------
xform = inv(sessionGet(mrSESSION, 'alignment'));
coords = xformROIcoords(volCoords, xform, ...
    viewGet(gr, 'mm per vox'), viewGet(ip, 'mm per vox'));

% We get back most of our inplane anatomical voxels, but with some holes
disp(coords)

% Convert anatomical inplane to functional
[ipFuncCoords, inds] = ip2functionalCoords(ip, coords, ...
    1, preserveCoords, preserveExactValues);

% Put these anatomical coords into an ROI
ip = newROI(ip,'Volume to inplane ROI', 1, 'g');
ip = viewSet(ip, 'ROI coords', coords);

% Get functional data from the coords
[subdata, indices] = getCurDataROI(ip, 'map', 1);

% Visualize functional / inplane voxel agreement
par_map = viewGet(ip, 'map scan', 1);
par_map(indices) = par_map(indices) + 1;
ip = viewSet(ip, 'mapscan', par_map, 1);
ip = viewSet(ip, 'mapclip', [0 2]);
ip = viewSet(ip, 'current slice', 9);
ip = setDisplayMode(ip,'map');
ip = refreshScreen(ip);

%% ---------------------------------------------------
% Example: Transform mean map from Gray to functional
% ----------------------------------------------------
ip = computeMeanMap(ip,1 , 1); 
ip = viewSet(ip, 'map clip', 'auto');
ip = refreshScreen(ip);
gr = ip2volParMap(ip, gr, 1, 1);
gr = setDisplayMode(gr, 'map');
gr = refreshScreen(gr);

% Now go from gray to inplane
% We have a function called ip2volParMap. 
% We now want to write vol2ipParMap.m

ipmap = viewGet(ip, 'mapscan',1);
ip = vol2ipParMap(gr, ip, 1, 1, 'linear');

% test whether the map returned from vol2ipParMap is within tol of the map
% that we started with (ie ip map that got xformed to vol)
ipmap2 = viewGet(ip, 'mapscan',1);

inds = ~isnan(ipmap2);
tol = 10;

figure, imagesc(makeimagestack(ipmap2));colormap gray, axis image off
figure, imagesc(makeimagestack(ipmap));colormap gray, axis image off
figure, imagesc(makeimagestack(ipmap.*inds));colormap gray, axis image off
figure, imagesc(makeimagestack(ipmap.*inds-ipmap2));colormap gray, axis image off
figure, scatter(flatten(ipmap.*inds), flatten(ipmap2)); hold on, plot([0 6000], [0 6000], 'r-')
assert(all(abs(ipmap2(inds) - ipmap(inds))>tol));








%% Question:
% How do we xform functional coords to anatomical ip coords?
% When we do create ROI from functional mask, this functionality is
% probably invoked.
