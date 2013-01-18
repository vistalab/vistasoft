function vw = roiSetVertIndsAllMeshes(vw, prefs)
%  Wrapper to set mesh vertex indices for all open ROIs and all open
%  meshes. Once the verInds field is added to the ROI structs, the meshes
%  can be updated more quickly.
%
% vw = roiSetVertIndsAllMeshes([vw], [prefs])
%
% Example: vw = roiSetVertIndsAllMeshes(vw); 
%
% 8/2009: JW

%% Variable check
if ~exist('vw', 'var'),  
    % this takes a LONG time!
    vw = getCurView; 
end

if ~exist('prefs', 'var'),  
    prefs = mrmPreferences; 
end

curmsh  = viewGet(vw, 'currentmeshnumber');
if isempty(curmsh), return; end
     
allmeshes = viewGet(vw, 'allMeshes');

for m = 1:length(allmeshes)
    vw = viewSet(vw, 'curmeshn', m); 
    vw = roiSetVertInds(vw, prefs); 
end

vw = viewSet(vw, 'curmeshn', curmsh);

end