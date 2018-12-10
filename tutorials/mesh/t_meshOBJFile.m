%% t_meshASCFile
% 
% Create an .asc file for mesh visualization in brainbrowser.
% Apparently, it will also take a json file.  We will figure that out and
% write out a json using the matlab json library, too.
%
% LMP/BW Vistasoft Team, 2015

%%
close all
clear all

%%  vistadata should be on your path.
%   Use remote data management tools to get the data if you don't have it.
remote = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
remoteF = 'anatomy/anatomyV/t1_class.nii.gz';
remoteF = fullfile(remote,remoteF);
tmp = [tempname,'.nii.gz'];
[niCFile, status] = urlwrite(remoteF,tmp);

% niCFile = fullfile(mrvDataRootPath,'anatomy','anatomyV','t1_class.nii.gz');
niClass = niftiRead(niCFile);
Ds = uint8(niClass.data);

% The ITKGRAY class labels are
%    0: unlabeled
%    1: CSF
%    2: Subcortical
%    3: left white matter
%    5: left gray matter
%    4: right white matter
%    6: right gray matter 

% Set the labels for everything that is not left gray or white to
% unlabeled. 
Ds(Ds == 1) = 0; 
Ds(Ds == 2) = 0; 
Ds(Ds == 4) = 0; 
Ds(Ds == 5) = 0; 
Ds(Ds == 6) = 0; 
% showMontage(double(Ds))

%% Matlab calculations reducing the patches and computing normals

% Make a picture of the cortical mesh.  We have all the information.
FV = isosurface(Ds,1);

% Calculate Iso-Normals of the surface
N=isonormals(Ds,FV.vertices);
L=sqrt(N(:,1).^2+N(:,2).^2+N(:,3).^2)+eps;
N(:,1)= N(:,1)./L; N(:,2)=N(:,2)./L; N(:,3)=N(:,3)./L;

%% Calculate Iso-Normals of the smoothed surface

% Center around (0,0)
% vMean = mean(FV.vertices);
% FV.vertices = bsxfun(@minus,FV.vertices,vMean);

% FLip the faces around and put them in too
% tmp = fliplr(FV.faces);
% FV.faces = [FV.faces; tmp];


% Invert Face rotation
% 
% FV.faces=[FV.faces(:,3) FV.faces(:,2) FV.faces(:,1)];  % Not bad
% 1 2 3 is no good
% 1 3 2 is not bad
% 2 1 3 is not bad
% 2 3 1 is no good
% 3 1 2 is no good
% 3 2 1 is not bad

%% New stuff

% Center around (0,0)
vMean = mean(FV.vertices);
FV.vertices = bsxfun(@minus,FV.vertices,vMean);

% % Smooth
smoothMode = 1; nIter = 30;
FV = smoothpatch(FV,smoothMode,nIter);  

% % Reduce to about 40K faces.  That's enough
% % This creates brainbrowser problems (but not meshLab problems)
% nFaces = size(FV.faces,1);
% maxFaces = 4*10^4;    % 40,000 faces?
% if nFaces > maxFaces
%     p = maxFaces/nFaces;
%     FV = reducepatch(FV.faces,FV.vertices, p);
% end


%% Display the iso-surface
% figure, patch(FV,'facecolor',[1 0 0],'edgecolor','none'); view(3);camlight
% Invert Face rotation
FV.faces=[FV.faces(:,3) FV.faces(:,2) FV.faces(:,1)];

%%

% Make a material structure
material(1).type='newmtl';
material(1).data='skin';
material(2).type='Ka';
material(2).data=[0.8 0.4 0.4];
material(3).type='Kd';
material(3).data=[0.8 0.4 0.4];
material(4).type='Ks';
material(4).data=[1 1 1];
material(5).type='illum';
material(5).data=2;
material(6).type='Ns';
material(6).data=27;

% Make OBJ structure
clear OBJ
OBJ.vertices = FV.vertices;
OBJ.vertices_normal = N;
OBJ.material = material;
OBJ.objects(1).type='g';
OBJ.objects(1).data='skin';
OBJ.objects(2).type='usemtl';
OBJ.objects(2).data='skin';
OBJ.objects(3).type='f';
OBJ.objects(3).data.vertices=FV.faces;
OBJ.objects(3).data.normal=FV.faces;

fname = fullfile(pwd,'cortex.obj');
objWrite(OBJ,fname);
fprintf('Wrote out OBJ file:  %s\n',fname);

%% Original code from write_wobj.m

% % Calculate Iso-Normals of the surface
% N=isonormals(Ds,FV.vertices);
% L=sqrt(N(:,1).^2+N(:,2).^2+N(:,3).^2)+eps;
% N(:,1)=N(:,1)./L; N(:,2)=N(:,2)./L; N(:,3)=N(:,3)./L;
% % Display the iso-surface
% % figure, patch(FV,'facecolor',[1 0 0],'edgecolor','none'); view(3);camlight
% % Invert Face rotation
% FV.faces=[FV.faces(:,3) FV.faces(:,2) FV.faces(:,1)];
% 
% % Make a material structure
% material(1).type='newmtl';
% material(1).data='skin';
% material(2).type='Ka';
% material(2).data=[0.8 0.4 0.4];
% material(3).type='Kd';
% material(3).data=[0.8 0.4 0.4];
% material(4).type='Ks';
% material(4).data=[1 1 1];
% material(5).type='illum';
% material(5).data=2;
% material(6).type='Ns';
% material(6).data=27;
% 
% % Make OBJ structure
% clear OBJ
% OBJ.vertices = FV.vertices;
% OBJ.vertices_normal = N;
% OBJ.material = material;
% OBJ.objects(1).type='g';
% OBJ.objects(1).data='skin';
% OBJ.objects(2).type='usemtl';
% OBJ.objects(2).data='skin';
% OBJ.objects(3).type='f';
% OBJ.objects(3).data.vertices=FV.faces;
% OBJ.objects(3).data.normal=FV.faces;
% 
% fname = 'cortex.obj';
% objWrite(OBJ,fname);
% fprintf('Wrote out OBJ file:  %s\n',fname);
%% END
