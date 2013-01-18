function emailMe(subject, emailTo, emailFrom, message, attachment)
%  emailMe([subject], emailTo, [emailFrom], [message], [attachment])
%
% email a message. it is useful to call this function immediatley after
% starting a long process in order to know when it is done. The message
% will show up as the subject title.
% 
% You can also send an attachment, which is useful if you're writing the
% outputs of your script to a log file - you can send that file to yourself
% for quick review. Multiple attachemnts can be sent if the file names are
% in a cell array. 
%
% Example:
% status=['Preprocessed this subject successfully'];
% attachment = 'path to some log file';
% emailMe(status,'jennifer.yoon@stanford.edu');
% 

% 7/2008 JW
% 11/2008 DY: modified default input arguments
% 3/2012 LMP: added the ability to send attachements

if notDefined('subject')
    subject = 'matlab has sent you an email!';
end

if notDefined('emailTo')
    error('You need to specify an @stanford.edu address to send the email to');
end

if notDefined('emailFrom')
    emailFrom = emailTo;
end

if notDefined('message')
    message = subject;
end

if notDefined('attachment')
    attachment = [];
end


setpref('Internet','SMTP_Server','smtp.stanford.edu');
setpref('Internet','E_mail',emailFrom);
sendmail(emailTo, subject, message, attachment);
