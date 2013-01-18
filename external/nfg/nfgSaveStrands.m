function nfgSaveStrands(fg,radius,dirname,bundleID)

mkdir(dirname);

if notDefined('bundleID')
    % Only one bundle
    bundleID=zeros(length(fg.fibers),1);
elseif length(bundleID)==1
    bundleID=bundleID*ones(length(fg.fibers),1);
end

if notDefined('radius')
    % Only one radius
    radius=ones(length(fg.fibers),1);
elseif length(radius)==1
    radius=radius*ones(length(fg.fibers),1);
end

for ff=1:length(fg.fibers)
    strand = fg.fibers{ff}';
    % Append and prepend post and pre points that define first and last
    % orientations
    % Prepoint is in reverse direction as first to second
    prep = (strand(1,:)-strand(2,:)) + strand(1,:);
    % Postpoint is in reverse direction of second-to-last to last
    postp = (strand(end,:)-strand(end-1,:)) + strand(end,:);
    strand = [prep; strand; postp];
    filename = ['strand_' num2str(ff-1) '-' num2str(bundleID(ff)) '-r' num2str(radius(ff)) '.txt'];
    dlmwrite(fullfile(dirname,filename),strand,'\t');
end

return;