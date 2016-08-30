function validationData = mrtGetValididationData(validationDataSet)
%Return remote validation data structure for code validation
%   validationData = mrtGetValididationData(validationDataSet)
% 
%   INPUT
%       validationDataSet: name of validation file to retrieve
%   OUTPUT
%       validationData: structure containing validation data
%
%   EXAMPLE
%       validationData = mrtGetValididationData('meanMapFromInplane');


% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% Change remote path to validate folder
rd.crp('/vistadata/validate/');

% Retrieve the data
validationData = rd.readArtifact(validationDataSet);

return