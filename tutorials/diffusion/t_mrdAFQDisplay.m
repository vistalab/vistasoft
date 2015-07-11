%% t_mrdMBA
%
%  Show fibers using FP's mba code
%  Make sure AFQ is on your path
%  SPM needs to be there, too.
%  The repository can be downloaded from: 
%     git clone
%
%%

remote.host = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
remote.directory = fullfile('diffusion','sampleData','fibers');
rdata('cd',remote);
dirList = rdata('ls',remote,'pdb');                   % Match .pdb extension
%
oname = rdata('get',remote,dirList{2});
fname = [oname,'.pdb'];
copyfile(oname,fname);

%%  Load the fibers and display
fg = fgRead(fname);

% Render the Tract FA Profile for the left uncinate
% A small number of triangles (25 is the default).
nTriangles = 8;
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,'subdivs',nTriangles);

%% 
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,...
    'subdivs',nTriangles,...
    'color',[.8 0 .8]);

%%
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,...
    'subdivs',nTriangles,...
    'color',[.6 .6 .8], ...
    'jittercolors',.4);
%%
[~, AFQdata] = AFQ_directories;
cortex = fullfile(AFQdata,'mesh','segmentation.nii.gz');
overlay = fullfile(AFQdata,'mesh','Left_Arcuate_Endpoints.nii.gz');
thresh = .01; % Threshold for the overlay image
crange = [.01 .8]; % Color range of the overlay image
% Render the cortical surface colored by the arcuate endpoint density
[p, msh, lightH] = AFQ_RenderCorticalSurface(cortex, 'overlay' , overlay, 'crange', crange, 'thresh', thresh)


  
% End