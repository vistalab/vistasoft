function dtiInitStandAloneValidateJson(J)
% 
%  Validate the class of each json field according to the JSON schema. 
% 
% (C) Stanford University, VISTA Lab 2015
% 


%% Load the JSON schema from file

S = loadjson(which('dtiInitStandAloneJsonSchema.json'));


%% Validate the JSON struct against the schema

% Initialize typeError to false
typeError = false;

% Validate top-level elements
elements = fieldnames(J);
for e = 1:numel(elements)
   if ~isempty(J.(elements{e})) && ...
           ~strcmpi(class(J.(elements{e})), S.(elements{e}).type)
       warning('%s is of the wrong type (%s). Expected type: %s \n', ...
           elements{e},  class(J.(elements{e})), S.(elements{e}).type)
       typeError = true;
   end
end

% Validate params elements
if isfield(J, 'params')
    % Get the name of each param in the JSON structure
    paramelements = fieldnames(J.params);
    for pe = 1:numel(paramelements)
        if ~isempty(J.params.(paramelements{pe})) && ...
                ~strcmpi(class(J.params.(paramelements{pe})), S.(paramelements{pe}).type)
            warning('%s is of the wrong type (%s). Expected type: %s \n', ...
                paramelements{pe},  class(J.params.(paramelements{pe})), S.(paramelements{pe}).type)
            typeError = true;
        end
    end
end

% IF there was a type-mismatch then error
if typeError
    error('Validation failed. Please fix type errors');
end


return