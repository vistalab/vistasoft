function tal = mrAnatGetTalairachDists
%
% tal = mrAnatGetTalairachDists
% 
% Simple function to return the measured distances (in mm) from
% the original Talairach and Tournoux brain. The origin is assumed
% to be the ac. However, note that the ppc point is the distance
% from the pc- to get the most posterior distance from the ac, use
% ppc+acpc.
%
% HISTORY:
% 2005.04.29 RFD:wrote it.

tal.sac = 72;
tal.iac = -42;
tal.lac = -62;
tal.rac = 62;
tal.aac = 68;
tal.acpc = -24;
tal.ppc = -78;
return;
