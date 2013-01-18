function camDTIShape(stat, eig_filename, shape_filename)
%Calculate DTI shape statistic from camino tensor fits
%
%  camDTIShape(stat, eig_filename, shape_filename)
%
%  Input:
%   stat - string for DTI shape statistic to calculate, can be (l1, l2, l3,
%       tr, md, rd, fa, ra, cl, cp, cs and 2dfa)
%
%
% (c) Stanford, 2010, Sherbondy and VISTA

% Handle the one special case where l1 and ad mean the same thing
if strcmp(stat,'ad')
    stat = 'l1';
end

if strcmp(stat,'cl') || strcmp(stat,'cp') || strcmp(stat,'cs')
    error('Currently we can trust the Camino calculation of Westin shape indices!');
else 
    cmd = ['dtshape -inputfile ' eig_filename ' -stat ' stat ' > ' shape_filename];
    display(cmd);
    system(cmd,'-echo');
end

return;
