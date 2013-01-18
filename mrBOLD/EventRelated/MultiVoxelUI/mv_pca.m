function mv = mv_pca(mv,centered);
%
% mv = mv_pca([mv],[centered]);
%
% Perform PCA on multi-voxel data.
%
%
%
% ras 05/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('centered')
    % this is currently not used, 
    % since I always do it both ways
    centered = 1;
end

% get the voxels x conditions amplitudes matrix
amps = mv_amps(mv);

% apply PCA
[pcs score k Uk Lk] = pca_all(amps); % kalanit's code, uncentered
eigenvals = Lk(sub2ind(size(Lk),1:k,1:k));      % diagonal entries of gamma mat
varExplained = 100 .* eigenvals ./ sum(eigenvals);     % percent variance explained

% redo centered, using MATLAB command
[pcs score latent tsquare] = princomp(amps); 

% add to mv struct
mv.pca.pcs = pcs;
mv.pca.score = score;
mv.pca.latent = latent;
mv.pca.tsquare = tsquare;
mv.pca.k = k;
mv.pca.Uk = Uk;
mv.pca.Lk = Lk;


% if a UI exists, visualize, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
    figure(mv.ui.fig)
    multiVoxelUI; % refresh UI
end


return