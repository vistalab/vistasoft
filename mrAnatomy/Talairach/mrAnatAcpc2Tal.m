function talCoords = mrAnatAcpc2Tal(talScale, acpcCoords)
%
% talCoords = mrAnatAcpc2Tal(talScale, acpcCoords)
% 
% Converts acpc coords to Talairach coords. 
%
% HISTORY:
% 2004.10.11 RFD: pulled code out of dtiFiberUI.
% 2005.04.29 RFD: added pcReference field to make this more general.

if(size(acpcCoords,1)~=3) acpcCoords = acpcCoords'; end
if(size(acpcCoords,1)~=3)
    error('The talCoords are the wrong size!');
end
talCoords = acpcCoords;
if(~isfield(talScale,'acpc') || isempty(talScale.acpc))
    return;
end
if(~isfield(talScale,'pcReference') || isempty(talScale.pcReference))
    tal = mrAnatGetTalairachDists;
    talScale.pcReference = tal.acpc;
end

% Do the easy ones first
% LEFT-RIGHT
inds = acpcCoords(1,:)>0;
talCoords(1,inds) = talCoords(1, inds).*talScale.rac;
inds = ~inds;
talCoords(1,inds) = talCoords(1, inds).*talScale.lac;
% SUP-INF
inds = acpcCoords(3,:)>0;
talCoords(3,inds) = talCoords(3,inds).*talScale.sac;
inds = ~inds;
talCoords(3,inds) = talCoords(3,inds).*talScale.iac;

pc = talScale.pcReference/talScale.acpc;
inds = acpcCoords(2,:)>0;
talCoords(2,inds) = talCoords(2,inds).*talScale.aac;
% between ac-pc
inds = acpcCoords(2,:)>=pc & acpcCoords(2,:)<0;
talCoords(2,inds) = talCoords(2,inds).*talScale.acpc;
inds = acpcCoords(2,:)<pc;
talCoords(2,inds) = talScale.pcReference + (talCoords(2,inds)-pc).*talScale.ppc;
return;
