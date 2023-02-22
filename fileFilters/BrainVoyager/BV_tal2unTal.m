function coords = BV_tal2unTal(coords,talPath);
% 
% coords = BV_tal2unTal(coords,talPath);
%
% An interface that calls talairachToVol from the Wandell lab anatomy
% tools; takes a set of coordinates in talairach space and converts them
% into coordinates for the current mrLoadRet (un-talled) volume. Requires
% that you have run computeTalairach.m on this volume, and saved the
% results to a .mat file somewhere (talPath).
%
% 03/03 ras

% if no talairach transformation matrix is specified,
% prompt for a BV .tal file containing this information
if ~exist('talPath','var')
    disp('Choose a .mat file containing the talairach points for this volume');
    disp('(See ''help computeTalairach'' if you are unsure of what this is.)');
    msg = ['Choose a .mat file from coputeTalairach...'];
    talPath = getPathStrDialog(pwd,msg,'*.mat');
 end
   
% load vol2Tal struct from the talairach file
load(talPath,'vol2Tal');

% use vol2Tal to convert coordinates to unTal
coords = talairachToVol(coords,vol2Tal);

return