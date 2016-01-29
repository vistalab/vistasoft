function fName = sdmGet(pLink,fName)
% Retrieve a file from an sdm instance
%
%   fName = sdmGet(pLink,[fName])
%
% Inputs
%  pLink:  Permalink from the SDM
%  fName:  Location and/or filename to write the file
%
% Return
%  fName:  Path to file saved on disk
%
% Example:
%   fName = sdmGet('https://sni-sdm.stanford.edu/api/acquisitions/55adf6956c6e/file/9999.31469779911316754284_nifti.bval', ...
%                  'lmperry@stanford.edu', '/tmp/nifti.nii.gz')
%
% LMP/BW Vistasoft Team, 2015-16


%% Combine permalink and username to generate the download link

% Handle permalinks which may have '?user='
pLink = explode('?', pLink);
pLink = pLink{1};


%% Parse fName from the permalink if 'fName' was not provided.
if notDefined('fName') 
    [~, f, e] = fileparts(pLink);
    t_e = explode('?', e);
    out_dir = tempname;
    mkdir(out_dir);
    fName = fullfile(out_dir, [ f, t_e{1}]);
end


%% Get authorization token 
fprintf('Authenticating...')
[token, ~] = sdmAuth();
fprintf('done.\n');


%% Download the data

% Use curl - works on any version of matlab
curEnv = configure_curl();

curl_cmd = sprintf('/usr/bin/curl -v -X GET "%s" -H "Authorization":"%s" -o %s\n', pLink, token, fName);
[status, result] = system(curl_cmd);

unconfigure_curl(curEnv);

if status > 0
    fName = '';
    warning(result); % warn - perhaps error?
end


return


    function curENV = configure_curl()
        %% Configure library paths for curl command to work properly
        % MAC
        if ismac
            curENV = getenv('DYLD_LIBRARY_PATH');
            setenv('DYLD_LIBRARY_PATH','');
            
        % Linux
        elseif (isunix && ~ismac)
            curENV = getenv('LD_LIBRARY_PATH');
            setenv('LD_LIBRARY_PATH','/usr/lib:/usr/local/lib');
            
        % Other/Unknown
        else
            error('Unsupported system.\n');
        end
    return
        
    
    function unconfigure_curl(curENV)
        %% Reset library paths
        if ismac
            setenv('DYLD_LIBRARY_PATH',curENV);
        elseif (isunix && ~ismac)
            setenv('LD_LIBRARY_PATH',curENV);
        else
            error('Unsupported system.\n');
        end
    return
    
    
    
 
% %% Use websave to retrieve the data and store it
% 
% if exist(which('websave'),'file') % use websave (only available on newer matlab)
%     options = weboptions('KeyName', 'Authorization', 'KeyValue', token);
%     websave(fName, pLink, options)
% 
% end
    

