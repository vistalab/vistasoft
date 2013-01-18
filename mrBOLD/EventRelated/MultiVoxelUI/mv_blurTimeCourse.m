function mv = mv_blurTimeCourse(mv);
%
% mv = mv_blurTimeCourse(mv);
%
% Blur the tSeries in a Multi Voxel UI time course, same
% as in blur tSeries plot.
%
%
% ras 03/30/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

nVoxels = size(mv.tSeries, 2);
for v = 1:nVoxels
    mv.tSeries(:,v) = imblur(mv.tSeries(:,v));
end

mv.voxData = er_voxDataMatrix(mv.tSeries, mv.trials, mv.params);

% re-appy GLM if it's already been applied
if isfield(mv, 'glm'), mv = mv_applyGlm(mv); end

if checkfields(mv, 'ui', 'fig')
    set(gcf,'UserData',mv);
    multiVoxelUI;
end



return
