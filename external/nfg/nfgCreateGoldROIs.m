function nfgCreateGoldROIs(phantomDir)
%Create gold standard ROIs for BlueMatter NFG tests.
%
%   nfgCreateGoldROIs(phantomDir)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

% Input Files
volExFile = nfgGetName('volExFile',phantomDir);
% Output Files
gmROIFile = nfgGetName('gmROIFile',phantomDir);
wmROIFile = nfgGetName('wmROIFile',phantomDir);

% Create sphere gray and white matter ROIs as all NFG phantoms are spheres
vol = niftiRead(volExFile);
gm = vol; gm.fname = gmROIFile;
wm = vol; wm.fname = wmROIFile;
gm.data(:) = 0;
wm.data(:) = 0;
for kk=1:size(wm.data,3)
    for jj=1:size(wm.data,2)
        for ii=1:size(wm.data,1)
            v = ([ii,jj,kk]-0.5)/(size(gm.data,1)/2) - 1 ;
            if norm(v) <= 1.1
                wm.data(ii,jj,kk) = 1;
                if norm(v) > 0.9
                    gm.data(ii,jj,kk) = 1;
                end
            end
        end
    end
end
writeFileNifti(wm);
writeFileNifti(gm);

return;
