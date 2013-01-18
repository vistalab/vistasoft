function class = readClassFile(filename,headerOnlyFlag,voiOnlyFlag);
% 
%  class = readClassFile(filename,[headerOnlyFlag]);
% 
% AUTHOR:  Wandell
% DATE: 06.24.96
% PURPOSE: 
%   Read in the information in a classification file produced by
% mrGray.  The results are returned in a Matlab 5.0 structure.
% 
% MODIFICATIONS:
% 07.20.98 SJC	commented out figures
% 09.02.98 SJC	Added the optional input argument 'headerOnlyFlag'
%		which, if set to 1, makes the function only read
%		and return the header information instead of
%		reading in the entire class file.
% 04.13.99 SJC Added the optional input argument 'voiOnlyFlag'
%		which, if set to 1, crops the classification data to the
%		volume of interest only, and if set to 0 does not crop it.
% 06.18.99 SJC Changed the pause after the message window pops up to 'drawnow'
% 09.15.99 BW/WP
%               The VOI now returns in Matlab coordinates (1:N), 
%               rather than C coordinates (0:(n-1)).  This is now 
%               consistent with the update in readGrayGraph.
% 

if (nargin < 3)
   voiOnlyFlag = 1;
if (nargin < 2)
  headerOnlyFlag = 0;
end, end

msg = sprintf('Reading in the white classification file %s...',filename);
h = msgbox(msg,'readClassFile');
drawnow

% Save the filename used to read the data
% 
class.filename = filename;

% Set up values for different data types
% 
class.type.unknown = (0*16);
class.type.white   = (1*16);
class.type.gray    = (2*16);
class.type.csf     = (3*16);

% Open the file
% 
fp = fopen(class.filename,'r');

% Read header information
% 
class.header.version = fscanf(fp, 'version= %d\n',1);
class.header.minor = fscanf(fp, 'minor= %d\n',1);

class.header.voi(1) = fscanf(fp, 'voi_xmin=%d\n',1);
class.header.voi(2) = fscanf(fp, 'voi_xmax=%d\n',1);
class.header.voi(3) = fscanf(fp, 'voi_ymin=%d\n',1);
class.header.voi(4) = fscanf(fp, 'voi_ymax=%d\n',1);
class.header.voi(5) = fscanf(fp, 'voi_zmin=%d\n',1);
class.header.voi(6) = fscanf(fp, 'voi_zmax=%d\n',1);

%  This converts VOI from C to Matlab values.
% 
class.header.voi = class.header.voi + 1;

class.header.xsize = fscanf(fp, 'xsize=%d\n',1);
class.header.ysize = fscanf(fp, 'ysize=%d\n',1);
class.header.zsize = fscanf(fp, 'zsize=%d\n',1);

% Only read in the classification data if the headerOnlyFlag
% is set to zero.
%
if ~headerOnlyFlag
  csf_mean = fscanf(fp, 'csf_mean=%g\n',1);
  gray_mean = fscanf(fp, 'gray_mean=%g\n',1);
  white_mean = fscanf(fp, 'white_mean=%g\n',1);
  stdev = fscanf(fp, 'stdev=%g\n',1);
  confidence = fscanf(fp, 'confidence=%g\n',1);
  smoothness = fscanf(fp, 'smoothness=%d\n',1);
  class.header.params = ...
    [ csf_mean gray_mean white_mean stdev confidence smoothness];

  % Read the raw datas
  % 
  [im, cnt ] = fread(fp,'uchar');
  fclose(fp);

  % Reshape the volume
  % 
  class.data = ...
    reshape(im,[class.header.xsize,class.header.ysize,class.header.zsize]);

  % figure(1);
  % imagesc(class.data(:,:,34)),axis image

  % Extract the volume of interest if the voiOnlyFlag is set
  % 
  if voiOnlyFlag
     class.data = class.data( ...
        (class.header.voi(1):class.header.voi(2)), ...
        (class.header.voi(3):class.header.voi(4)), ...
        (class.header.voi(5):class.header.voi(6)));
  end
  
  % figure(2)
  % imagesc(class.data(:,:,34)); axis image

  % Provide the variable vSize for consistency with Matlab 5.0
  % notation.  In this case, the first variable is row (y) dimension.
  % 
  %class.header.vSize = [ ...
  %	class.header.ysize ...
  %	class.header.xsize ...
  %	class.header.zsize];
end

if exist('h'), close(h), end

return;

% 
% End of readClassFile

