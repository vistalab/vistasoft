function [dtiF, dtiH] = mrDiffusion(visible,dt6Name)
% This function initializes a mrDiffusion window and handles
%
%  [dtiF, dtiH] = mrDiffusion
%
% This is useful for scripting because it returns the figure and handles
% that are used by dtiGet/Set (which you should always like to use).
%
% Example:
%   [dtiF, dtiH] = mrDiffusion('off');
%   dt6Name = fullfile(mrvDataRootPath,'diffusion','sampleData','dti40','dt6.mat');
%   [dtiF, dtiH] = mrDiffusion('on',dt6Name);
%
% (c) Stanford VISTA Team

if   notDefined('dt6Name'), dtiF = dtiFiberUI;
else dtiF = dtiFiberUI(dt6Name);
end

if notDefined('visible'), visible = 'on'; end

set(dtiF,'visible',visible)

dtiH = guidata(dtiF);

drawnow
return


%% mrDiffusion
%
% Make these comments better and then put them at the top.
%
% A software package for analysis and visualization of 
% diffusion MR data from the Stanford Vision, Imaging 
% Science and Technology Activities (VISTA) group and the 
% Stanford Institute for Reading and Learning (SIRL).
%
% The main components of mrDiffusion are:
% 
% dtiFiberUI: the main graphical interface for viewing a 
% diffusion dataset.
%
% dtiMakeDt6: the function that we use to build the dt6 file
% needed by dtiFiberUI. There are variants of this function
% designed to work for diffusion data from other sites. These
% other variants generally rely on FSL's FDT tools for various
% pre-processing stages. 
%
% analysisScrips: a big pile of analysis scripts that we have used
% for various projects. Most involve batch-processing of many dt6 
% files. This is where you might find examples for doing cross-subject
% analysis.
%
% mrDiffusion depends on:
% 
% * Matlab, versions >=7. We tried to keep the dependency on extra
%   toolboxes minimal. I think the image processing toolbox is needed
%   to run some basics, and the stats toolbox might be needed for
%   some of the specialized analysis scripts.
%
% * SPM (http://www.fil.ion.ucl.ac.uk/spm/). We mostly use spm2, but 
% everything also seems to work with spm5.
%
% * mrVista (http://white.stanford.edu/software/)
%
% mrDiffusion also relies on mex-files to do some loopy things that
% would take forever in pure matlab (like fiber tracking). All the
% source code is included, as well as binaries for windows, linux 
% and OSX. To compile for a new platform, try running dtiCompileMex.
%
% mrMesh is a 3d visualization served that can be used to make pretty, 
% interactive displays of fibers, cortical surfaces, etc. Binaries for
% windows and linux (x86) are included in mrVista. It can be compiled
% for other platforms, but is not easy to recompile. Contact us if you
% want to try compiling it for your favorite platoform and we'll send
% the source code.
%
% mrDiffusion is copyright 2003-2006 by Bob Dougherty and others, 
% including Brian Wandell, Armin Schwartzman, Girish Mulye, David Akers,
% and Anthony Sherbondy. Most of the code is released under the GPL
% (http://www.gnu.org/copyleft/gpl.html).
%


% Just run the dtiFiberUI GUI. Maybe someday we'll have a better top-level
% GUI that would serve as a guide to the various components.
