function camDTIFit(raw_bfloat_filename, scheme_filename, dtfit_filename)
%Fits the camino tensor model to raw data
%
%
%
% (c) Stanford Vista, Sherbondy, 2010

cmd = ['dtfit ' raw_bfloat_filename ' ' scheme_filename ' > ' dtfit_filename];
display(cmd);
system(cmd,'-echo');

return