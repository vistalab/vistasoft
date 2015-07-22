function camBV2Scheme(bval_filename,bvec_filename,scheme_filename)
%Converts mrVIsta b-values and vectors to the camino scheme format
%
%   camBV2Scheme(bval_filename,bvec_filename,scheme_filename)
%
%
% (c) Stanford Vista, Sherbondy, 2010

bvec_opt = [' -bvecfile ' bvec_filename];
bval_opt = [' -bvalfile ' bval_filename];

% First, guess at what units the bvals are in as camino expects kg,s,m
% units or specifically s/m^2 and we often get them in two other standard 
% forms, e.g., b=800 (s/mm^2) or b = 0.8 (ms/micron^2)
b = dlmread(bval_filename);
if any(b>100)
    bscale = '1E6';
else
    bscale = '1E9';
end

xform_opt = [' -bscale ' bscale ' -flipz -flipy -flipx '];

% Has to be scheme2 format so lets strip any provided extension
[pathstr, name, ext] = fileparts(scheme_filename);
scheme_filename = fullfile(pathstr,[name '.scheme2']);
scheme_opt = [' > ' scheme_filename];

cmd = ['fsl2scheme' bvec_opt bval_opt xform_opt  scheme_opt];

display(cmd);
system(cmd,'-echo');

return
