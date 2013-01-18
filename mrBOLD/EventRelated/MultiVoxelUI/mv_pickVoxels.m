function mv = mv_pickVoxels(mv,dim);
%
% mv = mv_pickVoxels(mv,dim);
%
% Graphically click on a voxel in a MultiVoxel UI
% plot, and create a new MultiVoxel UI for just
% that voxel.
% 
% dim is the dimension in the current axis which
% represents voxels. 1==X, 2==Y. NOTE: this is the
% OPPOSITE of the row/col convention!
%
% EXTRA BEHAVIOR: to make things more complicated, this
% function has a different behavior when the user is browsing
% through single voxel GLM results (which happens when mv.ui.plotType==7). 
% In this case, it produces a multi voxel UI for the selected voxel
% in the voxel slider.
% 
% ras 09/05.
if notDefined('mv'), mv = get(gcf,'UserData'); end
if notDefined('dim')
    if ismember(mv.ui.plotType,[1 3 5]), dim=1;
    else, dim = 2;
    end
    dim
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For visualizing GLMs, get point from voxel slider %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if checkfields(mv, 'ui', 'plotType') & mv.ui.plotType==7
    if ~checkfields(mv, 'ui', 'glmVoxel')
        error('Plot Type is set to 7 -- for GLMs, but no voxel slider.');
        
    else
        voxel = get(mv.ui.glmVoxel.sliderHandle, 'Value');
        mv_selectSubset(mv, voxel, 'voxels', 2);        
        return
        
    end
end

%%%%%%%%%%%%%%
% Get Points %
%%%%%%%%%%%%%%
col = get(gcf,'Color');
set(gcf,'Color','y');


msg='Click left to add voxels, middle to remove voxels, right to quit';
msgboxHandle = mrMessage(msg,'left','ur',12);

button = 1; h = []; I = [];
while button<3
    [X Y button] = ginput(1);
    X = round(X); Y = round(Y);
    
    AX = axis;
    if button==1
        % mark the location of the chosen voxel w/ a line
        if dim==1  % voxels along X axis
            h = [h line([X X],[AX(3) AX(4)],'Color','w')];
        else       % voxels along Y axis
            h = [h line([AX(1) AX(2)],[Y Y],'Color','w')];
        end

        % index into voxel data for this voxel
        if dim==1, I=[I X]; else, I=[I Y]; end
    elseif button==2
        % remove if selected
        if dim==1, rm=X; else, rm=Y; end
        delete(h(I==rm)) % delete the line
        if ismember(rm,I), I = setdiff(I,rm); end
    end
end

close(msgboxHandle);
set(gcf,'Color',col);


%%%%%%%%%%%%%%%%%%%%
% make a new MV UI %
%%%%%%%%%%%%%%%%%%%%
mvNew = mv;
mvNew.tSeries = mvNew.tSeries(:,I);
mvNew.coords = mvNew.coords(:,I);
mvNew.roi.coords = mvNew.roi.coords(:,I);
mvNew.voxData = er_voxDataMatrix(mvNew.tSeries,mvNew.trials,mvNew.params);
mvNew.voxAmps = er_voxAmpsMatrix(mvNew.voxData,mvNew.params);
mvNew.roi.name = sprintf('Subset of %s',mv.roi.name);
mvNew.roi.coords = mv.coords;

mvNew = mv_openFig(mvNew);
figure(mvNew.ui.fig);
multiVoxelUI;

return