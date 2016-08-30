function test_nifti(function_type)
% Test that reading and writing nifti files works properly.
% Tests: niftiWritematlab.m and niftiReadmatlab.m
% An error is thrown if any of the tests fail. 
%
%  test_nifti()
%
% INPUTS: 
%   function_type - selectes the type of reader/writer to test:
%                   either  {'mex','reandfilenifti','writefilenifti'} 
%                   or      {'mat','m','matlab','niftiwritematlab', ...
%                            'niftireadmatlab'}
%
% RETURNS: No returns, results are displayed on matlab output.
%
% Example: 
%   test_nifti()
%   test_nifti('mex')
%
% See also MRVTEST
%
% (c) Stanford Vista Team, 2012

test_vals          = [NaN, -10^3];
original_file_name{1} = fullfile(vistaRootPath, 'mrDiffusion','templates', 'MNI_EPI.nii.gz');

if notDefined('function_type'), function_type = 'm';end
switch function_type
  case {'mex','reandfilenifti','writefilenifti'}
    niftiFun{1} = 'readFileNifti';
    niftiFun{2} = 'writeFileNifti';
    
  case {'mat','m','matlab','niftiwritematlab','niftireadmatlab'}
    niftiFun{1} = 'niftiReadMatlab';
    niftiFun{2} = 'niftiWriteMatlab';
    
  otherwise
    keyboard
end

fprintf('[%s] Testing using Read/Write with %s and %s\n\n',mfilename, niftiFun{1},niftiFun{2})


%% Test that we can write a read file with out compromising it.
for iFile = 1:length(original_file_name)
  temp_file_name = fullfile(tempdir, 'test.nii.gz');
  
  % Test Reading a file from disk, saving it back using the mrVista matlab version of
  % the code.
  % Read a file
  niiOrig = eval(sprintf('%s(''%s'')',niftiFun{1},original_file_name{iFile}));
  
  % Write the file back to disk in a temporary file.
  niiOrig.fname = temp_file_name;
  eval(sprintf('%s(niiOrig)',niftiFun{2}));
  
  % Read the file we just wrote.
  %  niiNew = niftiReadMatlab(temp_file_name);
  niiNew = eval(sprintf('%s(''%s'')',niftiFun{1},temp_file_name));

  % Change the filenames before asserting equivalence.
  niiOrig.fname = '';
  niiNew.fname  = '';
  assertEqual(niiNew,niiOrig)
  fprintf('[%s] Tested Read/Write on %s\n',mfilename, original_file_name{iFile})
  
  %% Test a read and a write file with specific values inside the data field.
  % This requires setting the datatype field inside ni.hdr.
  for iValue =1:length(test_vals)
        % Load data from file
        niiOrig = eval(sprintf('%s(''%s'')',niftiFun{1},original_file_name{iFile}));
        tmp_data_type = niiOrig.nifti_type;
        
        % Cast into double format:
        niiOrig.data = double(niiOrig.data);
        
        % Change the nifti code for th format:
        niiOrig.nifti_type = niftiClass2DataType(class(niiOrig.data));
        
        % Choose the current value to test on:
        test_val            = test_vals(iValue);
        niiOrig.data(1,1,1) = test_val;
        
        % Write back the file to disk:
        niiOrig.fname = temp_file_name;
        eval(sprintf('%s(niiOrig)',niftiFun{2}));

        % Load it back:
        niiNew = eval(sprintf('%s(''%s'')',niftiFun{1},temp_file_name)); 
        fprintf('Val #%i, original nifti data type: %i, saved/loaded: %i\n\n',iValue,tmp_data_type,niiNew.nifti_type)
        % Assert that it retained its value:
        if isnan(test_val)
          assertTrue(isnan(niiNew.data(1,1,1)),'NaN value, was NOT correctly loaded and written in nifti file.');
        else
          assertEqual(niiNew.data(1,1,1), test_val)
        end
   
      fprintf('[%s] Tested writing VALUE %i in file %s\n\n',mfilename, iValue, original_file_name{iFile})
  end
end
