function fgsegment = dtiFiberExcludeDiscontinuous(fg, threshold)

% Remove the fascicles which has discontinuity by VOI-based fiber clipping
%
% Sometimes we create fascicles/streamlines which is discontinuous when we
% clip the fascicles using VOI/ROI (e.g. feConnectomeClip.m in LiFE). This function
% excludes the discontinuous fascicles from the connectome.
%
% INPUT:
% fg: fg structure for input
% threshold: If the nodal spacing exceeds this threshold, the fascicle will
%           be removed
%
% (C) Hiromasa Takemura, 2015 CiNet HHS/Stanford Vista Team

% The matrix to define fascicles to exclude
fascicletoremove = ones(length(fg.fibers),1);

for i=1:length(fg.fibers)
    
    x = fg.fibers{i}(1,:);
    y = fg.fibers{i}(2,:);
    z = fg.fibers{i}(3,:);
    
    try
        % Compute the 3d distance on each node
        for k=1:(length(x)-1)
            nodalspace(k) = sqrt((x(k+1)-x(k))^2 + (y(k+1)-y(k))^2 + (z(k+1)-z(k))^2);
            
            % Remove fascicles when the nodal spacing exceeds the threshold
            if nodalspace(k) > threshold
                fascicletoremove(i) = 0;
            end
            
        end
        
    catch
        % Remove fascicles if the code could not execute the process above
        % This happens when fascicle only contains one node as a consequence of the
        % clipping
        fascicletoremove(i) = 0;
        
    end
    clear nodalspace x y z k
    
end

% Remove fascicles having longer nodal spacing
fgsegment = fgExtract(fg, logical(fascicletoremove), 'keep');
