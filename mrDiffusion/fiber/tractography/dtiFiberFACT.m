function fiberPath = dtiFiberFACT(seedPoint, vecImg, faImg, voxSize, direction, faThresh, rThresh, angleThresh, options)% fiberPath = dtiFiberFACT(seedPoint, vecImg, faImg, voxSize, direction, faThresh, rThresh, options)% Implementation of the Mori Fiber Assignment by Continuous Tracking (FACT)% algorithm. Eg:%    Mori et. al. (2002). Imaging cortical association tracts in the%    human brain using diffusion-tensor-based axonal tracking. Magnetic%    Resonance in Medicine, 47:215-223.%% options include:% 'noCrossPath'- stops tracking when a fiber tries to cross it's own path.% % HISTORY:%   2003.05.15 RFD (bob@white.stanford.edu) wrote it.%
if(~exist('angleThresh','var') | isempty(angleThresh))    angleThresh = 180;end
% Parse optionsif(~exist('options','var'))    options = {};endnoCrossPath = ~isempty(strmatch('nocrosspath',lower(options)));   

% Mori likes to use '4' for this parameter, which is related to the% Coherence Index. It is used as a stopping criteria, to end a fiber trace% when the directions in a neighborhood get too incoherent.% This parameter determines the neighborhood size- it specifies the number% of neighbors to include.numNeighborsR = 4; 
% voxel face coordinates (from center of voxel)vFace = [voxSize/2; -voxSize/2];
% The coordinate ordering is x,y,z,-x,-y,-zvIndex =  [1 0 0; 0 1 0; 0 0 1; -1 0 0; 0 -1 0; 0 0 -1]';
inVoxThresh = voxSize/2 + 0.001;
% set trace direction (order that faces in voxel are searched for closest)if (direction>0)    traceDir = 1:6;    % trace 'forward'else    traceDir = 6:-1:1; % trace 'backward'end

% vCoord holds the coordinates of the current voxel and vPos holds the% current position of the origin of the tracing vector within that voxel. % That is, vCoords is the integer x,y,z coordinate of the voxel and vPos % is a real-valued position relative to the voxel center.vCoordNew = round(seedPoint(:));
% We no longer start at the voxel center. Now, we let the caller specify% where to start by passing a non-integer start point.vPosNew = seedPoint(:)-vCoordNew;if(all(vPosNew==0))    vPosNew = [.5;.5;.5];end% array to hold positionInVoxel and voxel path historyvPosPath = vPosNew';vCoordPath = vCoordNew';

