function imageMesh = dtiInitMrMeshWindow(imageMesh,bColor,wSize);
%
%   imageMesh = dtiInitMrMeshWindow(imageMesh,bColor,wSize);
%
%Author: Wandell
%Purpose:
%  Initialize the properties of the mrMesh window
%

if ieNotDefined('bColor'), bColor = [0.0 0.0 0.0]; end
if ieNotDefined('wSize'), wSize = [512,512]; end

mrmSet(imageMesh,'background',bColor);
mrmSet(imageMesh,'windowSize',wSize(1),wSize(2));
%mrmSet(imageMesh,'hidecursor');
mrmSet(imageMesh,'title','DTI');
mrmSet(imageMesh,'originlines',0);

imageMesh = dtiAddLights(imageMesh);

return;
