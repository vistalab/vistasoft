function class = writeClassFile(class,filename);
% 
%  class = writeClassFile(class,filename);
%
% AUTHOR:  Wandell
% DATE:    10.17.97
% PURPOSE: 
%   Write out the information in a mrGray classification file.
%   The output file is in a format that can be read by mrGray.
% 
% ARGUMENTS:
% 
%    class:  The classification data structure.  (Built by readClassFile).
% filename:  The output filename
% 
% SEE ALSO
%   readClassFile
%

% DEBUG:
% Read in a class file, write it back out, and check thend read
% it back in again.
% 
% class = readClassFile('rightCalc.class');
% filename = 'test.class'
% writeClassFile(class,filename);
% tclass = readClassFile(filename);
% 
% Check class.header by hand.
% max(abs(tclass.data(:) - class.data(:)))
% class.header.params - tclass.header.params
% class.header.voi - tclass.header.voi
% class.header.vSize - tclass.header.vSize

% Open the file
% 
fprintf('Writing class file:  %s\n',filename);
fp = fopen(filename,'w');

% Convert Matlab 1-indexing to C 0-indexing
class.header.voi = class.header.voi-1;

% Write header information
% 
fprintf(fp, 'version= %d\n',class.header.version);
fprintf(fp, 'minor= %d\n',class.header.minor);

fprintf(fp, 'voi_xmin=%d\n',class.header.voi(1));
fprintf(fp, 'voi_xmax=%g\n',class.header.voi(2));
fprintf(fp, 'voi_ymin=%d\n',class.header.voi(3));
fprintf(fp, 'voi_ymax=%d\n',class.header.voi(4));
fprintf(fp, 'voi_zmin=%d\n',class.header.voi(5));
fprintf(fp, 'voi_zmax=%d\n',class.header.voi(6));

fprintf(fp, 'xsize=%d\n',class.header.xsize);
fprintf(fp, 'ysize=%d\n',class.header.ysize);
fprintf(fp, 'zsize=%d\n',class.header.zsize);

csf_mean   = class.header.params(1);
gray_mean  = class.header.params(2);
white_mean = class.header.params(3);
stdev      = class.header.params(4);
confidence = class.header.params(5);
smoothness = class.header.params(6);

% 
fprintf(fp, 'csf_mean=%g\n',csf_mean );
fprintf(fp, 'gray_mean=%g\n',gray_mean);
fprintf(fp, 'white_mean=%g\n',white_mean);
fprintf(fp, 'stdev=%g\n',stdev);
fprintf(fp, 'confidence=%g\n',confidence);
fprintf(fp, 'smoothness=%d\n',smoothness);

% Done writing the header

% Initialize the classification volume
im = class.type.unknown* ...
    ones(class.header.xsize, class.header.ysize,class.header.zsize);

% Take the data in the VOI and copy them into the 
% classification volume
rngX = (class.header.voi(1):class.header.voi(2))+1;
rngY = (class.header.voi(3):class.header.voi(4))+1;
rngZ = (class.header.voi(5):class.header.voi(6))+1;
im(rngX,rngY,rngZ) = class.data;

% Write the data into the file and return
% 
cnt = fwrite(fp,im,'uchar');
fclose(fp);

return;

% 
% End of writeClassFile

