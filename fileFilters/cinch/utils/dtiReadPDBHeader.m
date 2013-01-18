function header = dtiReadPDBHeader (fid)

if (~exist('fid','var'))
    header = struct();
    header.xformToAcPc = repmat (0, 4);
    header.numPaths = 0;
else
    offset = fread (fid, 1, 'uint');
    mx = fread (fid, 16, 'double');
    header.xformToAcPc = reshape (mx, 4,4);
    fseek (fid, offset-4, -1);
    header.numPaths = fread (fid, 1, 'uint');
end
    
% xxx should contain information about statistics too!