function writeTiffImage(vw,pathStr)
% Writes a tiff image of the view with the proper color map.
%
% writeTiffImage(vw,[pathStr])
%
% If pathStr unspecified, prompts user for a filename.
%
% djh, 12/30/98
% sod, 09/2005: could not find tiffwrite, so I replaced it with
% imwrite (matlab-function).
% im data is often not found.  We need to figure out how to get the data
% and then write it.  Rory has ways, and Michal has an e-mail about it.
%

if ~exist('pathStr','var')
  pathStr = input('Enter filename (full path): ','s');
end

try
  im = vw.ui.image;
  modeStr=['vw.ui.',vw.ui.displayMode,'Mode'];
  mode = eval(modeStr);
  cmap = mode.cmap;
  % tiffwrite does not exist?!
  %tiffwrite(im,cmap,pathStr);
  if isempty(im), myErrorDlg('No image data'); return; end
  if size(im,3)>1,
      imwrite(im,pathStr,'TIFF');
  else
      imwrite(im,cmap,pathStr,'TIFF');
  end
catch
  % hack
  im=get(get(gca,'Children'),'Cdata');
  if isempty(im), myErrorDlg('No image data'); return; end
   if size(im,3)>1,
      imwrite(im,pathStr,'TIFF');
  else
      imwrite(im,cmap,pathStr,'TIFF');
   end
end;


