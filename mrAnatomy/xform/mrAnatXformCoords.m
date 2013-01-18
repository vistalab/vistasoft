function [coords, outMat, imScale] = mrAnatXformCoords(xform, coords, transposedOutput)
%Transforms a list of coords given the transform structure 'xform'.
%
% [xformedCoords, outMat, imScale] = mrAnatXformCoords(xform, coords, [transposedOutput=true])
%
% Coords should be an 3xN array, although a Nx3 will work, as long as it is
% not ambiguous (ie. 3x3). Returns an Nx3 array of transformed coords.
%
% Example:
%   imgCoords  = mrAnatXformCoords(nifti.qto_ijk, acpcCoords);
%   acpcCoords = mrAnatXformCoords(nifti.qto_xyz, imgCoords);
%
% The xform can be one of several types of objects.
%
% 1. a 4x4 affine transformation matrix (pre-multiply convention) that
%    specifies the mapping from input coords to the output coords.
%
% 2. a deformation field: a struct with the following five fields:
%     1-3: deformation field- xform.deformX, xform.deformY, xform.deformZ
%     4: xform.inMat xforms the input coords to the deformation field space, 
%     5: xform.outMat (optional) is applied to the coords that come out of 
%        the deformation field.
%
% 3. a coordinate LUT struct (simplfied & fast deformation), with inMat and
%    coordLUT fields. Should work the same as in the deformation field case,
%    but there is no interpolation of the coordLUT (ie. nearest-neighbor)
%    as the code is optimized for speed. We use this for getting
%    standard-space coords (e.g., MNI) given native image coords.
%
% 4. an SPM-style deformation (ie. from an sn3d or sn file). SPM2 and SPM5
%    formats are supported. Note that if no outMat is provided, outmat is
%    assumed to be inv(xform.VF.mat). This will do the right thing if the
%    input image is in the same space as the image used to align to the
%    template (e.g., you are applying sn to the same image used to compute
%    sn). If you don't want any outMat (e.g., you want to convert template
%    coords to acpcCoords), then set sn.outMat=[].  
%
% 5. a struct defining the Rohde et. al. (MRM 2004) eddy-current correction
%    deformation. This struct should include the following fields:
%     1. ecParams- the 14 parameters that Rohde et al. propose. The first
%        six are the rigid-body motion-correction params (translations in
%        1-3, rotations in 4-6). The remaining eight are the eddy-current
%        warping parameters (Rohde et al's 'c' parameters used to estimate
%        their b_eddy). 
%     2. phaseDir- a scalar in the range 1-3 indicating the phase-encoding
%        direction. E.g., 2 indictes phase encoding along the second
%        dim (second column of coords). Note that the eddy-correction
%        warping only affects this row of coords.
%     3. You may also include an inMat, which will be applied to the
%        coordinates before applying the motion correction. E.g., a
%        transform to standard space (like ac-pc) would go here.
%
% Note that for any 'struct' form of xform, additional fields are
% simply ignored.
%
% Optionally returns the output xform matrix- a 4x4 affine that is applied
% to the coordinates after they are deformed. Eg. a deformation field might
% be expressed in ac-pc space, and outMat is the xform that converts ac-pc
% space to image space. (and thus, inv(outMat) would get back to ac-pc).
%
% TODO: change return to 3xN to avoid the transpose. It takes a non-trivial
% amount of time with large sets of coords.
%
% HISTORY:
%   2003.07.09 RFD (bob@white.stanford.edu) wrote it.
%   2005.01.17 RFD: added option of passing a deformation field instead of
%   an affine xform.
%   2005.06.16 RFD: renamed from dtiXformCoords and moved to Anatomy module.
%   2007.02.28 RFD: For SPM-style 'sn' xforms, we now use a default outMat
%   (if one isn't provided) that will do the right thing, as long as the
%   input image is in the same space as the image used to align to the
%   template.
%   2007.05.03 RFD: Added support for Rohde et. al. (MRM 2004) eddy-cuurent
%   deformations. Also cleaned up help text.
%
% Bob (c) VISTASOFT Team

if(~exist('transposedOutput','var') || isempty(transposedOutput)) 
    transposedOutput = true;
end

if(isempty(coords)) % br: This is going to fail since outMat and imScale will be undefined
    % outMat = eye(4);
    % imScale = [];
    return;
end

if(size(coords,1)~=3)
    coords = coords';
end
if(size(coords,1)~=3)
    error('coords must be an 3xN array!');
end

% Do something different depending on the xform structure
outMat = eye(4);
imScale = [];
if(isstruct(xform))
    if(isfield(xform,'ecParams'))
        % Rohde et. al. (MRM 2004) eddy-current warping struct
        motionMat = affineBuild(xform.ecParams(1:3),xform.ecParams(4:6));
        if(isfield(xform,'inMat') && ~isempty(xform.inMat))
		  % Apply inMat before motion correction. We apply inMat by
          % calling ourself in case inMat is something other than
          % an affine matrix.
		  coords = mrAnatXformCoords(xform.inMat,coords,false);
		  %coords = affine(motionMat*xform.inMat,coords);
        end
		coords = affine(motionMat,coords);
        c = xform.ecParams(7:14);
        if(any(c~=0))
            oneSq = coords(1,:).^2;
            twoSq = coords(2,:).^2;
            b_eddy = c(1).*coords(1,:) + c(2).*coords(2,:) + c(3).*coords(3,:) ...
                   + c(4).*coords(1,:).*coords(2,:) + c(5).*coords(1,:).*coords(3,:) ...
                   + c(6).*coords(2,:).*coords(3,:) + c(7).*(oneSq-twoSq)...
                   + c(8).*(2*coords(3,:).^2 - oneSq - twoSq);
            coords(xform.phaseDir,:) = coords(xform.phaseDir,:) - b_eddy;
        end
    elseif(isfield(xform,'deformX'))
        % then it's a deformation field. We expect five fields:
        % the deformation field, in xform.deformX, xform.deformY, xform.deformZ
        % two 4x4 affine matrices, inMat xforms the input coords to the
        % deformation field space, and outMat is applied to the coords that come 
        % out of the deformation field.
        coords = affine(xform.inMat,coords);
        % interpolate the deformation field using trilinear
        sz = size(xform.deformX);
        % myCinterp3 likes the x,y flipped.
        oldCoords = coords([2,1,3],:)';
        % When interpolating a deformation field, we must be careful about
        % the values returned for out-of-range points.
        coords(1,:) = myCinterp3(double(xform.deformX), [sz(1) sz(2)], sz(3), oldCoords, NaN);
        coords(2,:) = myCinterp3(double(xform.deformY), [sz(1) sz(2)], sz(3), oldCoords, NaN);
        coords(3,:) = myCinterp3(double(xform.deformZ), [sz(1) sz(2)], sz(3), oldCoords, NaN);
    elseif(isfield(xform,'coordLUT'))
        % A coordinate look-up table (essentially a simplified deformation
        % field)
        coords = round(affine(xform.inMat,coords));
        sz = size(xform.coordLUT);
        if(size(coords,2)==1)
            if(any(coords(:)<1)||any(coords>sz(1:3)'))
                coords = [NaN; NaN; NaN];
            else
                coords = squeeze(xform.coordLUT(coords(1),coords(2),coords(3),:));
            end
        else
            for ii=1:3
                coords(ii,any(coords(ii,:)<1,1)) = 1; 
                coords(ii,any(coords(ii,:)>sz(ii),1)) = sz(ii);
            end
            inds = sub2ind(sz(1:3),coords(1,:),coords(2,:),coords(3,:));
            for ii=1:3
                tmp = xform.coordLUT(:,:,:,ii);
                coords(ii,:) = tmp(inds);
            end
        end
    elseif(isfield(xform,'Affine'))
        % SPM-style deformation params
        coords = mrAnatGetImageCoordsFromSn(xform, coords);
        if(~isfield(xform, 'outMat'))
            % Provide the default that will do the right thing, as long as
            % the input image is in the same space as the image used to
            % align to the template.
            xform.outMat = inv(xform.VF.mat);
        end
    elseif(isfield(xform,'talScaleDir'))
        % Dougherty Talairach-scale struct
        if(strcmpi(xform.talScaleDir,'acpc2tal'))
            coords = mrAnatAcpc2Tal(xform,coords);
        elseif(strcmpi(xform.talScaleDir,'tal2acpc'))
            coords = mrAnatTal2Acpc(xform,coords);
        else
            error('Incorrect talScaleDir- must be ''acpc2tal'' or ''tal2acpc''.');
        end
    else
        error('Unrecognized xform struct!');
    end
    if(isfield(xform, 'outMat') && ~isempty(xform.outMat) && ~all(all(xform.outMat==eye(4))))
	  coords = affine(xform.outMat,coords);
	  outMat = xform.outMat;
    end
else
    coords = affine(xform,coords);
end

if(transposedOutput)
    coords = coords';
end
return;


%% This is a speed up for the affine transform
function coords = affine(xform,coords)
    % coords = xform*[coords;ones(1,size(coords,2))];
    % The following is much more memory-efficient and thus usually faster:
    coords = xform(1:3,1:3)*coords;
    for ii=1:3
        coords(ii,:) = coords(ii,:)+xform(ii,4);
    end
return
