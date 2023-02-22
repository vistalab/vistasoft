function xform = mrAnatXform(mmPerPix,vSize,frames)
% Little used gateway routine for volume coordinate transforms.  Should be
% deprecated.
%
%     xform = mrAnatXform(mmPerPix,vSize,frames)
%
% See first mrAnatXformCoords
%
% Purpose:
%  Compute coordinate transform between various frames.  
%
%   analyze2vanatomy:  Might work
%   vanatomy2acpc:     This one works
%   acpc2vanatomy:     Nope.
%
%Examples:
%  xform = mrAnatXform(mmPerPix,vSize,'vanatomy2acpc');
%  newImg = mrAnatResliceSpm(img, xform); makeMontage
%
%Authors: MBS, BW, RFD

if ieNotDefined('frames'), frames = 'vanatomy2acpc'; end
if length(mmPerPix) ~= 3, error('mmPerPix must contain three values'); end
if length(vSize) ~= 3, error('vSize must contain three values'); end

halfSize = vSize/2;

switch lower(frames)
    case {'analyze2vanatomy'}
        xform = [diag(mmPerPix), -halfSize]; 
        xform = [ xform; 0 0 0 1];
        
    case {'vanatomy2acpc'}
        xform = [0 0 mmPerPix(3) -halfSize(3); 0 -mmPerPix(2) 0 halfSize(1); -mmPerPix(1) 0 0 halfSize(2); 0 0 0 1];
    case {'acpc2vanatomy'}
        disp('NYI');
    otherwise
        error('Unknown transform');
        
end

return;