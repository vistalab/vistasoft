function view = writeTSeriesInAnalyzeForm(view,scanList,saveDir);
%
% view = writeTSeriesInAnalyzeForm(view,[scanList],[saveDir])
% 
% Could be for either INPLANE or VOLUME
% Transform the time series into analyze format images.
% By definition, each analyze image corresponds to one time
% frame and is a 3D matrix.
% Unfortunately the orientation is kind of random now.
% Maybe I can fix it someday...
%
% scanList: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
% saveDir: if not given, save to 'Inplane/Original_Ana/Scan*/TS*.img'
% 
% SPM Matlab toolbox required.
% JL, 09/18/2004.

mrGlobals;

% (Re-)set scanList
if ~exist('scanList','var')
    scanList = selectScans(view);
elseif scanList == 0
    nScans = numScans(view);
    scanList = 1:nScans;
end

if isempty(scanList);error('Xform aborted');end

if exist('saveDir','var') && ~exist(saveDir,'dir');
    error('saveDir does not exist for writeTseriesInAnalyzeForm');
else
    saveDir = fullfile(dataDir(view),'TSeries_imgFiles');
    if ~exist(saveDir,'dir'); mkdir(dataDir(view),'TSeries_imgFiles'); end;
end

disp(['Hint: Analyze Files saved to ',saveDir]);

mmPerVox = mrSESSION.functionals(viewGet(view,'curScan')).voxelSize;

for scanIndex=1:length(scanList);
    scanNum = scanList(scanIndex);
    disp(['Xforming to Analyze Files: scan', int2str(scanNum),'...']);
    saveCurDir = fullfile(saveDir,['Scan',int2str(scanNum)]);
    if ~exist(saveCurDir); mkdir(saveDir,['Scan',int2str(scanNum)]); end;
    writeData = getTSeriesInAnalyzeForm(view,scanNum);
    [nFrames,x,y,nSlices]=size(writeData);
    img_dim=[x,y,nSlices]; % THis is each volume size : x*y*nSlices . The '4' refers to the spm data type 'uint16' : see spm_type
    for curFrame = 0:nFrames-1;
        newimg=squeeze(writeData(curFrame+1,:,:,:));
        fileNum = [int2str(fix(curFrame/100)) int2str(fix(fix(curFrame-100*fix(curFrame/100))/10)) int2str(mod(curFrame,10))];
        s = spm_hwrite(fullfile(saveCurDir,[fileNum,'.hdr']),img_dim,mmPerVox,1,4,0);
        if s~=348; error('Error writing hdr files'); end;
        V = spm_vol(fullfile(saveCurDir,[fileNum,'.img']));
        V.descrip=['Converted from tSeries file in session ',mrSESSION.sessionCode,' : ',dataTYPES(viewGet(view,'curDataType')).name,':  Scan ',int2str(viewGet(view,'curScan'))];
        s = spm_write_vol(V,newimg);
    end
end

return

%------------------------------------------------------------------- 

