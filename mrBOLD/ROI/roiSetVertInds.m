function vw = roiSetVertInds(vw, prefs)
%  Add a field to each current ROI with the mesh vertices needed to show
%  the ROI. By storing these values in the ROI field, they do not have to
%  be computed each time the mesh is updated. This significantly speeds the
%  update process.
%
% vw = roiSetVertInds([vw], [prefs])
%
% See roiRemoveVertInds.m 
%
% Example: vw = roiSetVertInds(vw); 
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

msh  = viewGet(vw, 'currentmeshnumber');
if isempty(msh), warning('need a mesh to get ROI vertex indices'); return; end
     

%% Set the ROI vert indices
nROIs = length(viewGet(vw, 'ROIs'));
verbose = prefsVerboseCheck;

for roi = 1:nROIs

    % Because this code can be slow, display some progress...
    if verbose 
        fprintf('[%s]: Adding vertex indices to ROI %d\n', mfilename, roi); 
    end
       
    roiVertInds = viewGet(vw, 'roiVertInds', roi, prefs);
    
    vw = viewSet(vw, 'roivertinds', roiVertInds, roi, prefs);

end