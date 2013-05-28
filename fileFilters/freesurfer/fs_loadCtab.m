function [brainAreas,vals,labels] = fs_loadCtab(ctabFile)
%
% Load a FreeSurfer .ctab file.  This is generally a file containing the
% labels and indices into a FreeSurfer segmaentation a segmentation.
%
% ctab = fs_loadCtab(ctabFile)
%
% INPUTS:
%    ctabFile - the fullpath to a file ending eith the .ctab exstension.
%               Freesurfer generates two as result of the full segmentation 
%               and parcellation process. These files are generally stored
%               in: $SUBJECTS_DIR/<subject>/label/
%
% OUTPUT:
%    brainAreas - is a cell array containing:
%                 brainAreas.val:  The values for each brain areas as coded 
%                                  in FreeSurfer.
%                 brainAreas.name: The corresponding labels, names for each
%                                  brain areas.
%    vals       - The values for each brain areas as coded in FreeSurfer
%    labels     - The corresponding labels, names for each
%                 brain areas.
%    colors     - The RGB colors for each brain area in the segmentation.
%
% EXAMPLE:
%    fsDir = getenv('SUBJECTS_DIR');
%    subject = 'pestilli_test';
%    segmentation = 'aparc.annot.a2009s';
%    segFile = fullfile(fsDir,subject,'label',sprintf('%s.ctab',segmentation));
%    ba = fs_loadCtab(segFile,' ',1);
%
% Written by Franco Pestilli (c) Stanford University 2013, Vistasoft

% Read the .ctab file
ctab = importdata(ctabFile,' ',1);

% Extract the labels names and corresponding values, and  colors.
vals             = cellfun(@str2num,ctab.textdata(:,1));
labels           = ctab.textdata(:,2);
brainAreas.name  = labels(:);
brainAreas.val   = vals;
brainAreas.colors= zeros(size(labels,1),3);
brainAreas.colors(vals>0,:) = ctab.data(:,1:3);    

end

