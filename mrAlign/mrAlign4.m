%
% NAME: mrAlign (ver 4)
% AUTHOR: Sunjay Lad
% DATE: 8/2002
% PURPOSE:
%	Main routine for menu driven matlab program to view and analyze
%	volumes of anatomical and functional MRI data.
% HISTORY:
%	Dozens of people contributed to the original mrAlign. It was written
%   using scripts in matlab 4 without any data structures. This is an 
%   attempt to clean up the code and make the alignment process fully 
%   automatic.

% Still need to do:
%   1) Add header comments
%   2) change regCheckRotAll to a function
%   3) clean up new coarse alignment code
%   4) comment new coarse alignment code
%   5) fix comments on all existing functions

disp('mrAlign (version 4.0)');

%%%%%%%%%%%%%%%%%%%%
% Global Variables %
%%%%%%%%%%%%%%%%%%%%

global HOMEDIR              % Current directory
HOMEDIR = pwd;

%%%%%%%%%%%%%%%%%%%
% Local Variables %
%%%%%%%%%%%%%%%%%%%

volume = [];			    % Volume of data
numSlices = 124;		    % Number of planes of volume anatomy
mmPerPix = [];              % Voxel size (in mm/pixel) of volume anatomy
volSize = [];               % Dimensions (in pixels) of volume anatomy

rot = [];
trans = [];
scaleFac = [];
Xform = [];                 % 4x4 transform matrix from inplane pixels -> volume pixels
sagSize = [];			    % Current sagittal size

NCoarseIter = [10 10];      % Number of coarse iterations at each level [fine ... coarser ... coarsest]
coarseFlag = [];            % Coarse iterations flag
fineFlag = [];              % Fine iterations flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mrLoadRet Stuff                                                         %
% The goal here is to make mrAlign a standalone program so that you don't %
% need to be running mrLoadRet. This stuff needs to be set up to allow    %
% mrAlign to run on its own.                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global mrSESSION dataTYPES
load mrSESSION
subject = mrSESSION.subject;
vAnatPath = getvAnatomyPath(subject);
numofanats = mrSESSION.inplanes.nSlices;
curSize = mrSESSION.inplanes.cropSize;
anatsz = [curSize,numofanats];
inplane_pix_size = 1./mrSESSION.inplanes.voxelSize;

% hack to make michaels's data work
HOMEDIR = pwd;

global INPLANE
% Set name, viewType, & subdir
INPLANE.name='INPLANE';
INPLANE.viewType='Inplane';
INPLANE.subdir='Inplane';
% Initialize slot for anat
INPLANE.anat = [];
% Loads anatomies
INPLANE = loadAnat(INPLANE);


%%%%%%%%%%%%%%%%
% Main Program %
%%%%%%%%%%%%%%%%

% Reads anatomy data
[volume,mmPerPix,volSize] = readVolAnat(vAnatPath); 
sagSize = volSize(1:2); 
numSlices = volSize(3);

% Main menu window
mainMenu = figure('MenuBar','none');


%%%%% File Menu %%%%%

ld = uimenu('Label','File');

% Extract Coarse Alignment Data From Header File
uimenu(ld, 'Label', 'Extract Coarse Alignment From Header Files','CallBack',...
    '[Xform,rot,trans,scaleFac] = coarseFromIfile(subject); Xform,rot,trans,scaleFac'...
    ,'Separator','on');

% Load Previous Alignment
uimenu(ld,'Label','Load Previous Alignment (bestrotvol)','CallBack',...
    'eval(sprintf(''load bestrotvol''));disp(''Loaded: bestrotvol.mat'');','Separator','on');

% Save Alignment
uimenu(ld,'Label','Save Alignment (bestrotvol)','CallBack',...
    'eval(sprintf(''save bestrotvol inpts volpts trans rot scaleFac'')); disp(''Saved: bestrotvol.mat'');'...
    ,'Separator','on');

% Quit
uimenu(ld,'Label','Quit','CallBack','close all; clear all;','Separator','on');
    

%%%%% Compute Alignment Menu %%%%%
ld = uimenu('Label','Compute Alignment','Separator','on');

% Compute Automatic Alignment - performs NCoarseIter amount of coarse
% iterations and then fine iterations
uimenu(ld,'Label','Compute Automatic Alignment (coarse and fine iterations)','CallBack',...
   'coarseFlag = 1; fineFlag = 1; [rot,trans,Mf] = regEstRot4(rot,trans,scaleFac,volume,numSlices,sagSize,NCoarseIter,coarseFlag,fineFlag);'...
   ,'Separator','on');

% Compute Automatic Alignment - only performs NCoarseIter amount of coarse iterations
uimenu(ld,'Label','Compute Automatic Alignment (coarse iterations only)','Callback',...
    'coarseFlag = 1; fineFlag = 0; [rot,trans,Mf] = regEstRot4(rot,trans,scaleFac,volume,numSlices,sagSize,NCoarseIter,coarseFlag,fineFlag);'...
   ,'Separator','on');

% Compute Automatic Alignment - performs only fine iterations
uimenu(ld,'Label','Compute Automatic Alignment (fine iterations only)','Callback',...
    'coarseFlag = 0; fineFlag = 1; [rot,trans,Mf] = regEstRot4(rot,trans,scaleFac,volume,numSlices,sagSize,NCoarseIter,coarseFlag,fineFlag);'...
   ,'Separator','on');

%%%%% Check Alignment Menu %%%%%
ld = uimenu('Label','Check Alignment','Separator','on');

% Generates checkerbaord mosaic to check alignemnt
uimenu(ld,'Label','Check Alignment (all slices)',...
   'CallBack','regCheckRotAll', 'Separator', 'on');
return