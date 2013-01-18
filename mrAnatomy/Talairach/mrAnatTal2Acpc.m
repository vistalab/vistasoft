function acpcCoords = mrAnatTal2Acpc(talScale, talCoords)
%
% acpcCoords = mrAnatTal2Acpc(talScale, talCoords)
% 
% Converts Talairached coords to acpc coords. 
% talCoords should be a 3xN.
%
% HISTORY:
% 2004.10.11 RFD: pulled code out of dtiFiberUI.
% 2005.04.29 RFD: added pcReference field to make this more general.

if(size(talCoords,1)~=3) talCoords = talCoords'; end
if(size(talCoords,1)~=3)
    error('The talCoords are the wrong size!');
end
acpcCoords = talCoords;
if(~isfield(talScale,'acpc') | isempty(talScale.acpc))
    error('Invalid talScale struct!');
end
if(~isfield(talScale,'pcReference') | isempty(talScale.pcReference))
    tal = mrAnatGetTalairachDists;
    talScale.pcReference = tal.acpc;
end

% Do the easy ones first
% LEFT-RIGHT
inds = talCoords(1,:)>0;
acpcCoords(1,inds) = acpcCoords(1, inds)./talScale.rac;
inds = ~inds;
acpcCoords(1,inds) = acpcCoords(1, inds)./talScale.lac;
% SUP-INF
inds = talCoords(3,:)>0;
acpcCoords(3,inds) = acpcCoords(3,inds)./talScale.sac;
inds = ~inds;
acpcCoords(3,inds) = acpcCoords(3,inds)/talScale.iac;

pc = talScale.pcReference/talScale.acpc;
inds = talCoords(2,:)>0;
acpcCoords(2,inds) = acpcCoords(2,inds)/talScale.aac;
% between ac-pc
inds = talCoords(2,:)>=talScale.pcReference & talCoords(2,:)<0;
acpcCoords(2,inds) = acpcCoords(2,inds)./talScale.acpc;
inds = talCoords(2,:)<talScale.pcReference;
acpcCoords(2,inds) = pc + (acpcCoords(2,inds)+abs(talScale.pcReference))./talScale.ppc;
return;
