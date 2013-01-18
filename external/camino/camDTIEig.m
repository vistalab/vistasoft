function camDTIEig(dtfit_filename, eig_filename)
%Calculate DTI eigenvalues
%
%  camDTIEig(dti_filename, eig_filename)
%
%
%
% (c) Stanford, 2010, Sherbondy and VISTA


cmd = ['dteig < ' dtfit_filename ' > ' eig_filename];
display(cmd);
system(cmd,'-echo');

return;
