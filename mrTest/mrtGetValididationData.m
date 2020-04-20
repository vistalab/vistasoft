function validationData = mrtGetValididationData(validationDataSet)
%Return remote validation data structure for code validation
%
% Syntax
%   validationData = mrtGetValididationData(validationDataSet)
%
% Description
%   Called by various test_* routines when they need a specific file.
%
% INPUT
%     validationDataSet: name of validation file to retrieve.
%     Potential values are:
%
% OUTPUT
%     validationData: structure containing validation data
%
% EXAMPLE
%       validationData = mrtGetValididationData('meanMapFromInplane');
%
% See also:
%    mrtInstallSampleData
%

% Find the validataion file
pth = fullfile(vistaRootPath, 'local', 'testData', 'validate'); 
d = dir (fullfile(pth, sprintf('%s*', validationDataSet)));

validationData = load(fullfile(d.folder, d.name));

end