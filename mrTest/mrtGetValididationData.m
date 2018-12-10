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

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% Change remote path to validate folder
rd.crp('/vistadata/validate/');

% Retrieve the data
validationData = rd.readArtifact(validationDataSet);

end