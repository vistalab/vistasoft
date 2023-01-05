J=zeros(3,3,3); J(2,2,2)=1;
Cube_FV=isosurface(J,0.1);
Cube_FV.vertices=Cube_FV.vertices-mean(Cube_FV.vertices(:));
Cube_FV.vertices=Cube_FV.vertices/2;
Cube_FV.vertices(:,3)=Cube_FV.vertices(:,3)+2;
Cube_FV.normals=patchnormals(Cube_FV);

load sphere
Sphere_FV=FV;
Sphere_FV.vertices=Sphere_FV.vertices-mean(Sphere_FV.vertices(:));
Sphere_FV.vertices=Sphere_FV.vertices/500;
Sphere_FV.vertices(:,3)=Sphere_FV.vertices(:,3)+1;

% Render first time to get depth profile of cube object
I = zeros (256,256,6); 
I(:,:,5)=100; % Background depth 
Cube_FV.color=[0 0 0.3];
I=renderpatch(I,Cube_FV); 
figure, h=imshow(I(:,:,1:3));
for a=-5:0.1:5
 L=[sin(a) cos(a) -5 1];
[Shadow_FV.vertices,Shadow_FV.faces]=patchshadowvolume(Sphere_FV.vertices,Sphere_FV.faces,L);

% Render faces shadow volume, and count backfacing and frontfacing
% fragments on every coordinate
FV=Shadow_FV;
FV.stencilfunction=1;
FV.stencilpassdepthbufferfail=0;
FV.stencilpassdepthbufferpass=5;
FV.enablestenciltest=1;
FV.enabledepthtest=1;
FV.depthfunction=2;
FV.depthbufferwrite = 0;
FV.colorbufferwrite = 0;
FV.culling=0;
J=renderpatch(I,FV); 

% Render without the shadow area
FV=Cube_FV;
FV.stencilfunction=4;
FV.enablestenciltest=1;
FV.enabledepthtest=1;
FV.depthfunction=2;
FV.depthbufferwrite = 0;
FV.culling=1;
FV.color=[0 0 1];
FV.enableshading=1;
FV.lightposition =L;
I2=I;
I2(:,:,5)=100; % Background depth 
I2(:,:,6)=J(:,:,6); % Shadow Stencil
J=renderpatch(I2,FV); 

set(h,'CData',J(:,:,1:3)); drawnow('expose'); 
end

