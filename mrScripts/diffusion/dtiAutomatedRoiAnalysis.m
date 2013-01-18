h = guidata(gcf);
fg = h.fiberGroups(4);
fa = dtiGetValFromFibers(h.dt6, fg, dtiGet(h,'invdt6xform'), 'fa');

ap = unique(fg.seeds(:,2));
si = unique(fg.seeds(:,3));
[x,y] = ndgrid(ap, si);

apPos = fg.seeds(:,2);
siPos = fg.seeds(:,3);
for(ii=1:length(fa)) 
    mnFa(ii) = mean(fa{ii});
    sdFa(ii) = std(fa{ii});
end

imgMn = zeros(length(ap), length(si));
imgSd= imgMn;
imgProjection = repmat(imgMn,[1 1 3]);
for(ii=1:length(ap))
    for(jj=1:length(si))
        inds = find(apPos==ap(ii) & siPos==si(jj));
        if(length(inds)>0)
            imgMn(ii,jj) = mean(mnFa(inds));
            imgSd(ii,jj) = mean(sdFa(inds));
            fiber = fg.fibers{inds(1)};
            seed = fg.seeds(inds(1),:)';
            dir = fiber(:,1)-seed + fiber(:,end)-seed;
            dir = dir./norm(dir);
            imgProjection(ii,jj,:) = dir;
        end
    end
end
imgProjection = imgProjection.*0.5+0.5;
imgMn = imgMn'; imgSd = imgSd'; imgProjection = permute(imgProjection, [2 1 3]);
figure; 
subplot(3,1,1); imagesc(imgMn); axis image xy; colorbar('horiz'); colormap(hot); title('Mean FA');
subplot(3,1,2); imagesc(imgSd); axis image xy; colorbar('horiz'); colormap(hot); title('StdDev FA');
subplot(3,1,3); image(abs(imgProjection)); axis image xy; title('Projection');