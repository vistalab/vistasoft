function [h,msh] = dtiMrMeshAddROIs(h,msh,showTheseRois)
%
%   [h,msh] = dtiMrMeshAddROIs(h,msh,[showTheseRois])
%
%Author: Wandell,Dougherty
%Purpose:
%    Add the selected Rois to the mrMesh window.
%    h is from dtiFiberUI
%    In general, the selection list is determined from the h
%    structure. But you can over-ride by specifying showTheseRois.
%

if ieNotDefined('h'), error('dtiFiberUI h required.'); end
if ieNotDefined('msh'), msh = dtiGet(h,'mrMesh'); end
if ieNotDefined('showTheseRois')
    showTheseRois = dtiROIShowList(h);
    if isempty(showTheseRois), return; end
end

%
clear p;
roi.scale = [1 1 1];
% Adjusts smoothing/shrinking of the ROIs.
roi.do_smooth = 1;
roi.do_smooth_pre = 0;
roi.smooth_iterations = 15;
roi.smooth_relaxation = 0.12;
roi.do_decimate = 1;
roi.decimate_reduction = 0.1;
roi.decimate_iterations = 1;
roi.class = 'mesh';

% The bounding box is defined in Talairach spce. We will usee this to
% build a volume in which we'll set pixels and have mrMesh convert the
% volume to a mesh.
bb = [-80,80;-120,85;-45,85];
roiTransparency = 0.5;
for(ii=showTheseRois)
    if(h.rois(ii).visible)
        %         if 0
        %             % Check caching again.
        %             % if(h.rois(ii).dirty==0 & isfield(h.rois(ii), 'mesh') & ~isempty(h.rois(ii).mesh))
        %             clear p; p.class = 'mesh';
        %             [id,s,p] = mrMesh(msh.host, msh.id, 'add_actor', p);
        %             h.rois(ii).mesh.actor = p.actor;
        %             msh.roiActors(ii) = p.actor;
        %             [id,s,r] = mrMesh(msh.host, msh.id, 'set_mesh', h.rois(ii).mesh);
        %             p.origin = h.rois(ii).mesh.origin;
        %             [id,s,r] = mrMesh(msh.host, msh.id, 'set', p);
        %             mrmSet(msh,'refresh');
        [id,s,tmp] = mrMesh(msh.host, msh.id, 'add_actor', roi);
        % We have to save the ROI actor here in msh.roiActors list so
        % we can clear out old ROIs even if the user deletes them from
        % the ROIs list.
        msh.roiActors(ii) = tmp.actor;
        p = roi;
        p.actor = tmp.actor;
        %
        % * * * * * * * * * * * * * * * * * *
        % * * * HACK ALERT! HACK ALERT! * * *
        % * * * * * * * * * * * * * * * * * *
        %
        % ROIs with exactly 2 coordinates are rendered as boxes,
        % where the two points specify the opposite corners. To do
        % this properly, we need to expand the ROI struct to allow
        % something like a 'type' field, where one type is 'points'
        % (the standard way in which we define ROIs) and another
        % type might be 'box', etc.
        if(size(h.rois(ii).coords,1)==2)
            
            clear p;
            p.actor = tmp.actor;
            p.vertices = zeros(3,8);
            p.vertices(:,1) = h.rois(ii).coords(1,:)';
            p.vertices(:,2) = [h.rois(ii).coords(1,1) h.rois(ii).coords(1,2) h.rois(ii).coords(2,3)]';
            p.vertices(:,3) = [h.rois(ii).coords(2,1) h.rois(ii).coords(1,2) h.rois(ii).coords(2,3)]';
            p.vertices(:,4) = [h.rois(ii).coords(2,1) h.rois(ii).coords(1,2) h.rois(ii).coords(1,3)]';
            p.vertices(:,5) = [h.rois(ii).coords(1,1) h.rois(ii).coords(2,2) h.rois(ii).coords(1,3)]';
            p.vertices(:,6) = [h.rois(ii).coords(1,1) h.rois(ii).coords(2,2) h.rois(ii).coords(2,3)]';
            p.vertices(:,7) = [h.rois(ii).coords(2,1) h.rois(ii).coords(2,2) h.rois(ii).coords(1,3)]';
            p.vertices(:,8) = h.rois(ii).coords(2,:)';
            p.triangles = [0 3 2; 2 1 0; 0 1 5; 5 4 0; 0 4 6; 6 3 0; 1 2 7; 7 5 1; 2 3 6; 6 7 2; 7 6 4; 4 5 7]';
            p.colors = repmat(uint8(round(dtiRoiGetColor(h.rois(ii), roiTransparency)'.*255)), 1, 8);
            p.origin = [0 0 0];
            [id,s,r] = mrMesh(msh.host, msh.id, 'set_mesh', p);
            % *** FIX ME: the box rendered with the above code
            % doesn't quite look right where it intersects other
            % objects. Note sure how to fix it.
        else
            p.voxels = zeros([diff(bb')+1]);
            goodCoords = h.rois(ii).coords(:,1)>bb(1,1) & h.rois(ii).coords(:,2)>bb(2,1) & h.rois(ii).coords(:,3)>bb(3,1) ...
                & h.rois(ii).coords(:,1)<bb(1,2) & h.rois(ii).coords(:,2)<bb(2,2) & h.rois(ii).coords(:,3)<bb(3,2);
            
            inds = sub2ind(size(p.voxels), ...
                round(h.rois(ii).coords(goodCoords,1)-bb(1,1)+1), ...
                round(h.rois(ii).coords(goodCoords,2)-bb(2,1)+1), ...
                round(h.rois(ii).coords(goodCoords,3)-bb(3,1)+1));
            p.voxels(inds) = 1;
            %p.colors = uint8([rgb(:,labels==h.rois(ii).color);255]);
            % The following should work, but does nothing. So, we'll
            % set the color of each vertex below.
            %p.colors = uint8(round(dtiRoiGetColor(h.rois(ii), roiTransparency).*255));
            [id,s,r] = mrMesh(msh.host, msh.id, 'build_mesh', p);
            clear p;
            p.actor = tmp.actor;
            p.origin = bb(:,1);
            [id,s,r] = mrMesh(msh.host, msh.id, 'set', p);
            % Why can't I just set the color of the whole mesh? This used to work!
            p.get_colors = 1;
            [id,s,r] = mrMesh(msh.host, msh.id, 'get', p);
            % Note that the ROI color may be a rgba, in which case the default
            % tranparency set here would be over-written.
            p.colors = repmat(uint8(round(dtiRoiGetColor(h.rois(ii), roiTransparency)'.*255)), 1, size(r.colors,2));
            [id,s,r] = mrMesh(msh.host, msh.id, 'modify_mesh', p);
        end
        
        clear p;
        p.actor = tmp.actor;
        p.get_all = 1;
        [id,s,r] = mrMesh(msh.host, msh.id, 'get', p);
        h.rois(ii).mesh = r;
        h.rois(ii).mesh.actor = tmp.actor;
        h.rois(ii).dirty = 0;
    end
end

return;