function [s] = spm_hwrite(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP)
% writes a header
% FORMAT [s] = spm_hwrite(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP);
%
% P       - filename 	     (e.g 'spm' or 'spm.img')
% DIM     - image size       [i j k [l]] (voxels)
% VOX     - voxel size       [x y z [t]] (mm [sec])
% SCALE   - scale factor
% TYPE    - datatype (integer - see spm_type)
% OFFSET  - offset (bytes)
% ORIGIN  - [i j k] of origin  (default = [0 0 0])
% DESCRIP - description string (default = 'spm compatible')
%
% s       - number of elements successfully written (should be 348)
%___________________________________________________________________________
%
% spm_hwrite writes variables from working memory into a SPM/ANALYZE
% compatible header file.  The 'originator' field of the ANALYZE format has
% been changed to ORIGIN in the SPM version of the header. funused1
% of the ANALYZE format is used for SCALE
%
% see also dbh.h (ANALYZE) spm_hread.m and spm_type.m
%
%__________________________________________________________________________
% @(#)spm_hwrite.m	2.3 00/02/22


% ensure correct suffix {.hdr} and open header file
%---------------------------------------------------------------------------
P               = deblank(P);
q    		= length(P);
if q>=4 & P(q - 3) == '.', P = P(1:(q - 4)); end;
P     		= [P '.hdr'];

% For byte swapped data-types, also swap the bytes around in the headers.
mach = 'native';
if spm_type(TYPE,'swapped'),
	if spm_platform('bigend'),
		mach = 'ieee-le';
	else,
		mach = 'ieee-be';
	end;
	TYPE = spm_type(spm_type(TYPE));
end;
fid             = fopen(P,'w',mach);

if (fid == -1),
	error(['Error opening ' P '. Check that you have write permission.']);
end;
%---------------------------------------------------------------------------
data_type 	= ['dsr      ' 0];

P     		= [P '                  '];
db_name		= [P(1:17) 0];

% set header variables
%---------------------------------------------------------------------------
DIM		= DIM(:)'; if size(DIM,2) < 4; DIM = [DIM 1]; end
VOX		= VOX(:)'; if size(VOX,2) < 4; VOX = [VOX 0]; end
dim		= [4 DIM(1:4) 0 0 0];	
pixdim		= [0 VOX(1:4) 0 0 0];
vox_offset      = OFFSET;
funused1	= SCALE;
glmax		= 1;
glmin		= 0;
bitpix 		= 0;
descrip         = zeros(1,80);
aux_file        = ['none                   ' 0];
origin          = [0 0 0 0 0];

%---------------------------------------------------------------------------
if TYPE == 1;   bitpix = 1;  glmax = 1;        glmin = 0;	end
if TYPE == 2;   bitpix = 8;  glmax = 255;      glmin = 0;	end
if TYPE == 4;   bitpix = 16; glmax = 32767;    glmin = 0;  	end
if TYPE == 8;   bitpix = 32; glmax = (2^31-1); glmin = 0;	end
if TYPE == 16;  bitpix = 32; glmax = 1;        glmin = 0;	end
if TYPE == 64;  bitpix = 64; glmax = 1;        glmin = 0;	end

%---------------------------------------------------------------------------
if nargin >= 7; origin = [ORIGIN(:)' 0 0];  end
if nargin <  8; DESCRIP = 'spm compatible'; end

d          	= 1:min([length(DESCRIP) 79]);
descrip(d) 	= DESCRIP(d);

fseek(fid,0,'bof');

% write (struct) header_key
%---------------------------------------------------------------------------
fwrite(fid,348,		'int32');
fwrite(fid,data_type,	'char' );
fwrite(fid,db_name,	'char' );
fwrite(fid,0,		'int32');
fwrite(fid,0,		'int16');
fwrite(fid,'r',		'char' );
fwrite(fid,'0',		'char' );

% write (struct) image_dimension
%---------------------------------------------------------------------------
fseek(fid,40,'bof');

fwrite(fid,dim,		'int16');
fwrite(fid,'mm',	'char' );
fwrite(fid,0,		'char' );
fwrite(fid,0,		'char' );

fwrite(fid,zeros(1,8),	'char' );
fwrite(fid,0,		'int16');
fwrite(fid,TYPE,	'int16');
fwrite(fid,bitpix,	'int16');
fwrite(fid,0,		'int16');
fwrite(fid,pixdim,	'float');
fwrite(fid,vox_offset,	'float');
fwrite(fid,funused1,	'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'int32');
fwrite(fid,0,		'int32');
fwrite(fid,glmax,	'int32');
fwrite(fid,glmin,	'int32');

% write (struct) image_dimension
%---------------------------------------------------------------------------
fwrite(fid,descrip,	'char');
fwrite(fid,aux_file,    'char');
fwrite(fid,0,           'char');
fwrite(fid,origin,      'int16');
if fwrite(fid,zeros(1,85), 'char')~=85
	fclose(fid);
	spm_unlink(P);
	error(['Error writing ' P '. Check your disk space.']);
end

s   = ftell(fid);
fclose(fid);

return


