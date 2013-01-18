% Comment me 
%
% Script to generate screenshots 
% Saves in current dir: 

viewList={'back','left','right','bottom','top'};
viewVectors={[pi -pi/2 0],[pi 0 0],[0 0 pi],[pi/2 -pi/2 0],[-pi/2 -pi/2 0]};
v=getSelectedVolume;

idList = viewGet(v,'allwindowids');
thisID=idList(meshNum3d);

for thisView=1:length(viewList);
    cam.actor=0; 
    cam.rotation=rotationMatrix3d(viewVectors{thisView})
    mrMesh('localhost',v,'set',cam)
    c.filename=fullfile(pwd,viewList{thisView},'.bmp');
    
    
    [a,b,c]=mrMesh('localhost',v,'screenshot',c)
    
    disp(thisView)
end
