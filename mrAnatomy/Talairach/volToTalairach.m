function vt = volToTalairach(volCoords, v2t)
% talairachCoords = volToTalairach(volCoords, v2t)
%
% PURPOSE:
%   Converts arbitrary coordinates (volCoords) to Talairach space, given
%   the transform info in the v2t struct. The coords must be in 'n X 3'
%   row-vector form. The v2t struct must have a 4x4 affine transform matrix
%
%       v2t.transRot
%
%   And 7 scale factors:
%
%       v2t.superiorAcScale
%       v2t.inferiorAcScale
%       v2t.rightAcScale
%       v2t.leftAcScale
%       v2t.anteriorAcScale
%       v2t.betweenAcPcScale
%       v2t.posteriorPcScale
%
%   See computeTalairach.m for an example of how to compute these.
%
% HISTORY:
%   2001.09.14 RFD (bob@white.stanford.edu) Wrote it, with help from
%              Alex Wade and Jochem Rieger.

% MrLoadRet coords are axial,coronal,sagittal, but we need coronal,axial,sagittal. 
% Oh well...

% We have to make the coords homogeneous (ie. 4d)
vt = ones(size(volCoords,1),size(volCoords,2)+1);
vt(:,1:3) = [volCoords(:,2),volCoords(:,1),volCoords(:,3)];

% now, apply translation and rotation
vt = vt * v2t.transRot;

% v shoule now be on the talairach axes:
%   X = sagittal slice (right is +)
%   Y = coronal slice (anterior is +)
%   Z = axial slice (superior is +)
%
% We just need to apply the appropriate scale factor
for(ii=1:size(vt,1))
    if(vt(ii,1)>0)
        vt(ii,1) = vt(ii,1) * v2t.rightAcScale;
    else
        vt(ii,1) = vt(ii,1) * v2t.leftAcScale;
    end
    if(vt(ii,3)>0)
        vt(ii,3) = vt(ii,3) * v2t.superiorAcScale;
    else
        vt(ii,3) = vt(ii,3) * v2t.inferiorAcScale;
    end
     if(vt(ii,2)>0)
        vt(ii,2) = vt(ii,2) * v2t.anteriorAcScale;
    else
        acpc = vt(ii,2) * v2t.betweenAcPcScale;
        % we have to apply separate scale factors if it goes beyond the PC
        if(acpc<-24)
            beyondPC = vt(ii,2) + 24/v2t.betweenAcPcScale;
            vt(ii,2) = -24 + beyondPC*v2t.posteriorPcScale;
        else
            vt(ii,2) = acpc;
        end
    end
end
vt = vt(:,1:3);
return;
