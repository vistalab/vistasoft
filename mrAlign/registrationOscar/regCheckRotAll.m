% regCheckRotAll - Script that interpolates the inplanes corresponding
%                to the estimated rotation (rot) and translation (trans)
%                and displays slice by slice the original inplanes, the
%                interpolated inplanes and a mosaic of both.
%
%  Oscar Nestares - 5/99
%

% Size of the original inplanes
[NyI NxI NzI] = size(INPLANE.anat);
inp = INPLANE.anat;

RESP = questdlg('Correct intensity?', 'Correct', 'Yes', 'No', 'Yes');

% interpolating the inplanes
hmsgbox = msgbox('Wait while interpolating the inplanes...'); drawnow
inpMf = regInplanes(reshape(volume,[sagSize, numSlices]),...
                    NxI, NyI, NzI, scaleFac, rot, trans);

if strcmp(RESP, 'Yes')
   Limit = 4;
   IntFunc = 'regEstFilIntGrad'; PbyPflag = 0;
   inp = regCorrMeanInt(inp);
   % intensity estimation
   [Int Noise] = feval(IntFunc, inp, PbyPflag); 
   % intensity normalization
   inp = regCorrIntGradWiener(inp, Int, Noise);
   % robust mean and contrast normalization
   inp = regCorrContrast(inp,Limit); 
   % intensity estimation
   [IntM NoiseM] = feval(IntFunc, inpMf, PbyPflag);
   % intensity normalization
   inpMf = regCorrIntGradWiener(inpMf, IntM, NoiseM);
   % robust mean and contrast normalization
   [inpMf, pM] = regCorrContrast(inpMf,Limit); 
end

close(hmsgbox);

% checking the alignment
FF = figure;
SS = get(0,'ScreenSize');
set(FF,'Position', [1 -40 SS(3)/3  SS(4)-80])
for k=1:size(inpMf,3)
   figure(FF)
   subplot(3,1,1)
   imagesc(inp(:,:,k));
   axis('image'); colormap('gray'); axis('off');
   subplot(3,1,2)
   imagesc(regMosaic(regNormal(inpMf(:,:,k),0,1),...
                     regNormal(inp(:,:,k),0,1)));
   axis('image'); colormap('gray'); axis('off');
   subplot(3,1,3)
   imagesc(inpMf(:,:,k));
   axis('image'); colormap('gray'); axis('off');
   disp('Press a key to continue...')
   pause
end

close(FF)
