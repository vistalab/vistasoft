function [subject] = mrGetSubject(voldr)
%function [subject] = mrGetSubject(voldr)
%
% PURPOSE: Get the name of a subject on whom we have volume data.
% 07.19.97 - Created by Poirson
% 10.27.98 - Rewritten by Press to get rid of unix calls

subject = 'NotAPerson';

while ~exist([voldr '/' subject],'dir')
  
  disp('Current list of subject:');
  dir(voldr);
  subject = input('Subject name: ','s');
  disp('');

end
