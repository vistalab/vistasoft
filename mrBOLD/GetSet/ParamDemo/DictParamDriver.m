function val = DictParamDriver(paramStruct, paramIn)


% USAGE: Gets an input parameter and returns the value in the struct it is
% associated with.
%
% INPUT: paramStruct, paramIn
% The struct that will be searched to find the specific value, as well as
% the parameter that relates to that struct location.
%
% OUTPUT: val
% The value stored at the location necessary within the parameter struct 

global DictParamTranslate

if (strcmp(paramIn,'help'))
    %We need to return the help file. Let's do that:
    params = keys(DictParamTranslate);
    for ii = 1:numel(params),
        %Print out all of the possible inputs with their help functions
        inputParam = params{ii};
        helpMsg = DictParamHelper(DictParamTranslator(params{ii}));
        fprintf('%s :\t\t%s \n',inputParam,helpMsg);
    end %for
    val = '';
    return;
end %if

%We can assume that help wasn't asked for, so let's return the value in the
%struct associated

paramKey = DictParamTranslator(paramIn);

if (isempty(paramKey))
    %We don't have a record of this. Return with warning
    val = '';
    warning('Dict:ParamDriverWarning', 'The input of %s does not appear to be in the dictionary', paramIn);
    return;
end %if

location = DictParamLocator(paramKey);

val = paramStruct.(location); %Use dynamic struct navigation to get the correct location

return