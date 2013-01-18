function images = rmfilter_energy(images, display)

% simlpe energy filter: 
%   (1) subtract background intenstity
%   (2) rectify
%   (3) divide by maximum 
%       (max = greatest absolute distance from background)  

try
    % look up min, max, and bk from screen calibration
    Cmap.min  = min(display.stimRgbRange);
    Cmap.max  = max(display.stimRgbRange);
    Cmap.bk   = display.backColorIndex;
catch
    % if not found assume them from image matrix
    Cmap.min  = min(images(:));
    Cmap.max  = max(images(:));
    Cmap.bk   = round(mean(images(:)));
end

images = double(images);
images = images - Cmap.bk;
images = sqrt(images.^2);
maxEnergy = double(max(Cmap.max - Cmap.bk, Cmap.bk - Cmap.min));
maxEnergy = double(maxEnergy);
images = images  / maxEnergy;

end