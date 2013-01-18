function  dtiShowFGs(handles)
% Overlay fiber groups (FGs) on the inplane images in the Matlab dtiFiberUI
% window. 
%
%   dtiShowFGs(handles)
%
%HISTORY
% Author: Dougherty, Wandell
%
% Stanford VISTA Team

if isempty(handles.fiberGroups), return; end

showTheseFgs = dtiFGShowList(handles);
curPosition  = str2num(get(handles.editPosition, 'String')); %#ok<ST2NM>
glassbrain   = get(handles.cbGlassBrain,'Value');
% markSize = 8;

for grpNum = showTheseFgs
    nfibers = length(handles.fiberGroups(grpNum).fibers);
    if(nfibers > 0 && handles.fiberGroups(grpNum).visible)
        % This takes a long time with many fibers. We speed things up by
        % quantizing to a grid and doing 'unique'.
        fp = horzcat(handles.fiberGroups(grpNum).fibers{:});
        fiberColor = [handles.fiberGroups(grpNum).colorRgb./255];
        fp = fp';
        fp = round(fp);
        fp = unique(fp,'rows');
        axes(handles.z_cut);
        if (~glassbrain)
            nfp = fp(round(fp(:,3))==round(curPosition(3)), :);
        else
            nfp = fp;
        end
        hold on;
        h = scatter(nfp(:,1), nfp(:,2), '.');
        set(h, 'MarkerEdgeColor', fiberColor);
        %set(h,'MarkerSize',markSize);
        hold off;
        
        axes(handles.y_cut);
        if (~glassbrain)
            nfp = fp(round(fp(:,2))==round(curPosition(2)), :);
        else
            nfp = fp;
        end
        hold on;
        h = scatter(nfp(:,1), nfp(:,3), '.');
        set(h, 'MarkerEdgeColor', fiberColor);
        %set(h,'MarkerSize',markSize);
        hold off;
        
        axes(handles.x_cut);
        if (~glassbrain)
            nfp = fp(round(fp(:,1))==round(curPosition(1)), :);
        else
            nfp = fp;
        end
        hold on;
        % h = scatter(nfp(:,2), size(anat,3)+1-nfp(:,3), 'r.');
        % To flip the fiber positions left right we just need to use 
        % some formula for flipping LR
        h = scatter(nfp(:,2), nfp(:,3), '.');
        set(h, 'MarkerEdgeColor', fiberColor, 'HitTest', 'off');
        %set(h,'MarkerSize',markSize);
        hold off;
    end
end

return;
