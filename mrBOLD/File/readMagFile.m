function [tMat, hdr] = readMagFile(magFile, slice, useLittleEndian, verbose)
% Read a P*.mag file into a 4D tSeries matrix
%
% [tMat, hdr] = readMagFile(magFile,[slice],[useLittleEndian], [verbose=0]);
%
% This routine does not make any of the built-in assumptions of mrInitRet.
% Requires that a corresponding E-file header be present. If the second
% argument, slice, is entered, only returns the tSeries for that slice;
% otherwise, returns the entire 4D array in the format: rows, cols, slices,
% frames. Also, if slice is entered as 0, returns an empty tMat matrix,
% plus the header.
%
% Returns the matrix as a uint16 to save memory. Note:
% to do arithmetic on this, you'll need to convert back
% to a double, which may hog more memory again. (Though
% I heard matlab 7 is better about this...)
%
% useLittleEndian: this is a flag; if 1 [default], it will
% read the mag file as a little endian file (all scans at
% Lucas Center after Mar 1, 2005 do this). Otherwise, reads
% as Big-Endian (most mag files created before that date
% use big endian).
%
% You can also enter a directory path as 'magFile', without
% actually specifying which mag file to read, to get the
% most recently-created mag file in that dir (assuming there
% are any).
%
% 03/05 ras.
% 08/07 ras: streamlined; added verbose flag to turn off the mrvWaitbar.
if notDefined('slice'),					slice = [];					end
if notDefined('useLittleEndian'),		useLittleEndian = 1;		end
if notDefined('verbose'),				verbose = 0;				end

% check whether a directory is specified,
% in which case, find newest mag file there:
if exist(magFile,'dir')
    magFile = newestMagFile(magFile);
    if isempty(magFile)
        % didn't find any, can't get any
        % data
        tMat = []; hdr = [];
        return
    else
        % got one, tell user which file it is
        fprintf('Most recent P-mag file: %s\n',magFile);
    end
end    

% check that the mag file exists
if ~exist(magFile,'file')
    error('%s does not exist!',magFile);
end

% get the # from the mag file name
[par fname ext] = fileparts(magFile);
num = str2double(fname(2:6));
if ~isnumeric(num)
    error('Something wrong with file name -- number must be present.')
end

% check for a corresponding E file
if isempty(par)
    % no parent dir specified, is relative to wd
    par = pwd;
end
pattern = fullfile(par,sprintf('E*P%05d.7*',num));
efiles = dir(pattern);
if isempty(efiles)
    error('No corresponding E-file header found.')
else
    eFile = fullfile(par,efiles(1).name);
end
hdr = ReadEfileHeader(eFile);

% figure out # of slices in the output matrix
if isempty(slice)
    slices = 1:hdr.slquant;
else
    slices = slice;
end

% if slice==0, we just want the header info and can omit the
% rest:
if slice==0
    tMat = 0;
    return
end

% set up params for getting tSeries
nSlices = length(slices);
nFrames = hdr.nframes;
xsz = hdr.imgsize;
ysz = hdr.imgsize;
if useLittleEndian==1
    endianFlag = 'ieee-le';
else
    endianFlag = 'ieee-be';
end

% get ready to read the mag file
fid = fopen(magFile,'r',endianFlag);

% loop through slices, reading tSeries from mag file
if verbose
	msg = sprintf('Reading Mag File %s.%s...',fname,ext);
	h = mrvWaitbar(0,msg);
end

for i = 1:nSlices
    curSlice = slices(i);
    offset = (curSlice-1)*xsz*ysz*nFrames*2;
    fseek(fid,offset,0);
    for f = 1:nFrames
        img = fread(fid, [ysz xsz], 'int16')';
        tMat(:,:,i,f) = img;
    end
    frewind(fid);
    
    if verbose, mrvWaitbar(i/nSlices,h); end
end

if verbose
	close(h);
end

fclose(fid);


return
