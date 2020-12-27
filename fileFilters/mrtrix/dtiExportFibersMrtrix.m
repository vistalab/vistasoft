function tck = dtiExportFibersMrtrix(fg, tck_filename)
%
%   tck = dtiExportFibersMrtrix(fg, tck_filename) 
%
%   Saves a FG structure to disk in MRTRIX format (.tck)
%
% INPUTS:
%     fg -           vistasoft fiber group structure
%     tck_filename - file path to output .ick
% 
% OUTPUT:
%     tck - reconstructed TCK file structure. 
%
%   Based on MATLAB functions distributed with mrtrix 0.3
%
%   Note 1. The .tck HEADER is reconstructed before writing to disk from 
%   information found in fg.params. The HEADER does not seem to be necessary
%   to for the final .tck file to be compatible to MRTRIX and mrview.
%
%   Note 2. The HEADER can contain information aboutThe ROIs used for tracking. 
%   However, if multiple ROIs were used for tracking currently the MATLAB code 
%   only stores the last ROI name used. This is a limitation existent in the 
%   original MATLAB code provided with MRTRIX. We could try to solve this but 
%   have not yet.
%
% Brent McPherson, Indiana University (C), 2017
% Updated by Lindsey Kitchell, Indiana University 2017
% Edits to comments by Franco Pestilli

% initialize output
tck = dtiGetFgParams(fg);

% transpose the streamline order
tck.data = fg.fibers';

for ii = 1:length(tck.data)
    % transpose the node order
    tck.data{ii} = tck.data{ii}';

end
clear ii

% save the file w/ mrtrix fxn
write_mrtrix_fibers(tck, tck_filename);

return
end

%%%%%%%%%%%%%%%%%%%%%%
% AUXILIARY FUNCTION %
%%%%%%%%%%%%%%%%%%%%%%
function write_mrtrix_fibers (fibers, filename)
%
% function: write_mrtrix_fibers (fibers, filename)
%
% writes the track data stored as a cell array in the 'data' field of the
% fibers variable to the MRtrix format track file 'filename'. All other fields
% of the fibers variable will be written as text entries in the header, and are
% expected to supplied as character arrays.
%
% 
% This function was originally distributed with mrtrix 0.2/0.3

if ~isfield (fibers, 'data')
  disp ('ERROR: input fibers variable does not contain required ''data'' field');
  return;
end

if ~iscell (fibers.data)
  disp ('ERROR: input fibers.data variable should be a cell array');
  return;
end

f = fopen (filename, 'w', 'ieee-le');
if (f < 1) 
  disp (['error opening ' filename ]);
  return;
end

fprintf (f, 'mrtrix fibers\ndatatype: Float32LE\ncount: %d\n', prod(size(fibers.data)));
names = fieldnames(fibers);
for i=1:size(names)
  if strcmpi (names{i}, 'data'), continue; end
  if strcmpi (names{i}, 'count'), continue; end
  if strcmpi (names{i}, 'datatype'), continue; end
  fprintf (f, '%s: %s\n', names{i}, getfield(fibers, names{i}));
end
fprintf (f, '%s: %s\n', 'timestamp: ', num2str(now)); % This allows visualizing the streamlines in mrview
data_offset = ftell (f) + 20;
fprintf (f, 'file: . %d\nEND\n', data_offset);

fwrite (f, zeros(data_offset-ftell(f),1), 'uint8');
for i = 1:prod(size(fibers.data))
  fwrite (f, fibers.data{i}', 'float32');
  fwrite (f, [ nan nan nan ], 'float32');
end

fwrite (f, [ inf inf inf ], 'float32');
fclose (f);

end