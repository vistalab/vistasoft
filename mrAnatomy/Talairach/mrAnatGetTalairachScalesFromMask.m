function talScale = mrAnatGetTalairachScalesFromMask(brainMask, brainMaskXform)
%
% talScale = mrAnatGetTalairachScalesFromMask(brainMask, brainMaskXform)
% 
% Computes the Talairach scales from a brain mask. Note that the brainMaskXform
% should transform image coords to ac-pc (RAS) space in mm (first dim runs
% left-to-right, second dim runs posterior-to-anterior, third dim runs
% inferior-to-superior). The only scale factor that can't be estimated from
% the brain edge is the ac-pc scale. This will be set to 1. (TO DO: allow
% user to pass the pc landmark.)
%
% HISTORY:
% 2007.07.23 RFD: wrote it.

tmp = sum(brainMask,3);
x = find(sum(tmp,1)); x = [x(1) x(end)];
y = find(sum(tmp,2)); y = [y(1) y(end)];
tmp = squeeze(sum(brainMask,1));
z = find(sum(tmp,1)); z = [z(1) z(end)];
curSizeAcPc = mrAnatXformCoords(brainMaskXform,[y;x;z]');
tal = mrAnatGetTalairachDists;
talScale.sac = curSizeAcPc(2,3)./tal.sac;
talScale.iac = curSizeAcPc(1,3)./tal.iac;
talScale.lac = curSizeAcPc(1,1)./tal.lac;
talScale.rac = curSizeAcPc(2,1)./tal.rac;
talScale.aac = curSizeAcPc(2,2)./tal.aac;
pac = curSizeAcPc(1,2)./(tal.acpc+tal.ppc);
talScale.acpc = pac;
talScale.ppc = pac;

return;
