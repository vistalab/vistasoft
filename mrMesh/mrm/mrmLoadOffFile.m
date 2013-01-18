function msh = mrmLoadOffFile(offFile, origin)
% Buils a basic mrm structure given an OFF format mesh file.
% mrm = mrmLoadOffFile(offFile, origin)
%
% 2007.06.08 RFD wrote it.

if(~exist('offFile','var')||isempty(offFile))
    [f,p] = uigetfile({'*.off';'*.*'},'Select the OFF file...');
    if(isnumeric(f)); disp('user canceled.'); return; end
    offFile = fullfile(p,f);
end
if(~exist('origin','var')||isempty(origin))
    msh.origin = [0 0 0];
else
    msh.origin = origin;
end

% Read new vertex locations
fid = fopen(offFile, 'r', 'ieee-be');
if fid == -1,
  delete(inFile);
  delete(outFile);
  error('Could not open file'); 
end

%--- read .off output file
% Header
hdr = fgetl(fid); 

% First see if we have a SurfRelax patch header
if(strcmp(hdr,'#PATCH'))
    % header information from SURFRelax.  Becuase this file has a subset of
    % vertices from a parent mesh
   msh.parentInds = getSRHeader(fid); 
   hdr = fgetl(fid); 
end

% Now we can read the mesh data
if(strcmp(hdr,'OFF BINARY'))
    % binary format
    n = fread(fid, 3, 'int32');
    % Read the vertices
    msh.vertices = fread(fid, [3 n(1)], 'float32');
    msh.triangles = fread(fid, [5 n(2)], 'int32');
elseif(strcmp(hdr,'OFF'))
   % text format, probably from FSL's bet
   n = fscanf(fid, '%d', 3);
   % Read the vertices
   msh.vertices = fscanf(fid, '%f', [3 n(1)]);
   msh.triangles = fscanf(fid, '%d', [4 n(2)]);
end
fclose(fid);

if(any(msh.origin~=0))
    for ii=1:3
        msh.vertices(ii,:) = msh.vertices(ii,:) - msh.origin(ii);
    end
end
msh.triangles = msh.triangles(2:4,:);

msh.lights = [];
msh.id = -1;

return;

function [parentInds] = getSRHeader(fid)
% This header contains the map from a patch mesh to the parent mesh
foundInds=0;
while ~foundInds
    line = fgetl(fid);
    delI = strfind(line,'=');
    if strcmp(line(1:delI-1),'#patch_dimensions')
        foundInds=1;
        patchInds = sscanf(line(delI+1:end),'%d');
        patchInds = patchInds(1);
    end
end
% Skip a text line
fgetl(fid);
% Get the parent indices for each patch vertex
parentInds = zeros(1,patchInds);
for ii=1:patchInds
    line = fgetl(fid);
    n = sscanf(line,'#%d %d');
    parentInds(ii) = n(2);
end
return;

