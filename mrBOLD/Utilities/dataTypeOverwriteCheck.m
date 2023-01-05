function dtName = dataTypeOverwriteCheck(dtName)
% dtName = dataTypeOverwriteCheck(dtName)
% 
% Takes an input string and checks to see if a dataType already exists with that name.
%
% If it does, uses GUI to ask if user wishes to overwrite the existing dataType.
%         if so: function closes with a warning.
%         if not: prompts user to provide an alternate name for the new DT.
%
% remus 03/09

mrGlobals

if sum(strcmpi({dataTYPES.name},dtName)) %a datatype with that name already exists
    prompt= sprintf('Do you want to OVERWRITE dataType "%s?"',dtName);
    answer = questdlg(prompt);
    if strcmpi(answer,'cancel')
        error('Process cancelled by user');
    elseif strcmpi(answer,'no')
        dtName = char(inputdlg('Please enter name for new dataType:', 'Enter Data Type Name'));
        dataTypeOverwriteCheck(dtName);
    elseif strcmpi(answer,'yes')
        warning('Overwriting existing dataType')
    end
end

return