function dir = mrDiffusionDir()
%
% dir = mrDiffusionDir()
%
% Returns the top-level directory that contians the mrDiffusion code.
%

dir = fileparts(which('mrDiffusion.m'));
return;