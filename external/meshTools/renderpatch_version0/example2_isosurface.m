 % Load volume data
 load MRI; D=squeeze(D); D=smooth3(D);
 % Calculate iso surface patch
 FV=isosurface(D,5);
 % Get iso normals form the volume data;
 FV.normals = -isonormals(D,FV.vertices);
 % Make the coordinates in range 0..1
 FV.vertices(:,3)=FV.vertices(:,3)*3;
 FV.vertices = FV.vertices-mean(FV.vertices(:));
 FV.vertices = FV.vertices ./max(FV.vertices(:));
 % Make the buffers RGB, and depth
 I = zeros(512,512,6); I(:,:,5)=1;
 % Set the ModelViewMatrix
 FV.modelviewmatrix=[-0.45,0.84,-0.29,0;-0.30,-0.45,-0.83,0;0.83,0.29,-0.46,0;0,0,0,1];
 % Set color to blue
 FV.color=[0 0 1];
 % enable light
 FV.enableshading=1;
 FV.lightposition=[0.67 0.33 -2 1];

 % Render the patch
 J=renderpatch(I,FV); 
 figure,
 subplot(1,2,1),imshow(J(:,:,1:3)), title('rendered patch');
 subplot(1,2,2),imshow(J(:,:,4),[]), title('depthbuffer');