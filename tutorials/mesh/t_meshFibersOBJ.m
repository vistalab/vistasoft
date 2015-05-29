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
[lgt , fSurf, fvc] = AFQ_RenderFibers(fg);

% fvc is a cell array, each one with the faces, vertices and colors of a
% single streamline.


% FV.vertices = fvc(1).vertices;
% FV.faces    = fvc(1).faces;
% 
% % mrvNewGraphWin; 
% % plot3(FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3),'.');
% 
% [Nx,Ny,Nz] = surfnorm(fSurf.X{1},fSurf.Y{1},fSurf.Z{1});
% N = [Nx(:),Ny(:),Nz(:)];
% OBJ = objFVN(FV,N);
% objWrite(OBJ,'deleteMe.obj');


%%
obj = objCreate;
mtl = mtlCreate;

obj.vertices = fg(1).fibers{1}';

obj.objects(1).type = 'l';
obj.objects(1).data = 1:120;
objWrite(obj,'deleteMe.obj');



%%
FV.vertices = [];
FV.faces = [];
N = [];
for ff =1:5
    FV.vertices = [FV.vertices; fvc(ff).vertices];
    FV.faces    = [FV.faces; fvc(ff).faces];
    [Nx,Ny,Nz] = surfnorm(fSurf.X{ff},fSurf.Y{ff},fSurf.Z{ff});
    tmp =[Nx(:),Ny(:),Nz(:)];
    N = [N ; tmp];
end

% 
OBJ = objFVN(FV,N);
objWrite(OBJ,'deleteMe.obj');

% mrvNewGraphWin; 
% plot3(FV.vertices(:,1),FV.vertices(:,2),FV.vertices(:,3),'.');


%% END