function J=renderpatch(I,FV)
% This function RENDERPATCH renders a triangulated patch to an image.
% With features as phongshading, color interpolation and texture. 
%
% Compile the c++code befor using with "mex renderpatch.cpp -v", note 
% that the default LCC compiler doesn't support c++ files.
%
%
%   J=renderpatch(I,FV);
%
% inputs,  (All inputs must be of data type double !)
%   I : A matrix with sizes M x N x 6, which describes 
%       the R,G,B,A, depth buffer and stencil buffer before rendering. The RENDERPATCH
%       function uses a depth check on the renderd polygons, thus make 
%       sure that I(:,:,5) contains a high value.
%   FV : A structure which can contain the patch and all other render options.
%
% ouputs,
%   I : A matrix with sizes M x N x 6, which describes 
%       the R,G,B,A depth buffer and stencil buffer after rendering
%
% FV,
%   FV.vertices : The vertices of the triangulated mesh (N x 3 array)
%   FV.faces : The faces (vertice indices) of the triangulated mesh (M x 3 array)
%
% (Optional Options)
%
%   FV.normals : The normals on the vertices (can be calculated with patchnormals.m)
%   FV.material : Material of faces, [1 x 5] array. Sets the ambient, diffuse, 
%                 specular strength and specular exponent and specular
%                 color reflectance
%                 examples:
%                 Shiny	[0.3 0.6 0.9 20 1.0]
%                 Dull  [0.3 0.8 0.0 10 1.0]
%                 Metal	[0.3 0.3 1.0 25 0.5]
%   FV.lightposition : The light(s) must be a 1x4 or kx4 array with x,y,z,d, 
% 		 with d=0 for parallel light, then x,y,z is the light direction
% 		 and d=1 for point light, then x,y,z is the light position
%
%   FV.color : The color of the vertices (N x 3 array) or ( 1 x 3) array.
%
%   FV.texturimage : An image
%   FV.texturevertices : Texture image coordinates (N x 2 array) with range [0..1]
%   
%   FV.depthfunction : Depth test, integer value [0..7] (see stencil
%                           function, with reference value z-depth in buffer)
%   FV.stencilfunction : Stencil test, integer value [0..7]
%       0 : NEVER 	 always fails
%       1 : ALWAYS 	 always passes
%       2 : LESS 	 passes if reference value is less than buffer
%       3 : LEQUAL 	 passes if reference value is less than or equal to buffer
%       4 : EQUAL 	 passes if reference value is equal to buffer
%       5 : GEQUAL 	 passes if reference value is greater than or equal to buffer
%       6 : GREATER  passes if reference value is greater than buffer
%       7 : NOTEQUAL passes if reference value is not equal to buffer
%   FV.stencilreferencevalue : Stencil reference value
%   FV.stencilfail : Change Stencil buffer, integer value [0..4]
%   FV.stencilpassdepthbufferfail : Change Stencil buffer, integer value [0..4]
%   FV.stencilpassdepthbufferpass : Change Stencil buffer, integer value [0..4]
%       0 : KEEP 	value unchanged
%       1 : ZERO 	value set to zero
%       2 : REPLACE value replaced by reference value
%       3 : INCR 	value incremented
%       4 : DECR 	value decremented
%       5 : CULL    value incremented by front-facing decremented by back-facing
%   FV.depthbufferwrite : If value one write depth buffer with new
%                           fragment depths (default)
%   FV.culling : If zero render all faces, if one render only front 
%                       facing faces, if -1 only render back facing faces
%   FV.blendfunction : 1x2 array with [sfactor dfactor], with integer
%                       values in range [0..14]
%       0 :  ZERO	
%       1 :  ONE	
%       2 :  SRC_COLOR	
%       3 :  ONE_MINUS_SRC_COLOR	
%       4 :  DST_COLOR	
%       5 :  ONE_MINUS_DST_COLOR	
%       6 :  SRC_ALPHA	
%       7 :  ONE_MINUS_SRC_ALPHA	
%       8 :  DST_ALPHA	
%       9 :  ONE_MINUS_DST_ALPHA	
%       10 : SRC_ALPHA_SATURATE	
%       11 : CONSTANT_COLOR	
%       12 : ONE_MINUS_CONSTANT_COLOR	
%       13 : CONSTANT_ALPHA	
%       14 : ONE_MINUS_CONSTANT_ALPHA	
%
%   FV.enableblending :  Set to 0 for disabling and 1 for enabling blending
%   FV.enabledepthtest : Set to 0 for disabling and 1 for enabling depthtest
%   FV.enablestenciltest : Set to 0 for disabling and 1 for enabling stenciltest
%   FV.enabletexture : Set to 0 for disabling and 1 for enabling texture
%   FV.enableshading : Set to 0 for disabling and 1 for enabling shading
%
%   The matrices for viewing are the ones used in OpenGL:
%   See, http://www.songho.ca/opengl/gl_transform.html
%
%   FV.modelviewmatrix : 4 x 4 matrix, Combined Model and View matrix
%           see OpenGL help GL_MODELVIEW 
%   FV.projectionmatrix : 4 x 4 matrix, Projection matrix as in 
%           see OpenGL help GL_PROJECTION   
%   FV.viewport : 1 x 4 array with, Viewport [x,y,width,height],
%           see OpenGL help glViewport(x, y, w, h);
%   FV.depthrange : 1 x 2 array with, Depth Range [n , f];
%           see OpenGL help glDepthRange(n, f);
%
% Function is written by D.Kroon University of Twente (February 2010)

