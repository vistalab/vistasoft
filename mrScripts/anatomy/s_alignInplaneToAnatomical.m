% s_alignInplaneToAnatomical
%
% This script is used to align a T1- or T2-weighted to a high resolution,
% whole brain anatomical scan. It requires two code repositories:
%
%   knkutils (https://github.com/kendrickkay/knkutils)
%   alignvolumedata (https://github.com/kendrickkay/alignvolumedata)
%
% We assume there is already a mrSESSION file (i.e., a vista session has
% been initiated). Manual intervention is required in two steps - step 1
% and step 4b below. Otherwise it is automated.

%% Align inplane to stored high-res anatomy. 
% The plans is:
%   (1) do our best with rxAlign
%   (2) export our best alignment (the 4x4 transform matrix)
%   (3) use exported xform matrix as starting point in knk's alignment code
%   (4) for knk code, we:
%       (a) pretreat volumes (some kind of contrast / luminance
%       normalization)
%       (b) fit an ellipse that covers the brain but not the skull.
%           this ellipse determines which voxels contribute to the
%           alignment process.  the point is to avoid artifacts
%           like fat which can confuse the alignment.
%       (c) do a coarse alignment using mutual information metric
%       (d) do a fine alignment using mutual information metric
%       (d') optionally, allow a full affine transformation (instead
%            of rigid-body) in order to compensate for scaling issues
%            due to nonlinearities/miscalibration of the gradients.
%       (e) export xform and generate a 4x4 xform matrix
%   (5) save this xform as mrVista alignment


%% (1) Do our best alignment in rxAlign


% Open the rxAlign GUI. Either get a decent alignment manually, or if you
% have already done so, select the best alignment in the GUI.
% if you are going to use knk's automated alignment, the alignment you
% start with just doesn't have to be very good; it just has to be 
% somewhere in the ballpark of being right.
rxAlign; 

%% (2) Once you are done with the alignment, pull out the necessary info
rxVista = rxRefresh;
rxClose;
rx = rxVista; clear rxVista;
close all;
%% (3) get into knk format 
% (why doesn't he just take the 4x4?)
% the reason is that the coordinate-space conventions are different.
rxAlignment = rx.xform;
rxAlignment([1 2],:) = rxAlignment([2 1],:);
rxAlignment(:,[1 2]) = rxAlignment(:,[2 1]);
knk.TORIG = rxAlignment;
knk.trORIG = matrixtotransformation(knk.TORIG,0,rx.volVoxelSize,size(rx.ref),size(rx.ref) .* rx.refVoxelSize);

%% (4) KNK alignment ***********************

%% 4a pre-condition the volumes [although it's sensible to do this, I'm not actually sure how much of a difference this makes]
volpre = rx.vol;% preconditionvolume(rx.vol,[],[],[99 1/3]);
refpre = rx.ref;% preconditionvolume(rx.ref);
close all

%%  open knk alignment GUI
alignvolumedata(volpre,rx.volVoxelSize,refpre,rx.refVoxelSize,knk.trORIG);

%% 4b Define ellipse
% (if you need help with the shortcut keys:) 
% doc defineellipse3d 
[~,mn,sd] = defineellipse3d(refpre);%,[],[],mn,sd);
% mn = [0.5674    0.4732    0.5131];
% sd = [0.2888    0.2278    0.3938];

%% 4c Automatic alignment (coarse)
useMI = true;  % you need MI if the two volumes have different tissue contrast.
               % it's much faster to not use MI.
alignvolumedata_auto(mn,sd,0,[2 2 2],[],[],[],useMI);  % rigid body, coarse, mutual information metric

%% 4d Automatic alignment (fine)
alignvolumedata_auto(mn,sd,0,[1 1 1],[],[],[],useMI);  % rigid body, fine, mutual information metric

%% 4d' (OPTIONAL) Automatic alignment (affine transformation) [use alternating fitting to help avoid local minima]
% Note: You may want to skip this section, inspect the results, and then come
%       back and do this section, and then compare the results, just to make sure
%       everything is sane.
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,0,[2 2 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,0,[2 2 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,0,[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,0,[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,0,[1 1 1],[],[],[],useMI,1e-3);
alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],useMI,1e-3);

%% 4e Export the final transformation
tr = alignvolumedata_exporttransformation;

% make the transformation into a 4x4 matrix
T = transformationtomatrix(tr,0,rx.volVoxelSize);

%% (5) Save as alignment for your vista session 
vw = initHiddenInplane; mrGlobals; 
mrSESSION.alignment = T;
saveSession;

%% Optional: Save images showing the alignment

t1match = extractslices(volpre,rx.volVoxelSize,refpre,rx.refVoxelSize,tr);

% inspect the results
if ~exist('./Images', 'dir'), mkdir('Images'); end
imwrite(uint8(255*makeimagestack(refpre,1)),'Images/inplane.png');
imwrite(uint8(255*makeimagestack(t1match,1)),'Images/reslicedT1.png');


