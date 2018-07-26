function rgb_matrix = prepareMrMeshPyColourMap(cmap)
% function rgb_matrix = prepareMrMeshPyColourMap(cmap)
% so mrVista uses the convetion of color mapping of scalars to lookup
% tables with 256 entries - the first 128 are used for grayscale mapping of
% the anatomy - light gray for gyri and dark gray for sulci; the 2nd half
% of the table (entries 129-256) are r/g/b/ moldulated channels that the
% scalar data are mapped to relative to a min/max range and some clipping /
% windowing. We'll rescale these 128 colour values to 1:1024 range and then
% send to mrMeshPy

% extract just the colour section of the map
cols = cmap(129:end,:);

% upsample the 128 samples to 1024 samples for each colour vector
r_vec = interp(cols(:,1),8);
g_vec = interp(cols(:,2),8);
b_vec = interp(cols(:,3),8);

%put it all togtether and clean up
rgb_matrix = [r_vec,g_vec,b_vec];

% interpolation causes a slight under/over-shoot so clip to 0-1 range.
rgb_matrix(rgb_matrix<0) = 0;
rgb_matrix(rgb_matrix>1) = 1;


