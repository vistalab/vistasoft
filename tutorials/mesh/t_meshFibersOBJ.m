%% t_meshFibersOBJ
%
%  Shows how to create OBJ fiber files from AFQ fibers.
%
% BW/LMP

%% Download a small set of fibers in a pdb file

remote = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
remoteF = 'diffusion/sampleData/fibers/leftArcuateSmall.pdb';
remoteF = fullfile(remote,remoteF);
tmp = [tempname,'.pdb'];
[fgFile, status] = urlwrite(remoteF,tmp);

% Read the fiber groups
fg = fgRead(fgFile);

% Render the Tract FA Profile for the left uncinate
% A small number of triangles (25 is the default).
nTriangles = 4;
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,'subdivs',nTriangles);
% mrvNewGraphWin; surf(fSurf.X{1},fSurf.Y{1},fSurf.Z{1},fSurf.C{1})
% mrvNewGraphWin; plot3(FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3),'.');

%% Accumulate fascicles into a structure that we can write using objWrite

% The obj structure has one list of vertices and one list of normals.
% It can then have multiple groups of fascicles (e.g., f1, f2, ...)
% But we end up accumulating the vertices from all the fascicles, and when
% we descrive the faces for, say, f2, they have to refer to the vertices
% for f2, not the vertices for f1.  So, we need to add an offset value to
% the faces.
FV.vertices = [];
FV.faces    = [];
N           = [];
% select = 1:10;  % Small for debugging.  Select only some faces.
cnt = 0;
nFascicles = size(fvc,2);
c    = ones(nFascicles,3);
redF = round(nFascicles)/2;
c(1:redF,:) = repmat([1 0 0],redF,1);
% c(1:redF,:) = repmat([1 0 0],redF,1);

for ff = 1:2:size(fvc,2)
   
    % We expertimented with color, and this worked in meshLab but not in
    % brainbrowser
    %
    % When we add color, we do it this way by appending RGB to the
    % vertex, and dealing with the first case separately
    if isempty(FV.vertices)
        % FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
        FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
    else
        % Vertices of the triangles defining the fascicle mesh
        FV.vertices = [FV.vertices; [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)]];
    end
    
    % Cumulate the vertices
    % FV.vertices = [FV.vertices; fvc(ff).vertices];
    
    % Cumulate the normals for each vertex
    [Nx,Ny,Nz] = surfnorm(fSurf.X{ff},fSurf.Y{ff},fSurf.Z{ff});
    tmp =[Nx(:),Ny(:),Nz(:)];
    N = [N ; tmp];
    
    % Add an offset to the faces, to make them consistent with cumulating
    % vertices.
    FV.faces    = [FV.faces; fvc(ff).faces + cnt];
    
    % Update where we are
    cnt = size(FV.vertices,1);

end

%% Format the OBJ data and write them out

OBJ = objFVN(FV,N);

fname = '/Users/wandell/Desktop/testArcuate.obj';
% fname = '/home/wandell/Desktop/testArcuate.obj';
objWrite(OBJ,fname);

%% Copy the data onto SDM
pLink = 'https://sni-sdm.stanford.edu/api/acquisitions/558da2ba3113bb9e05daaf0f/file/1.3.12.2.1107.5.2.32.35381.2015012510504883990801657.0.0.0_nifti.nii.gz?user=';
uName = 'wandell@stanford.edu';

%
sdmPut(pLink,uName,fname);

%%  These commands create the data and put the method as a PDF into the SDM
%
%   pdfFile = publish('t_meshFibersOBJ.m','pdf');
%   sdmPut(pLink,uName,pdfFile); disp('Done');
%


