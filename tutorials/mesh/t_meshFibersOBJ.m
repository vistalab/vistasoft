%% t_meshFibersOBJ
%
%
% obj = objCreate;
% mtl = mtlCreate;
% obj = objSet(obj,'material',mtl);
% obj = objSet(obj,'vertices',FV.vertices);
% obj = objSet(obj,'vertex normals',N);
% obj = objSet(obj,'faces',FV.faces);
%
% obj = objSet(obj,'line',fg{1}.coords);
%
% objWrite(obj);
%

%%
remote = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
remoteF = 'diffusion/sampleData/fibers/leftArcuateSmall.pdb';
remoteF = fullfile(remote,remoteF);
tmp = [tempname,'.pdb'];
[fgFile, status] = urlwrite(remoteF,tmp);

fg = fgRead(fgFile);

% Render the Tract FA Profile for the left uncinate
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg,'subdivs',6);
% mrvNewGraphWin; surf(fSurf.X{1},fSurf.Y{1},fSurf.Z{1},fSurf.C{1})


%%
% obj = objCreate;
% % mtl = mtlCreate;
% 
% obj.vertices = fg(1).fibers{1}';
% 
% obj.objects(1).type = 'l';
% obj.objects(1).data = 1:120;
% objWrite(obj,'deleteMe.obj');



%% Accumulate fascicles

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
c = [1 0 0; 0 1 0];
for ff = [1:3:350]
    
    %     % When we add color, we do it this way by appending RGB to the
    %     % vertex, and dealing with the first case separately
    %     if isempty(FV.vertices)
    %         % FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
    %         FV.vertices = [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)];
    %     else
    %         % Vertices of the triangles defining the fascicle mesh
    %         % FV.vertices = [FV.vertices; [fvc(ff).vertices repmat(c(ff,:),size(fvc(ff).vertices,1),1)]];
    %     end
    FV.vertices = [FV.vertices; fvc(ff).vertices];
    
    % Normals for each vertex
    [Nx,Ny,Nz] = surfnorm(fSurf.X{ff},fSurf.Y{ff},fSurf.Z{ff});
    tmp =[Nx(:),Ny(:),Nz(:)];
    N = [N ; tmp];
    
    % Add the offset to the faces
    % These could be grouped into fascicles somehow at write-out time.
    FV.faces    = [FV.faces; fvc(ff).faces + cnt];
    cnt = size(FV.vertices,1);

end

% 
OBJ = objFVN(FV,N);
name = '/Users/wandell/Desktop/deleteMe.obj';
objWrite(OBJ,name);

% mrvNewGraphWin; 
% plot3(FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3),'.');




%% END