function [coords, outMat] = coordsXform(xform, coords)
%
% [xformedCoords, outMat] = coordsXform(xform, coords)
%
% Transforms a list of coords given the affine transform matrix 'xform'.
%
% Alternatively, xform can be a full deformation field. In that case, it
% should be a struct with the following five fields:
% 1-3: deformation field- xform.deformX, xform.deformY, xform.deformZ
% 4: xform.inMat xforms the input coords to the deformation field space, 
% 5: xform.outMat (optional) is applied to the coords that come out of 
% the deformation field.
% OR- xform can be an SPM-style deformation (ie. from an sn3d or sn file)
%
% Optionally returns the output xform matrix- a 4x4 affine that is applied
% to the coordinates after they are deformed. Eg. a deformation filed might
% be expressed in ac-pc space, and outMat is the xform that converts ac-pc
% space to image space. (and thus, inv(outMat) would get back to ac-pc).
%
% HISTORY:
%   2003.07.09 RFD (bob@white.stanford.edu) wrote it.
%   2005.01.17 RFD: added option of passing a deformation field instead of
%   an affine xform.
%   2005.06.16 RFD: renamed from dtiXformCoords and moved to Anatomy module.
% ras, 07/05: renamed coordsXform and moved into mrVista 2.0 repository.
if(isempty(coords)),        return;                                 end
if(size(coords,2)~=3),      coords = coords';                       end
if(size(coords,2)~=3),      error('coords must be an Nx3 array!');  end
if ~isa(coords, 'double'),  coords = double(coords);                end    

outMat = [];
if(isstruct(xform))
    if(isfield(xform,'deformX'))
        
        % then it's a deformation field. We expect five fields:
        % the deformation field, in xform.deformX, xform.deformY, xform.deformZ
        % two 4x4 affine matrices, inMat xforms the input coords to the
        % deformation field space, and outMat is applied to the coords that come 
        % out of the deformation field.
        coords = xform.inMat*[coords,ones(size(coords,1),1)]';
        coords = coords(1:3,:)';
        
        % interpolate the deformation field using trilinear
        sz = size(xform.deformX);
        
        % myCinterp3 likes the x,y flipped.
        oldCoords = coords(:,[2,1,3]);
        
        % When interpolating a deformation field, we must be careful about
        % the values returned for out-of-range points.
        coords(:,1) = myCinterp3(double(xform.deformX), [sz(1) sz(2)], sz(3), oldCoords, xform.deformX(end))';
        coords(:,2) = myCinterp3(double(xform.deformY), [sz(1) sz(2)], sz(3), oldCoords, xform.deformY(end))';
        coords(:,3) = myCinterp3(double(xform.deformZ), [sz(1) sz(2)], sz(3), oldCoords, xform.deformZ(end))';
        
        %coords = round(oldCoords);
        %defInds = sub2ind(size(xform.deformX), coords(:,1), coords(:,2), coords(:,3));
        %coords = double([xform.deformX(defInds), xform.deformY(defInds), xform.deformZ(defInds)]);
        if(isfield(xform, 'outMat') & ~isempty(xform.outMat) & ~all(all(xform.outMat==eye(4))))
            coords = xform.outMat*[coords,ones(size(coords,1),1)]';
            coords = coords(1:3,:)';
            outMat = xform.outMat;
        end
        
    elseif(isfield(xform,'Affine'))   
        
        % SPM-style deformation params
        coords = mrAnatGetImageCoordsFromSn(xform, coords)';
        if(isfield(xform, 'outMat') & ~isempty(xform.outMat) & ~all(all(xform.outMat==eye(4))))
            coords = xform.outMat*[coords,ones(size(coords,1),1)]';
            coords = coords(1:3,:)';
            outMat = xform.outMat;
        end
        
    elseif(isfield(xform,'talScaleDir'))
        
        % Dougherty Talairach-scale struct
        if(strcmp(lower(xform.talScaleDir),'acpc2tal'))
            coords = mrAnatAcpc2Tal(xform,coords)';
        elseif(strcmp(lower(xform.talScaleDir),'tal2acpc'))
            coords = mrAnatTal2Acpc(xform,coords)';
        else
            error('Incorrect talScaleDir- must be ''acpc2tal'' or ''tal2acpc''.');
        end
        
        if(isfield(xform, 'outMat') & ~isempty(xform.outMat) & ~all(all(xform.outMat==eye(4))))
            coords = xform.outMat*[coords,ones(size(coords,1),1)]';
            coords = coords(1:3,:)';
            outMat = xform.outMat;
        end
        
    else
        
        error('Unrecognized xform struct!');
        
    end
    
else
    
    coords = xform*[coords,ones(size(coords,1),1)]';
    coords = coords(1:3,:)';

end

return;
