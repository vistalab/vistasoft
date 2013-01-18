

fname = '/biac1/wandell/data/anatomy/winawer/t1_class.nii.gz';

[cd,mm] = readClassFile(fname,0,0,'left');

% Process left hemisphere
wmL = uint8(cd.data==cd.type.white);
%[msh,lights,tenseMsh] = mrmBuildMesh(wmL, mm, 'localhost', 1);
msh = build_mesh(wmL,mm);

% Process right
[cd,mm] = readClassFile(fname,0,0,'right');

wmR = uint8(cd.data==cd.type.white);
%[msh,lights,tenseMsh] = mrmBuildMesh(wmL, mm, 'localhost', 1);
msh = build_mesh(wmR,mm);
