function remixByICA(filebase, img0, img1, epoch)
% function remixByICA(filebase, img0, img1, epoch)
%
% manual selection of ICs for remixing to generate denoised data files
% version 1.0: April 15, 2004
%
% filebase: filename with full path up to the run number, 
%           e.g., '/marr3/ntt3/exp/ntt3r01'
% img0: the first img number, e.g.,  5 if ...i005.img is the first
% img1: the last img number to be analyzed, e.g., ....i144.img is the last
% epoch: event onset time list
% example) remixByICA('/marr3/ntt3/exp/ntt3r01', 5, 144, [9 35 70])

switch nargin,
    case {0, 1, 2},
        eval(['help remixByICA'])
        return;
    case 3,
        ep= zeros(img1-img0, 1)';
    case 4,
        ep = zeros(img1-img0, 1)';
        ep(epoch)=1;
end

filebase = [filebase '_mcf'];
%=== load melodic results for further analysis
fname = [filebase '.ica' DM 'mask'];
[maskImg, dims, scales, bpp, endian] = read_avw(fname);
maskImg = reshape(maskImg, dims(1)*dims(2), dims(3));
maskIdx = find(maskImg);
clear dims scales bpp endian % to avoid confusion with those from IC file

ICfname = [filebase '.ica' DM 'melodic_IC'];
[dim, vox, scale, type, off, orig, desc] = fslHread(ICfname);
[img, dims, scales, bpp, endian] = read_avw(ICfname);
switch type
    case 2, dtype = 'uint8';
    case 4, dtype = 'int16';
    case 16, dtype = 'float';
    otherwise, disp(['unknown data type in ' ICfname]); return
end

disp([filebase '.ica' DM 'melodic_mix is loaded for selection']);
%load([filebase '.ica' DM 'melodic_mix'], '-ascii');
load([filebase '.ica' DM 'melodic_mix']);
A = melodic_mix;

paramList = zeros(dims(4),6);   % matrix for saving results of IC selection

%=== parameters based on FFT of IC time profile
signalF = 10;
nImg = size(A,1);

fA = abs(fft(melodic_mix));
nfA = fA - repmat(min(fA,[],1),size(fA,1),1);
nfA = nfA ./ repmat(max(nfA,[],1),size(nfA,1),1);
lRatio = max(fA(2:3,:)) ./ max(fA(signalF:signalF+2,:));
uRatio = max(fA(fix(nImg/4):fix(nImg/2),:)) ./ max(fA(signalF:signalF+2,:));

%=== IC-by-IC analysis
Imat = reshape(img,dims(1)*dims(2)*dims(3),dims(4));
maxVal = max(abs(Imat), [], 1);

figure(1)
set(gcf, 'Name', [filebase '.ica' DM 'melodic_mix'], 'NumberTitle', 'off')
%colormap('gray')

prevcue = 0;
if exist([filebase '.ica' DM 'melodic_mix_denoised']);
	B = dlmread([filebase '.ica' DM 'melodic_mix_denoised']);
	disp([filebase '.ica' DM 'melodic_mix_denoised is loaded']);
	prevcue = 1;	
end

i = 0;
disp('Choices')
disp('0:zero this IC in reconstruction')
disp('1:original IC kept in reconstruction')
disp('b:show previous IC')
disp('r:restart from IC#1')
disp('')

while i < dims(4),
    i = i+1;
    if i < 1, i = 1; end
    
    %=== parameter to measure smoothness over slices
    reimg = abs(reshape(img(:,:,:,i), dims(1)*dims(2), dims(3)));
    maxreimg = max(reimg,[],1);
    [maxV, maxI] = max(maxreimg);
    [minV, minI] = min(maxreimg);
    neighborIdx = [];
    if (maxI > 1) neighborIdx = [neighborIdx maxI - 1]; end
    if (maxI < size(reimg,2)) neighborIdx = [neighborIdx maxI + 1]; end
    neighborV = mean(maxreimg(neighborIdx));
    mRatio = (maxV - neighborV) / (maxV - minV);
    
    %=== parameter to measure fluctuation over odd- vs even- slices
    onePrct = prctile(reimg(:),99);
    onePrctIdx = find(reimg > onePrct);
    actAreas = zeros(size(reimg));
    actAreas(onePrctIdx) = 1;
    actSliceRatio = sum(actAreas);
    aRatio = abs(sum(actSliceRatio(1:2:end)) - sum(actSliceRatio(2:2:end))) / sum(actSliceRatio); 
    
    %=== parameter to measure smoothness over time course of an IC
    dA = diff(A(:,i));
    dRatio = range(dA) / iqr(dA);

    %=== algorithm to pick noise ICs from genuine activation ICs, very tricky!
    accept = 0; % default reject
    if (mRatio < 0.6) & (uRatio(i) < 1.5) & (aRatio < 0.4) & (lRatio(i) < 4) & (dRatio < 10),
        accept = 1;
    end
    
    % === displaying the slices of ith IC, slices higher than 20 will be overdrawn later
    maxVal = max(reshape(img,dims(1)*dims(2)*dims(3),dims(4)), [], 1);	
    for sl = 1:dims(3),
        subplot(6,5,sl)
        image(img(:,:,sl,i) / maxVal(i) * 255);
    end
    
    %subplot(5,5,[21:24])
    subplot(6,5,[26:29])
    plot(melodic_mix(:,i));
    axis tight
    xlabel(['Time course of IC#' num2str(i)])
    hold on
    subplot(6,5,[26:29])
    plot(ep, 'r');
    hold off
    
    subplot(6,5,30)
    plot(1:dims(3), maxreimg, 'k')
    axis tight
    xlabel('max value in each slice')

	%if B(:,i) ~= 0 & prevcue ==1,
	%	disp(['previous selected']);
	%end 
    if accept,
        resp = input(['IC' num2str(i) ': accept recommanded. Command? (0, 1, b, f as above) '],'s');
    else
        resp = input(['IC' num2str(i) ': reject recommanded. Command? (0, 1, b, f as above) '],'s');
    end

    switch resp,
        case 'b',
            i = i - 2;
        case {'0','p'}
            A(:,i) = 0;
        case {'1','q'}
            A(:,i) = melodic_mix(:,i);
        case 'r',
            i = 0;
        otherwise,
            A(:,i) = 0;
    end
end

%=== save the denixing matrix
dlmwrite([filebase '.ica' DM 'melodic_mix_denoised'], A, '  ');
disp([filebase '.ica' DM 'melodic_mix_denoised is saved']);

%=== mix the IC with denoised mixing matrix to yield "better" data 
X = (A * Imat')';

%=== Gaussian filtering to remove residual noise
X = reshape( X, dims(1), dims(2)*dims(3)*nImg );
gfkernel = fspecial('gaussian', 5, 1); % sigma of 1 voxel is approximately 4 mm, so that FWHM is about 7-8 mm
X = reshape( conv2( X, gfkernel, 'same'), prod(dims(1:3)), nImg );

%=== save denoised and filtered files to individual 3D volumes
vox = [1.72 1.72 4.00];
%vox = [1.72 1.72 5.00];
orig = [66 77 9];
%vox = [1.18 1.18 5.00];
%orig = [67 80 12];

for i = 1:nImg,
    outfname = [filebase '_dn' sprintf('%.3d', i + img0 - 1) '.img'];
    fslHwrite(outfname, [dim(1:3) 1], vox, scale, type, off, orig, desc);
    fid = fopen(outfname, 'w');
    fwrite(fid, X(:,i), dtype);
    fclose(fid);
end
disp([outfname ' saved']);
