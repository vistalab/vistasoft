function val = rdata(func,remote,varargin)
% Execute a function on data at host h in directory d
%
% MIGHT WANT TO MOVE remote LATER SO WE DON"T HAVE TO USE IT SO MUCH
% THOUGH IT READS OK AS FUNCTION, REMOTE, (FILE OR FILE PATTERN)
%
%   val = rdata(function, remote, varargin)
%
% Perform simple operations on data in a remote file system
%
% Examples:
%
%  This is the base directory for these examples
%   remote.host = 'http://scarlet.stanford.edu/validation/MRI/VISTADATA';
%
%  File list
%   remote.directory = fullfile('diffusion','sampleData','fibers');
%   rdata('cd',remote);
%   dirList = rdata('ls',remote,'pdb');                   % Match .pdb extension
%
%  File get
%   oname = rdata('get',remote,dirList{2});
%   copyfile(oname,'fibers.pdb');
%
%  Read an image
%   remote.host = 'http://scarlet.stanford.edu/validation/SCIEN/';
%   remote.directory = fullfile('L3','nikond200','JPG');
%   img = rdata('read image',remote,'DSC_0767.JPG');
%   imshow(img);
%
%  Load a .mat file
%   remote.directory = fullfile('L3','people_small');
%   scene = rdata('load data',remote,'people_small_1_scene.mat','scene');
%   vcAddObject(scene); sceneWindow;
%
%  Set the remote directory and use it
%    rdata('cd',remote);
%    dirList = rdata('ls',[],'pdb');
%
% BW ISETBIO Team, Copyright 2015

if notDefined('func'), func = 'ls'; end
if notDefined('remote')
    if ispref('ISET','remote'), remote = getpref('ISET','remote');
    else
        remote.host = 'http://scarlet.stanford.edu';
        remote.directory = fullfile('validation','MRI');
    end
end
webdir = fullfile(remote.host,remote.directory);

f = mrvParamFormat(func);
switch f
    
    case 'ls'
        % dirList = rdata('ls',remote, extension);
        if ~isempty(varargin), pattern = varargin{1};
        else pattern = '.mat';
        end
        
        % Read and parse html string
        % Some day we might pass this as an argument
        p    = '<a[^>]*href="(?<link>[^"]*)">(?<name>[^<]*)</a>';
        
        % str  = webread(webdir);
        str  = urlread(webdir);
        name = regexp(str, p, 'names');

        %% Filter by user input pattern
        if ~isempty(pattern)
            indx = arrayfun(@(x) ~isempty(strfind(x.name, pattern)), name);
            nfiles = sum(indx);
            if nfiles == 0
                warning('No files match pattern: %s',pattern);
                fnames = [];
            else
                % Copy the matching patterns
                fnames = cell(nfiles,1);
                cnt = 1;
                for ii=find(indx)
                    fnames{cnt} = name(ii).name;
                    cnt = cnt+1;
                end
            end
        end
        val = fnames;
        
    case 'cd'
        % rdata('cd',remote)
        setpref('ISET','remote',remote);
        val = remote;
        
    case 'get'
        % outName = rdata('get',remote,fname);
        rname = fullfile(webdir,varargin{1});
        oname = tempname;
        [val,status] = urlwrite(rname,oname);
        if ~status,  error('File get error.\n'); end
        
    case 'put'
        % NYI
        error('Put not yet implemented');
        
    case 'readimage'
        % rdata('read image', remote, fname);
        if isempty(varargin), error('remote file name required'); end
        
        rname = fullfile(webdir,varargin{1});
        val = imread(rname);
        
    case 'loaddata'
        % rdata('load data',remote,fname,variable)
        if isempty(varargin), error('remote data file name required'); end
        
        rname = fullfile(webdir,varargin{1});
        oname = tempname; oname = [oname,'.mat'];
        [oname, status] = urlwrite(rname,oname);
        if ~status,  error('Load data error.\n'); end
        
        val = load(oname);
        if length(varargin) == 2
            eval(['val = val.',varargin{2},';']);
        end

    otherwise
        error('Unknown function %s\n',func);
end

end
