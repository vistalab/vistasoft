function fg = dtiImportFibersMrtrix(filename, fiberPointStride)
%
% fg = dtiImportFibersMrtrix(filename, [fiberPointStride=max(1,floor(1/stepSize))])
% 
% Input arguments:
%
%   filename: the filename of fiber tract file output from mrtrix.
%
%   fiberPointStride: if <=1, then all fiber points will be returned. If 2,
%   every 2nd point will be returned, etc. The default will try to get you
%   close to a 1mm step size.
%                     
%
% Returns: a mrDiffusion fiber group structure.
%
% Example;
%
% fg = dtiImportFibersMrtrix('all_1000K.tck');
% mtrExportFibers(fg, 'all_1000K.pdb', eye(4));
%
% Bob & Franco (c) Vista Soft, Stanford University, 2013

% Strip out the file name.
[~,f] = fileparts(filename);

% Build an empty mrDiffusion fier group.
fg = dtiNewFiberGroup(f);

% Read a binary fiber tracking file (.tck) output from mrTrix. 
fid = fopen(filename ,'r','ieee-le'); % Note that we assume that the data 
                                      % always little-endian. 
if(fid==-1), error('Unable to access file %s\n', filename);end

% Read the .tck file just opened.
try
    % Read the text header, line-by-line, until the 'END' keyword. We'll
    % store all header fields in a cell array and then pull out the ones
    % that we need below.
    ln = fgetl(fid);
    ii = 1;
    while(~strcmp(ln,'END'))
        header{ii} = ln;
        ln = fgetl(fid);
        ii = ii+1;
    end
   
    % Get the datatype from the header cell array.
    dt = header{strmatch('datatype:',header)};
    if(isempty(findstr(dt,'Float32LE')))
        % *** FIXME: we should close the file and reopen in big-endian.
        error('Only Float32LE data supported!');
    end
    % Get the number of tracts from the header cell array. There seem to
    % be two possible keywords for this field.
    numIndx = strmatch('num_tracks:',header);
    if(isempty(numIndx))
        numIndx = strmatch('count:',header); 
        n = str2double(header{numIndx}(7:end));
    else
        n = str2double(header{numIndx}(12:end));
    end
    fprintf(1,'Reading Fiber Data for %d fibers...\n',n);
    offset = str2double(header{strmatch('file:',header)}(8:end));
    
    % Get the stepsize (in mm) from the header cell array.
    stepSize = str2double(header{strmatch('step_size:',header)}(11:end));
    
    % Tuck the whole header into an fg.params field.
    fg.params = {'mrtrix_header',header};
    
    % Now load all the fibers (float32 format):
    fseek(fid,offset,-1);
    tmp = fread(fid,inf,'*float32')';
    fclose(fid);
catch
    error('Unable to parse header for file %s\n', filename);
end

% Reshape the fibers to the mrDiffusion format
tmp = tmp(1:end-6);
tmp = reshape(tmp,3,numel(tmp)/3);

% Fibers are separated by a column of NaNs
fb = [0 find(isnan(tmp(1,:))) size(tmp,2)+1];
nFibers = numel(fb)-1;

if(~exist('fiberPointStride','var') || isempty(fiberPointStride))
    fiberPointStride = max(1,floor(1/stepSize));
end
if(fiberPointStride<1)
    fiberPointStride = 1;
end

for(ii=1:nFibers)
    fg.fibers{ii,1} = tmp(:, fb(ii)+1:fiberPointStride:fb(ii+1)-1);
end
fg.fibers=cellfun(@double, fg.fibers, 'UniformOutput', false);

return

