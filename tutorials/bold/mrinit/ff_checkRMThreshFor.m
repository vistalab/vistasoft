% very specific function. 
% sees whether the RM_th structure contains a field for a specific subject.
% returns yes if subject exists, no if not
% INPUT:
% 1. initials of subjects
% 2. RM_th structure

function subjectExists = ff_checkRMThreshFor(initialsOfSubjectsToCheck, RM_th)

subjectExists = 0;

for ii = 1:length(RM_th)
    
    if strcmp(RM_th{ii}.subject, initialsOfSubjectsToCheck)
        subjectExists = 1; 
    end
    
end

end