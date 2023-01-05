function coords=rotateCoords(vw,coords,inverseFlag)
% coords=rotateCoords(vw,coords,[inverseFlag])
% PURPOSE: Rotates the coords by the value in
% vw.rotateImageDegrees(currentSlice)
% 
% So that we can have arbitrary rotations of our flat maps
% Inverse flag allows you to rotate coordinates in the opposite direction
% (for adding
% as opposed to displaying ROIs)
if(~exist('inverseFlag','var'))
    inverseFlag=0;
end

% updated, now using truecolor, image may be 3D
% midPoint = (size(vw.ui.image(:,:,1)))/2;
midPoint = vw.ui.imSize ./ 2;

% To rotate the coordinates correctly, we need to zero-center the
% coords.
[y x]=size(coords);
mpOffset=repmat(midPoint',1,x);

% See what rotation we want
if (strcmp(vw.viewType,'Flat'))
    [rotations,flipLR]=getFlatRotations(vw);
    rotateDeg=rotations(viewGet(vw, 'current slice'));  
    flipFlag=flipLR(viewGet(vw, 'current slice'));
    
    % Only do this if a rotations ~=0 was asked for
	if (rotateDeg || flipFlag) % Do nothing if this is zero
        
        if (inverseFlag)
            angRad=-rotateDeg*pi/180;
        else
            angRad=rotateDeg*pi/180;    
        end
        
        % Build the rotation matrix.
        if (flipFlag) % Do we do a L/R flip?
            if(inverseFlag) % if we are inverting the rotation we flip, then rotate
                rotMat=[cos(angRad) -sin(angRad);-sin(angRad) -cos(angRad)];
            else % Else rotate then flip
                rotMat=[cos(angRad) sin(angRad);sin(angRad) -cos(angRad)];
            end
        
        else % Just make a straight rotation matrix
            rotMat=[cos(angRad) -sin(angRad);sin(angRad) cos(angRad)];
        end
     
        rot_coords=coords(1:2,:);
        
        rot_coords=rot_coords-mpOffset;
        rot_coords=rot_coords'*rotMat;
        
        coords(1:2,:)=round(rot_coords'+mpOffset);
	end
end
    
return;
