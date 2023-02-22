
 % Compile the C-code
 mex renderpatch.cpp -v
 mex patchshadowvolume.cpp -v
 mex patchnormals_double.c -v

 % Make the render-buffers RGB and depth
 I = zeros (256,256,6); 
 I(:,:,5)=1; % Background depth 
 % Load Patch object
 load Sphere
 % Transform coordinates to [-1..1] range
 FV.vertices = FV.vertices-mean(FV.vertices(:));
 FV.vertices =FV.vertices ./max(FV.vertices(:));
 % Calculate the normals 
 FV.normals=patchnormals(FV);
 % Set the ModelViewMatrix
 FV.modelviewmatrix=[1 0 0 0; 0 1 0 0;0 0 1 0; 0 0 0 1];
 % Load the texture
 FV.textureimage=im2double(imread('lena.jpg'));
 % Make texture coordinates in range [0..1]
 FV.texturevertices=(FV.vertices(:,1:2)+1)/2;
 % Set the material to shiny values
 FV.material=[0.3 0.6 0.9 20 1.0];
 % Set the light position
 FV.lightposition=[0.67 0.33 -2 1];
 % Set the viewport 
 FV.viewport=[64 64 128 128];
 FV.enableshading=1;
 FV.enabletexture=1;
 FV.culling=1;
 % Render the patch
 J=renderpatch(I,FV); 
 %Show the RGB buffer
 figure, h=imshow(J(:,:,1:3));
 % Rotate the object slowly while showing the render result
 for i=1:1000
    transm = transformmatrix(1+sin(i/10)/30,[0 0.05 0.05],[0 0 0]);
    FV.modelviewmatrix = transm*FV.modelviewmatrix;
    J=renderpatch(I,FV); set(h,'CData',J(:,:,1:3)); drawnow('expose');
 end