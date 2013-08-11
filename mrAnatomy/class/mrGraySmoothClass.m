

fname = 't1_man_seg_class.nii.gz';
hemi = 'left';
s = 2;

ni = niftiRead(fname);
l = mrGrayGetLabels;

% Process left hemisphere
wmL = ni.data==l.leftWhite;
wmLs = dtiSmooth3(double(wmL),s);
wmLs = wmLs>=0.5;

% Process right
wmR = ni.data==l.rightWhite;
wmRs = dtiSmooth3(double(wmR),s);
wmRs = wmRs>=0.5;

ni.data(wmL|wmR) = 0;
ni.data(wmRs) = l.rightWhite;
ni.data(wmLs) = l.leftWhite;

ni.fname = [fname(1:strfind(fname,'.nii.gz')-1) sprintf('_smooth%d.nii.gz',s)];

writeFileNifti(ni);
