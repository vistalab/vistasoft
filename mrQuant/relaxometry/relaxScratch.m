
t1 = t1/1000;
sl = 181;

figure;imagesc(ni.data(:,:,sl));axis image;colormap gray;colorbar;title('bob');
figure;imagesc(t1(:,:,sl));axis image;colormap gray;colorbar;title('deoni');

wm = roipoly;
[x,y] = ind2sub(ni.dim(1:2),find(wm));
wmInds = sub2ind(ni.dim(1:3),x,y,ones(size(x))*sl);
gm = roipoly;
[x,y] = ind2sub(ni.dim(1:2),find(gm));
gmInds = sub2ind(ni.dim(1:3),x,y,ones(size(x))*sl);

dm = [mean(t1(wmInds)) std(t1(wmInds)); mean(t1(gmInds)) std(t1(gmInds))];
km = [mean(ni.data(wmInds)),std(ni.data(wmInds)); mean(ni.data(gmInds)) std(ni.data(gmInds))];

(dm(2,1)-dm(1,1))/mean(dm(:,2))

(km(2,1)-km(1,1))/mean(km(:,2))


% Save a bunch of slices
sl = 115;

im = flipud(t1(:,:,sl)');
im = im./max(im(:));
imwrite(im,sprintf('images/deoni_T1_%03d.png',sl));

im = flipud(ni.data(:,:,sl)');
im = im./max(im(:));
imwrite(im,sprintf('images/bob_T1_%03d.png',sl));

allData = cat(4,s(:).imData);
[img, clipVals] = mrAnatHistogramClip(allData(:),.4,.99);
clear img allData;
for(ii=1:length(s))
   im = flipud(s(ii).imData(:,:,sl)');
   im(im>clipVals(2)) = clipVals(2);
   im(im<clipVals(1)) = clipVals(1);
   im = im-clipVals(1);
   im = im./max(im(:));
   if(ii==find(tiInds))
      imwrite(im,sprintf('images/raw_IR_%03d.png',sl));
   else
      imwrite(im,sprintf('images/raw_%02ddeg_%03d.png',s(ii).flipAngle,sl));
   end
end



