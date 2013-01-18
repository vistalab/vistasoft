
classFiles = {'/biac2/wandell2/data/reading_longitude/dti/bg040719/left/20050318/left.Class',...
    '/biac2/wandell2/data/reading_longitude/dti/bg040719/right/20050321/right.Class'};
mmPerVox = [1 1 1];
    
tmp = readClassFile(classFiles{1},0,0);
wm = tmp.data==tmp.type.white;
for(ii=2:length(classFiles))
    tmp = readClassFile(classFiles{ii},0,0);
    wm = wm|(tmp.data==tmp.type.white);
end

%msh = meshBuildFromClass(wm,mmPerVox);
[msh,lights,tenseMsh] = mrmBuildMesh(uint8(wm), mmPerVox, 'localhost', -1, 'RelaxIterations', 1);

mshInflated = mrmInflate(msh.data,600);

meshVisualize(mshInflated);

