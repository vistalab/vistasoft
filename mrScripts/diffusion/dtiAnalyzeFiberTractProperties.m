

%h = guidata(6);
h = guidata(gcf);
fg = h.fiberGroups(h.curFiberGroup);
% interp method can be 'nearest'|'trilin'|'spline'. If you are going to
% just average a bunch of these values, it's probably best to use nearest. 
interp = 'nearest'; 
md = dtiGetValFromFibers(h.dt6, fg, inv(dtiGet(h,'dt6xform')),'md',interp);
fa = dtiGetValFromFibers(h.dt6, fg, inv(dtiGet(h,'dt6xform')),'fa',interp);
ln = dtiGetValFromFibers(h.dt6, fg, inv(dtiGet(h,'dt6xform')),'linearity',interp);

%alignSlice = [nan -55 nan]; % the alignment position (in mm from AC)
alignSlice = [nan nan 28]; % the alignment position (in mm from AC)
ax = find(~isnan(alignSlice));
sl = alignSlice(ax);
if(length(ax)~=1) error('specify just one alignment axis!'); end
if(ax==1) axName='LR'; elseif(ax==2) axName='AP'; else axName='SI'; end
nPts = 20;
nFibers = length(fg.fibers);
fiberFa = zeros(nFibers, nPts*2+1)*nan;
fiberMd = fiberFa; fiberLn = fiberFa;
fiberCoords = zeros(nFibers, nPts*2+1,3)*nan;
for(ii=1:length(fg.fibers))
    d = abs(fg.fibers{ii}(ax,:)-alignSlice(ax));
    nearInd = find(d==min(d));
    if(nearInd-nPts<=1 | nearInd+nPts>=length(fg.fibers{ii}))
        continue;
    end
    fDir = fg.fibers{ii}(ax,[nearInd-1,nearInd+1]);
    inds = [nearInd-nPts:nearInd+nPts];
    % We skip the fiber end-points, since the FA there can be misleading
    if(fDir(2)<fDir(1)) inds = fliplr(inds); end
    goodInds = inds>1 & inds<length(d);
    fiberFa(ii,goodInds) = fa{ii}(inds(goodInds));
    fiberMd(ii,goodInds) = md{ii}(inds(goodInds));
    fiberLn(ii,goodInds) = ln{ii}(inds(goodInds));
    fiberCoord(ii,goodInds,:) = fg.fibers{ii}(:,inds(goodInds))';
end

xlab = [axName ' step (mm)'];
x = [sl-nPts:sl+nPts];
%x = mean(fiberCoord(:,:,ax),1);

mnFa = nanmean(fiberFa);
sdFa = nanstd(fiberFa);
figure;errorbar(x,mnFa,sdFa,sdFa);
hold on;
plot(x,min(fiberFa),'c');
hold off;
y = get(gca,'YLim');
line([sl,sl],y,'color','r');
xlabel(xlab); ylabel('Mean FA');

mnMd = nanmean(fiberMd);
sdMd = nanstd(fiberMd);
figure;errorbar(x,mnMd,sdMd,sdMd);
y = get(gca,'YLim');
line([sl,sl],y,'color','r');
xlabel(xlab); ylabel('Mean Diffusivity (mm^2/s*10^-^6)');

mnLn = nanmean(fiberLn);
sdLn = nanstd(fiberLn);
figure;errorbar(x,mnLn,sdLn,sdLn);
y = get(gca,'YLim');
line([sl,sl],y,'color','r');
xlabel(xlab); ylabel('Linearity Index');


error('stop here');

tdir = '/biac2/wandell2/data/reading_longitude/templates/child/SIRL53warp3';
h = guidata(1);
fg = h.fiberGroups(h.curFiberGroup);
alignSlice = [nan nan 28]; % the alignment position (in mm from AC)
ax = find(~isnan(alignSlice));
sl = alignSlice(ax);
if(length(ax)~=1) error('specify just one alignment axis!'); end
if(ax==1) axName='LR'; elseif(ax==2) axName='AP'; else axName='SI'; end
nPts = 20;
nFibers = length(fg.fibers);
% interp method can be 'nearest'|'trilin'|'spline'. If you are going to
% just average a bunch of these values, it's probably best to use nearest. 
interp = 'nearest'; 

snFiles = findSubjects(tdir, '*_sn*',{});
N = length(snFiles);
gFiberFa = zeros(nFibers, nPts*2+1, N)*nan;
gFiberMd = fiberFa; fiberLn = fiberFa;
gFiberCoords = zeros(nFibers, nPts*2+1,3)*nan;
for(subNum=1:N)
    disp(['Loading ' snFiles{subNum} '...']);
    dt = load(snFiles{subNum});
    dt.dt6(isnan(dt.dt6)) = 0;
    md = dtiGetValFromFibers(dt.dt6, fg, inv(dt.xformToAcPc), 'md', interp);
    fa = dtiGetValFromFibers(dt.dt6, fg, inv(dt.xformToAcPc), 'fa', interp);
    ln = dtiGetValFromFibers(dt.dt6, fg, inv(dt.xformToAcPc), 'linearity', interp);

    for(ii=1:length(fg.fibers))
        d = abs(fg.fibers{ii}(ax,:)-alignSlice(ax));
        nearInd = find(d==min(d));
        fDir = fg.fibers{ii}(ax,[nearInd-1,nearInd+1]);
        inds = [nearInd-nPts:nearInd+nPts];
        % We skip the fiber end-points, since the FA there can be misleading
        if(fDir(2)<fDir(1)) inds = fliplr(inds); end
        goodInds = inds>1 & inds<length(d);
        gFiberFa(ii,goodInds,subNum) = fa{ii}(inds(goodInds));
        gFiberMd(ii,goodInds,subNum) = md{ii}(inds(goodInds));
        gFiberLn(ii,goodInds,subNum) = ln{ii}(inds(goodInds));
        gFiberCoord(ii,goodInds,:) = fg.fibers{ii}(:,inds(goodInds))';
    end
end

ssMnFa = nanmean(fiberFa, 1);
%sdFa = nanstd(fiberFa);
gMnFa = squeeze(nanmean(gFiberFa, 1));
mnGMnFa = nanmean(gMnFa, 2);
sdGMnFa = nanstd(gMnFa, 0, 2);
semGMnFa = sdGMnFa/sqrt(N-1);
figure;errorbar(x, mnGMnFa, semGMnFa, semGMnFa);
hold on;
plot(x,ssMnFa,'r');
hold off;
y = get(gca,'YLim');
line([sl,sl],y,'color','r');
xlabel(xlab); ylabel('Mean FA');

ssMnMd = nanmean(fiberMd, 1);
%sdFa = nanstd(fiberFa);
gMnMd = squeeze(nanmean(gFiberMd, 1));
mnGMnMd = nanmean(gMnMd, 2);
sdGMnMd = nanstd(gMnMd, 0, 2);
semGMnMd = sdGMnMd/sqrt(N-1);
figure;errorbar(x, mnGMnMd, semGMnMd, semGMnMd);
hold on;
plot(x,ssMnMd,'r');
hold off;
y = get(gca,'YLim');
line([sl,sl],y,'color','r');
xlabel(xlab); ylabel('Mean MD (mm^2/s*10^-^6)');

