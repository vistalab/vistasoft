function writeFiberSelection (sel, filename)

% function writeFiberSelection (sel, filename)
% Author: DA

fid = fopen (filename, 'wb');

fwrite (fid, length(sel.selected), 'uint');
fwrite (fid, sel.selected, 'uint');

fclose(fid);

