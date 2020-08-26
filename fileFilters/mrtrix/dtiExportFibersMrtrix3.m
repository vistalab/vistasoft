function tck = dtiExportFibersMrtrix3(fg, tck_filename)
%
%   tck = dtiExportFibersMrtrix3(fg, tck_filename) 
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
% This function is a modification of dtiExportFibersMrtrix.m, by incorportating header information of MRTrix 3 .tck format ("mrtrix tracks"). 
%
% Written by Hiromasa Takemura, CiNet BIT 2020 August 
% 

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

fprintf (f, 'mrtrix tracks\ndatatype: Float32LE\ncount: %d\n', prod(size(fibers.data)));
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