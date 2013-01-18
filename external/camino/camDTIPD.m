function camDTIPD(eig_filename, pd_filename)
%Extract principal diffusion directions from eigen decomposition
%
%  camDTIPD(eig_filename, pd_filename)
%
%
%
% (c) Stanford, 2010, Sherbondy and VISTA


cmd = ['shredder 8 24 72 < ' eig_filename ' > ' pd_filename];
display(cmd);
system(cmd,'-echo');

return;
