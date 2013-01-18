function  vol2mrGray(outData,cmap,filename)
% 
% AUTHOR: Wandell
% DATE:   06.21.00
% PURPOSE:
% 
%     outData is Nx4
% The first three entries are a mrGray xyz location. 
% The last entry is an index into the color map cmap is the color map
% 

if ( (nargin < 3) | isempty(filename))
  [fname pname] = uiputfile('*.fun','mrGray Functional');
  if fname == 0
    return;
  end
  filename = [pname fname];
end

fid = fopen(filename,'w');
numColors = size(cmap,1);

if max(outData(:,4) > numColors
  error('Bad index values in 4th column:  Exceeds color map.');
else
  fprintf(fid,'%d\n',numColors);
end

% Write out the colormap [R,G,B] at the top of the file
%
fprintf(fid,'%d %d %d\n', cmap');

% Write out the location and index into the colormap for
% each data point.
%
fprintf(fid,'%d %d %d %d\n', [outData; cmapIdx(:)']);

fclose(fid);

fprintf('Saved mrGray functional data overlay %s\n',filename);

return;