%==================
% MAIN TRACING LOOP
%==================
iter = 0;done = 0;maxIter = 1000;imSize = size(vecImg(:,:,:,1));while (~done & iter<maxIter)    vPos = vPosNew;    vCoord = vCoordNew;
    if(any(vCoord<1) | any(vCoord>imSize'))
        disp('Tracking terminated: path wandered outside image data.');        done = 1;    else
        
        % Get direction vector for this voxel
        vDir = [ vecImg(vCoord(1), vCoord(2), vCoord(3), 1); ...                vecImg(vCoord(1), vCoord(2), vCoord(3), 2); ...                vecImg(vCoord(1), vCoord(2), vCoord(3), 3); ];
        
        % Get the FA for this voxel        fa = faImg(vCoord(1), vCoord(2), vCoord(3));
        
        % Compute R, the sum of the inner-product of the neighbors        % Find the numNeighborsR nearest neighbors

        
        % check vDir data is valid (we are in range)
        if (isnan(fa) | fa < faThresh | sum(vDir) == 0)
            disp(['Tracking terminated: fa=',num2str(fa)]);
            done = 1;
        else
            % calculate where this vector intersects the planes of the voxel faces. 
            % We only need a scalar for each face- essentially, the magnitude
            % of the direction vector along each axis in both + and - directions.
            % Eg., the coordinates of the intersection point for the first face is 
            % vPos + voxFaces(1) .* vDir.
            voxFaces = (vFace - [vPos; vPos]) ./ [vDir; vDir];
            
            % now, find the nearest non-zero face. Note that zero values
            % indicate faces that contain the origin of this vector (ie.
            % vPos == vFace).
            index = [];
            for k=traceDir 
                % isInVoxel(vPos + voxFaces(k).*vDir, voxSize)
                %[k,abs(vPos + voxFaces(k).*vDir)']
                if (voxFaces(k)~=0 & all(abs(vPos + voxFaces(k).*vDir) <= inVoxThresh))
                    index(end+1) = k;
                end            
            end
            if (isempty(index))
                disp('Tracking terminated: index empty');
                done = 1;
            else            
                vCoordNew = repmat(vCoord,1,length(index)) + vIndex(:,index);
                % The position within the next voxel is the intersection                % point of this vector with the nearest face in the current                % voxel (vPos + voxFaces(index).*vDir), but shifted over to the                % new voxel's coordinate frame ( - voxSize.*vIndex(:,index)).                % The problem with the original code was that the small                % rounding errors would accumulate and eventually the vPos                % would fall quite a distance from the voxel face. So, we force                % it to realign with a voxel face.                vPosNew = repmat(vPos,1,length(index)) + vDir*voxFaces(index)' - repmat(voxSize,1,length(index)).*vIndex(:,index);

                if(size(vCoordPath,1)>1 & length(index)>1)
                    % select the direction that gives the smoothest fiber
                    prevPos = vCoordPath(end-1,:) + vPosPath(end-1,:)./voxSize';                    dist1 = sum((prevPos - (vCoordNew(:,1)' + vPosNew(:,1)'./voxSize')).^2);                    dist2 = sum((prevPos - (vCoordNew(:,2)' + vPosNew(:,2)'./voxSize')).^2);                    if(dist1>dist2)
                        vCoordNew = vCoordNew(:,1);
                        vPosNew = vPosNew(:,1);
                    else
                        vCoordNew = vCoordNew(:,2);
                        vPosNew = vPosNew(:,2);
                    end
                else
                    vCoordNew = vCoordNew(:,1);
                    vPosNew = vPosNew(:,1);
                end
                
                % Check the angle threshold
                if(angleThresh < 180 & size(vCoordPath,1)>1)
                    backTwoPos = vCoordPath(end-1,:) + vPosPath(end-1,:)./voxSize';
                    backOnePos = vCoordPath(end,:) + vPosPath(end,:)./voxSize';
                    % The angle between two vectors is given by acos(A*B/a*b)  
                    % (A*B is the dot-product of the two vectors and a*b is the
                    % product of their magnitudes)
                    A = backOnePos - backTwoPos;
                    B = (vCoordNew' + vPosNew'./voxSize') - backOnePos;
                    magProd = (sqrt(sum(A.^2)) * sqrt(sum(B.^2)));
                    if(abs(magProd)>0)
                        angle = abs(acos( (A*B') ./ magProd)/pi*180);
                    else
                        angle = 0;
                    end
                    %disp(['angle: ' num2str(angle)]);
                    if(angle>angleThresh)
                        disp(['Tracking terminated: angle (' num2str(round(angle)) ') exceeds threshold.']);
                        done = 1;
                    end
                end
                
                % Don't allow a fiber to loop back on itself
                if(~done & ~noCrossPath | isempty(intersect(vCoordPath, vCoordNew', 'rows')))                    vPosPath = [vPosPath; vPosNew'];                    vCoordPath = [vCoordPath; vCoordNew'];                else
                    disp('Tracking terminated: path folded on itself');
                    done = 1;
                end
            end
        end
    end
    iter = iter+1;
end
% Return the real-valued fiber path:
fiberPath = vCoordPath + vPosPath./repmat(voxSize',size(vPosPath,1),1);
%disp(fiberPath);return;


% --------------------------------------------------------------------
function  inVoxel = isInVoxel(point, Vsize)% returns 1 for point inside voxel, 0 for outside

% Following is a fudge factor to allow for small precision-limit errors.
epsilon = 0.01;
inVoxel = all(abs(point) <= Vsize/2+epsilon);
return;
