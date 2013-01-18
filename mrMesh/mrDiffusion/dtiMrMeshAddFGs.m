function [handles,msh] = dtiMrMeshAddFGs(handles,msh,showTheseFGs)
%Add the selected fiber groups to the mrMesh window.  
%
% [handles,msh] = dtiMrMeshAddFGs(handles,msh,[showTheseFGs])
%
%   handles is from dtiFiberUI (guidata)
%
%   The show selection list is determined from data in the handles
%   structure. You can over-ride that by specifying a vector of 0s and 1s
%   in showTheseFGs. 0 means don't show, 1 means show.  The length is equal
%   to the number of fiber groups.
%
% See also:  dtiFGShowList, dtiRefreshFigure; dtiMrMesh3AxisImage
%
% HISTORY:
% 2004.09.?? Dougherty & Wandell wrote it.
% 2006.11.21 RFD: fixed a couple of little bugs that affected the rendering
% of fibers with few points 
%
% (c) Stanford VISTA Team 2005

if ~exist('showTheseFGs','var')||isempty(showTheseFGs), 
    showTheseFGs =  dtiFGShowList(handles);
    if(isempty(showTheseFGs)), return; end
end

% This is the list of fiber groups to show
fiberGroups = handles.fiberGroups(showTheseFGs);
defaultAlpha = 255;

stepSizeMm = sqrt(mean(sum(diff(fiberGroups(1).fibers{1},1,2).^2,1)));
skipPoints = round(2./stepSizeMm);

% Display the fiber groups
numGrps = length(fiberGroups);
totalNumActors = 0;
for grpNum=1:numGrps
    fg = fiberGroups(grpNum);
    if(fg.visible)
        fgRgba = uint8(fg.colorRgb);
        sz = size(fgRgba);
        if(sz(2)==3), fgRgba(:,4) = repmat(defaultAlpha,sz(1),1); end
        if(fg.thickness>0)
            % Positive thickness means render as tubes
            clear t;
            t.class = 'mesh';
            [id,s,t] = mrMesh(msh.host, msh.id, 'add_actor', t);
            totalNumActors = totalNumActors+1;
            msh.fiberGroupActors(totalNumActors) = t.actor;

            % This value could change to make really beautiful fibers.  But
            % for exploration, this is fine.  It makes little
            % square/rectangular extrusions.
            t.sides = 5;
            t.radius = fg.thickness;
            t.cap = 1;
            t.points = [];
            % t.points are assembled into a set of tubes separated by a
            % [999,999,999] value.  Inelegant, but OK for now.
            t.color = fgRgba(1,:);
            for ii=1:length(fg.fibers)
                if(size(fg.fibers{ii},2)>skipPoints*10)
                    % We now ensure that we always include the first and last
                    % point. This matters more with metrotrac paths that are
                    % sampled at 2mm.
                    fg.fibers{ii} = horzcat(fg.fibers{ii}(:,1:skipPoints:end-1),fg.fibers{ii}(:,end));
                end
                fg.fibers{ii}(:,end+1) = [999;999;999];
            end
            t.points = horzcat(fg.fibers{:});
            [id,s,r] = mrMesh(msh.host, msh.id, 'tube', t);
        else
            % A negative thickness means render fibers as polylines
            clear t
            t.class = 'polyline';
            t.width = abs(fg.thickness);
            if(sz(1)==1)
                [id,s,r] = mrMesh(msh.host, msh.id, 'add_actor', t);
                totalNumActors = totalNumActors+1;
                msh.fiberGroupActors(totalNumActors) = r.actor(1);
                t.actor = r.actor;
                t.color = uint8(fgRgba);
                % Work-around for fiber color bug in mrMesh. With polylines, it
                % adds a random luminance offset in the range of +/- 8 to the
                % color of each fiber to make individual polylines distinct.
                % But, it donesn't clamp the values at 0,255, so if any of the
                % RGB values are too close to 0,255 the value might wrap and
                % make rainbow colors.
                t.color(t.color(1:3)<8) = 8;
                t.color(t.color(1:3)>247) = 247;
                t.points = [];
                for(ii=1:length(fg.fibers))
                    fg.fibers{ii}(:,end) = [999;999;999];
                end
                t.points = horzcat(fg.fibers{:});
                [id,s,r] = mrMesh(msh.host, msh.id, 'set', t);
            else
                for ii=1:length(fg.fibers)
                    [id,s,r] = mrMesh(msh.host, msh.id, 'add_actor', t);
                    totalNumActors = totalNumActors+1;
                    msh.fiberGroupActors(totalNumActors) = r.actor(1);
                    t.actor = r.actor;
                    if(size(fg.fibers{ii},2)>skipPoints*10)
                        fg.fibers{ii} = horzcat(fg.fibers{ii}(:,1:skipPoints:end-1),fg.fibers{ii}(:,end));
                    end
                    t.points = fg.fibers{ii};
                    t.color = fgRgba(ii,:);
                    t.color(t.color(1:3)<8) = 8;
                    t.color(t.color(1:3)>247) = 247;
                    [id,s,r] = mrMesh(msh.host, msh.id, 'set', t);
                end
                
            end
        end
    end
end

return;
