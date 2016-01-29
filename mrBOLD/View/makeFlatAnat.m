function anat = makeFlatAnat(view)
%
% function anat = makeFlatAnat(view)
%
% djh, 8/1/99  Culled this stuff out of loadAnat.
% djh, 8/18/99 Modified to use curvature if available.

disp('Interpolating flat images...');

% Initialize to zeros
imSize = view.ui.imSize;
anat = NaN*ones([imSize,2]);

% Loop through hemispheres and make the images with myGriddata
for h=1:2               
    
    % Load gLocs to get 2D coords and Z
    if h==1
        [gLocs2d,gLocs3d,curvature] = loadGLocs('left',view.leftPath);
        
    else
        [gLocs2d,gLocs3d,curvature] = loadGLocs('right',view.rightPath);
        
    end
    if ~isempty(gLocs2d)
        y = gLocs2d(1,:);
        x = gLocs2d(2,:);
        
        
        
        % If curvature is nonempty, then use it.  Otherwise use z coord
        
        if ~isempty(curvature)          
            z = curvature;           
        else
            z = gLocs3d(3,:);          
        end
        
        
        % Remove NaN coords
        allFinite = isfinite(x) & isfinite(y);
        
        
        x = x(allFinite);
        y = y(allFinite);
        
        
        % Deal with new curvature coding: only l1 curvatures are now
        % encoded to make the flat maps look nicer. The following code
        % checks to see if we are building an anatomy from the old or the
        % new version of the flat files.
        if (length(z)<length(x))
            x=x(1:length(z));
            y=y(1:length(z));
        else                     
            z = z(allFinite);
        end
        
        % call griddata        
        yi = [1:imSize(1)]';
        xi = [1:imSize(2)];
        warning off;
        
        if (checkML7)
            disp('Matlab 7 or higher detected..');            
%             anat(:,:,h) = griddata(x,y,z,xi,yi,'linear',{'QJ'});
            anat(:,:,h) = griddata(x,y,z,xi,yi,'linear');
        else         
            anat(:,:,h) = griddata(x,y,z,xi,yi,'linear');
        end
        
        warning backtrace;
    end
end