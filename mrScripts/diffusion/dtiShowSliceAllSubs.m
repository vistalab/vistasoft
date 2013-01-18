f = findSubjects('/silver/scr1/dti/trilinear_PPD','',{'...','mb041004','nad040610','vt040717','zs040630'});
n = length(f);
for(ii=1:n)
    dt = load(f{ii}, 'anat', 'b0', 'dt6');
    if(ii==1)
        sz = size(dt.anat.img);
        t1_a = zeros([sz(1) sz(2) n]);
        t1_s = zeros([sz(1) sz(3) n]);
        t1_c = zeros([sz(2) sz(3) n]);
        t1Avg = zeros(sz);
        sz = size(dt.b0);
        b0_a = zeros([sz(1) sz(2) n]);
        b0_s = zeros([sz(1) sz(3) n]);
        b0_c = zeros([sz(2) sz(3) n]);
        b0Avg = zeros(sz);
        dt6Avg = zeros(size(dt.dt6));
    end
    t1_a(:,:,ii) = squeeze(dt.anat.img(:,:,91));
    t1_s(:,:,ii) = squeeze(dt.anat.img(:,109,:));
    t1_c(:,:,ii) = squeeze(dt.anat.img(91,:,:));
    t1Avg = t1Avg + dt.anat.img./max(dt.anat.img(:));
    b0_a(:,:,ii) = squeeze(dt.b0(:,:,46));
    b0_s(:,:,ii) = squeeze(dt.b0(:,55,:));
    b0_c(:,:,ii) = squeeze(dt.b0(46,:,:));
    b0Avg = b0Avg + dt.b0./max(dt.b0(:));
    dt6Avg = dt6Avg + dt.dt6;
    %disp(dt.anat.xformToAcPc);
end

figure; imagesc(makeMontage(t1_a)); axis image; colormap gray;
figure; imagesc(makeMontage(t1_s)); axis image; colormap gray;
figure; imagesc(makeMontage(t1_c)); axis image; colormap gray;

figure; imagesc(makeMontage(b0_a)); axis image; colormap gray;
figure; imagesc(makeMontage(b0_s)); axis image; colormap gray;
figure; imagesc(makeMontage(b0_c)); axis image; colormap gray;

figure; imagesc(makeMontage(t1Avg)); axis image; colormap gray;
figure; imagesc(makeMontage(b0Avg)); axis image; colormap gray;
figure; imagesc(makeMontage(permute(t1Avg,[3 1 2]),[29:size(t1Avg,2)-20])); axis image xy; colormap gray;

m = makeMontage(permute(t1Avg,[3 2 1]),[32:size(t1Avg,1)-30]);
figure; imagesc(m); axis image xy; colormap gray;
m = makeMontage(permute(b0Avg,[3 2 1]),[16:size(b0Avg,1)-15]);
figure; imagesc(m); axis image xy; colormap gray;