function path = writeVolAnatShortHeader(imgCube, mmPerPix, fileName)
% path = writeVolAnat(imgCube, mmPerPix, [fileName])
% imgCube is a [rows,cols,planes] image array
% It must already be scaled to 0-255!
%
% mmPerPix is the pixels size, for [rows,cols,planes]
%		(eg. [240/256,240/256,1.2] is typical)
%
% fileName specifies the output file location (full path!)
% If it's omitted or ends in a filesep character, then a 
% save-file dialog box appears.
% (If fileName ends in a filesep, it is assumed to be a 
% default path to use for the dialog.)
% 
% RETURNS:
%   The path to where the vAnatomy ends up is returned, in
%   case you care.
% 
%
% 00.01.28 RFD
% 01.08.28 RFD: it now actually writes the mmPerPix in the header.
% 04.02.02 ARW : Removed mmPerPix in header- it screwed up too many things in mrLoadRet2.5
if ~exist('fileName', 'var')
   fileName = '';
end

% open file for writing (little-endian mode)
if isempty(fileName)
	[fname, path] = uiputfile('vAnatomy.dat', 'Save vAnatomy file...');
   fileName = [path fname];
elseif fileName(end) == filesep
	[fname, path] = uiputfile([fileName 'vAnatomy.dat'], 'Save vAnatomy file...');
   fileName = [path fname];
else
   path = fileName;
end

vFile = fopen(fileName,'w','l');
if vFile<1
   while vFile<1;
   disp('Couldn''t open that file- please try saving it somewhere else.');
	[fname, path] = uiputfile('vAnatomy.dat', 'Save vAnatomy file...');
   fileName = [path fname];
   vFile = fopen(fileName,'w','l');
	end
end
   
% Write size info
[rows,cols,planes] = size(imgCube);
fprintf(vFile,'rows %f\n', rows);
fprintf(vFile,'cols %f\n', cols);
fprintf(vFile,'planes %f\n', planes);
% It would be great to save the mm/pix info, too, but some
% other things need to be changed for this not to cause problems.
% Here is the alternative fprintf lines:
%fprintf(vFile,'rows 	%f (%f mm/pixel)\n', rows, mmPerPix(1));
%fprintf(vFile,'cols 	%f (%f mm/pixel)\n', cols, mmPerPix(2));
%fprintf(vFile,'planes 	%f (%f mm/pixel)\n', planes, mmPerPix(3));

% Write endOfHeader.
c = fprintf(vFile,'*\n');

% Swap rows and columns
tmp = zeros(cols,rows,planes);
for ii=1:planes
   tmp(:,:,ii) = imgCube(:,:,ii)';
end

% Write data
count = fwrite(vFile, tmp, 'uchar');
fclose(vFile);

return;
