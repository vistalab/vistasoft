function [b0Im,im,xform] = dtiFieldmapGet(pfile, dwRawFile, outFile)
%
% fm = dtiFieldmapGet(pfile, dwRawFile, [outFile])
%
% cd /biac3/wandell4/data/reading_longitude/dti_adults/rfd070508/raw
% [fm,im,xform] = dtiFieldmapGet('P22016.zip','dti_g13_b800_b0.nii.gz');
% dtiWriteNiftiWrapper(single(im), xform, 'fieldMapImage', 1, 'Field map image');
% dtiWriteNiftiWrapper(single(fm), xform, 'fieldMap', 1, 'Field map (Hz)');
%
% HISTORY
% 2009.10.30 RFD wrote it.
%

%grecons = '/usr/local/bin/grecons_rev32';
writehdr = '/biac2/kgs/dataTools/writeihdr';
grecons = '/biac2/kgs/dataTools/grecons.lnx';

if(~exist('outFile','var'))
    if(nargout<1)
        [p,f] = fileparts(dwRawFile); 
        [j,f] = fileparts(f);
        [f,p] = uiputfile('*.nii.gz', 'Save fieldmap as...', fullfile(p,[f '_fieldmap.nii.gz']));
        outFile = fullfile(p,f);
    end
end

tmpDir = tempname;
mkdir(tmpDir);
oldDir = pwd;

% make sure pfile and dwRawFile are full path specs:
[p,f,e] = fileparts(pfile);
if(isempty(p)), pfile = fullfile(pwd,pfile); end
[p,f,e] = fileparts(dwRawFile);
if(isempty(p)), dwRawFile = fullfile(pwd,dwRawFile); end

cd(tmpDir);

[p,f,e] = fileparts(pfile);
if(strcmpi(e,'.zip'))
    tmpPfile = unzip(pfile);
    tmpPfile = tmpPfile{1};
elseif(strcmpi(e,'.gz'))
    tmpPfile = gunzip(pfile,tmpDir); 
    tmpPfile = tmpPfile{1};
elseif(strcmpi(e,'.7'))
    tmpPfile = [f e];
    if(~strcmp(pfile,tmpPfile))
        copyfile(pfile,tmpPfile);
    end
else
    error('Unknown pfile format. Must be a PNNNNN.7 file (can be gzipped or zipped)');
end

unix([grecons ' ' tmpPfile]);

rawHdr = niftiRead(dwRawFile, []);
b0Im = zeros(rawHdr.dim(1:3));
xform = rawHdr.qto_xyz;

b0Files = dir('B0.*');
for(ii=1:numel(b0Files))
    sl = readRawImage(b0Files(ii).name, [], [], 'l');
    b0Im(:,:,ii) = sl;
end

imFiles = dir([tmpPfile '.*']);
im = zeros([rawHdr.dim(1:2) numel(imFiles)]);
for(ii=1:numel(imFiles)-1)
    sl = readRawImage(imFiles(ii).name, [], [], 'l');
    im(:,:,ii) = sl;
end
im = (im(:,:,1:2:end)+im(:,:,2:2:end))./2;

im = flipdim(permute(im,[2 1 3]),2);
b0Im = flipdim(permute(b0Im,[2 1 3]),2);

cd(oldDir);

return

