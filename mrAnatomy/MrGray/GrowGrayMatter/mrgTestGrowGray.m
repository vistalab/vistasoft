


% Right
rClass = readClassFile('/biac1/wandell/data/anatomy/winawer/t1_class.nii.gz',false,false,'right');

tic; [rNodes,rEdges]=grow_gray(rClass.data,5); toc

mrgDisplayGrayMatter(rNodes, rEdges, 138, [60 100 120 160]);

% Left
lClass = readClassFile('/biac1/wandell/data/anatomy/winawer/t1_class.nii.gz',false,false,'left');

tic; [lNodes,lEdges] = grow_gray(lClass.data,5,lClass.header.voi); toc

mrgDisplayGrayMatter(lNodes,lEdges, 52, [100 140 100 140]);

mrmStart
rf = '/biac1/wandell/data/anatomy/winawer/t1_class_right.nii.gz';
msh = meshBuildFromClass(rf);
msh = meshSmooth(msh);
msh = meshColor(msh);
meshVisualize(msh);
