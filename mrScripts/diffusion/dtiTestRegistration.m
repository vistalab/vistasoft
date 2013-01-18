doChild = true;
tdir = '/silver/scr1/data/templates/';
baseDir = '/biac2/wandell2/data/reading_longitude/';
    
if(doChild)
    baseDir = fullfile(baseDir,'dti','*0*');
    tdir = fullfile(tdir,'child');
    % es's data are OK now.
    %excludeList = {'es041113','tk040817'};
    excludeList = {'tk040817'};
    tBaseName = 'SIRL%02d';
else
    baseDir = fullfile(baseDir,'dti_adults','*0*');
    tdir = fullfile(tdir,'adult_new');
    excludeList = {'ah051003','gf050826','da050311','bw040806'};
    tBaseName = 'SIRL%02dadult';
end
[files,subCodes] = findSubjects(baseDir, '*_dt6_noMask',excludeList);
N = length(files);
tensorInterpMethod = 1;
useBrainMask = true;
mmPerVox = [1 1 1];

d1 = load(files{1},'anat');
RD = double(d1.anat.img);
%figure;imagesc(makeMontage(RD)); axis image;colormap(gray)
d2 = load(files{2},'anat');
TD = double(d2.anat.img);
%figure;imagesc(makeMontage(TD)); axis image;colormap(gray)
viewPara = viewImage('set','viewer','imgmontage','colmap',gray(256));

TD = TD./max(TD(:)).*255;
padSize = ([256 256 256]-size(TD))/2;
TD = padarray(TD, floor(padSize), 0, 'pre');
TD = padarray(TD, ceil(padSize), 0, 'post');
RD = RD./max(RD(:)).*255;
padSize = ([256 256 256]-size(RD))/2;
RD = padarray(RD, floor(padSize), 0, 'pre');
RD = padarray(RD, ceil(padSize), 0, 'post');
Omega = d2.anat.mmPerVox.*size(TD);
save([subCodes{1} '_' subCodes{2}],'RD','TD','Omega','viewPara');

% TO run the image registration:
setupData
runMLIR



[im,mm,hdr] = loadAnalyze(prevTemplate);
ac = round(mrAnatXformCoords(inv(hdr.mat),[0 0 0]));
