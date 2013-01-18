
%
% To generate the data from a raw P-file, use:
% /home/bob/bin/recon_lcmr1/grecons.lnx -i 3 -O P53248.7
%

saveImages = true;

%dirName = 'jl20040902/fieldmap';
dirName = pwd;
%fname = fullfile(dirName, 'fieldmaps', '6dir', 'P18432.7.mag');
[f,p] = uigetfile('*.mag','Select mag file...');
fname = fullfile(p,f);
sz = [128 128];
fid = fopen(fname,'r','l');
img = fread(fid,'int16');
fclose(fid);
nSlices = floor(length(img)./sz(1)./sz(2));
img = reshape(img, [sz nSlices]);
im1 = img(:,:,1:2:end-1);
im2 = img(:,:,2:2:end);
mag = (im1+im2)./2;
mag = permute(mag, [2 1 3]);
mag = mrAnatHistogramClip(mag, 0.4, 0.999);
figure; imagesc(makeMontage(mag)); axis equal off; colormap(gray);


b0 = makeCubeIfiles(fullfile(fileparts(fname),'B0'),sz(1),[],[],'l');
mask = mag<0.15;
b0(mask) = 0;
rng = [min(b0(:)) max(b0(:))];
cm = [flipud(hot(127)); [0 0 0; 0 0 0]; fliplr(hot(127))];
figure; imagesc(makeMontage(b0,[],[],9)); axis equal off tight; colormap(cm); 
set(gca,'Position',[0 0 1 1]); truesize;
h=colorbar('South');
set(get(h,'XLabel'),'String','Off Resonance (Hz)','Color','w');
set(h,'Position',[0.55 0.04 0.4 0.03],'XColor','w');
set(gcf,'PaperPositionMode','auto','Color','k','InvertHardCopy','off');
print(gcf, '-dpng', '-r90', 'B0_fieldmap.png');
%mrUtilMakeColorbar(cm, round([rng(1) rng(1)/2, 0, rng(2)/2 rng(2)]), 'Off Resonance (Hz)');

if(saveImages)
  imwrite(uint8(makeMontage(mag)*255+0.5),gray(256),'mag.png');
  imwrite(uint8((makeMontage(b0)-rng(1))/diff(rng)*255+0.5),cm,'fieldMap.png');
  print(gcf, '-dpng', '-r120', 'tv05_fieldMap_legend.png');
end

epi = makeCubeIfiles(fullfile(fileparts(fileparts(fname)),'dti','B0_001.dcm'));
epi = mrAnatHistogramClip(epi, 0.4, 0.999);
figure; imagesc(makeMontage(epi)); axis equal off; colormap(gray);

spm_defaults;
VG.uint8 = uint8(round(mag*255));
VG.mat = eye(4);
VF.uint8 = uint8(round(b0*255));
VF.mat = eye(4);
p = defaults.coreg.estimate;
%p.params = [0 0 0, 0 0 0];
%p.tol(1:6) = [0.04 0.04 0.04 0.002 0.002 0.002];
p.params = [0 0 0, 0 0 0, 1 1 1, 0 0 0];
p.tol = [0.02 0.02 0.02, 0.001 0.001 0.001, 0.01 0.01 0.01, 0.001 0.001 0.001];
rotTrans = spm_coreg(VG,VF,p);
xform = inv(VF.mat\spm_matrix(rotTrans(:)'));
bb=[1 128; 1 128; 1 52]';
b0_align = mrAnatResliceSpm(b0, xform, bb);
b0_align = mrAnatHistogramClip(b0_align, 0.2, 0.99);
figure; imagesc(makeMontage(b0_align)); axis equal off; colormap(gray);

figure; imagesc(makeMontage(b0_align-mag)); axis equal off; colormap(gray);
figure; imagesc(makeMontage(b0-mag)); axis equal off; colormap(gray);

mask = mag<.15;
%figure; imagesc(makeMontage(mask)); axis equal off; colorbar;

b = makeCubeIfiles(fullfile(dirName, 'B0'),128,[],[],'l');
% Gary's B0 is in Hertz (f, cycles/sec), but we want angular freq (w, rad/sec).
% w = 2*pi*f; f = w/(2*pi)
b = b./1000*2*pi;
% Fill in masked (low SNR) regions by linear interpolation along
% phase-encode direction only (in our case, the y-axis- matlab's first
% dim).
bNorm = b;
bNorm(mask) = 0;

figure; imagesc(makeMontage(bNorm)); axis equal off; colorbar;
title('Gary''s B0');
colormap([flipud(hot(32)); hot(32)]);


% [gy,gx,gz] = ind2sub(size(b), find(~mask(:)));
% [by,bx,bz] = ind2sub(size(b), find(mask(:)));
% sz = size(bNorm);
% for(zn=1:sz(3))
%     for(xn=bx')
%         for(yn=by')
%             % find the two good values that bracket the bad region (along
%             % phase encode direction only).
%             yUpper = max(gy(gy<yn));
%             yLower = min(gy(gy>yn));
%             if(isempty(yUpper) | isempty(yLower))
%                 newVal = 0;
%             else
%                 newVal = (b(yUpper,xn,zn) + b(yLower,xn,zn))/2;
%             end
%             bNorm(yn,xn,zn) = newVal;
%         end
%     end
% end
% bNorm(mask) = (bNorm(sub2ind(size(b),yUpper, x, z)) ...
%     + bNorm(sub2ind(size(b),yLower, x, z)))./2;
%b = dtiSmooth3(b,2);
