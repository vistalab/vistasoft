function CancelEdit(topH)

% CancelEdit(topH)
%
% Sets the cancel flag in the user data.
%
% DBR 4/99

uiData = get(topH, 'UserData');
uiData.cancel = 1;
set(topH, 'UserData', uiData);
uiresume;
