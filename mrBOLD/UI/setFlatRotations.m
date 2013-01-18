function vw = setFlatRotations(vw,rotations,flipLR)
%
% vw = setFlatRotations(vw,rotations,flipLR)
%
% Set rotation field in FLAT
% AND also set the flat slider
%
% originally written -- who knows?
% ras 01/07 -- added toggles for flip menus

if (~strcmp(vw.viewType,'Flat'))
    error('setFlatRotation called for non-flat view');
end

if (exist('rotations','var'))
    vw.rotateImageDegrees=rotations;
end

if (exist('flipLR','var'))
    vw.flipLR = flipLR;
    
    % also update menu toggles, if they exist
    if checkfields(vw, 'ui', 'flipLHMenu')
        offon = {'off' 'on'};
        set(vw.ui.flipLHMenu, 'Checked', offon{flipLR(1)+1});
        set(vw.ui.flipRHMenu, 'Checked', offon{flipLR(2)+1});
    end
end

curSlice = viewGet(vw, 'Current Slice');

% Set the slider
setImageRotate( vw, rotations(curSlice) / (180/pi) );


return
