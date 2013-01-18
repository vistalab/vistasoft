function [varargout] = openDbConnection(view);
% [View,OK] = openDbConnection(view);
% OK = openDbConnection(view);
% openDbConnection(view);
%
% First overload is used for login, others - for  simple connection.
% 
% In login mode: Check for session  existence. If  not exist - ask operator for his 
% username, password etc. Then connect. If name doesn't exist - ask for  it  again and create 
% a  new record  in the database.
% In simple mode: Just try to connect. If it fails - bring an error message.

defautValues = {'snarp.stanford.edu','vista','',''};

if(nargout<2) % SIMPLE MODE
  if(isfield(view,'mysqlsession')) % We are logged in already
    mysql('open',view.mysqlsession.hostname,view.mysqlsession.username,...
      view.mysqlsession.password);
    mysql('use','mrDataDB');
    varargout{1} = 1; % OK button
    return;
  else % Error Message
    myWarnDlg('You''re not logged in yet. Please, go to File/Login to database and log in.');
    varargout{1} = 0; % Cancel button
    return;
  end
else % ADVANCED MODE
  varargout{2} = 1; % OK button
  if(isfield(view, 'mysqlsession')) %  Connection was  already open
    Answer = questdlg('You have selected your database,username and password already. Do you wish to continue?',...
      'Alert','Cancel','OK','Cancel');
    if(strcomp(Answer,'Cancel'))
       varargout{1} = view;
       varargout{2} = 0;
       return;
    end
  end

  prompt={'Hostname:','Login:','Password:','Username (how are you listed in a database'};
  answer=inputdlg(prompt,'Connecting to database...',1,defautValues);
  
  if ~isempty(answer)
    mysqlsession = struct('hostname',answer{1},'username',answer{2},...
      'password',answer{3},'userId',0); 
    view = setfield(view,'mysqlsession',mysqlsession);
    Flag = mysql('open',mysqlsession.hostname,mysqlsession.username,...
      mysqlsession.password);
    if(~exist('Flag')) % An error occured when opening a connection
      varargout{1} = view;
      varargout{2} = 0;
      return;
    end
    mysql('use','mrDataDB');
    view.mysqlsession.userId = checkForUser(answer{4}); % Transform nick name to an Id (see below)
    view.mysqlsession.userId
    varargout{1} = view;
    return;
  else % Cancel button
    varargout{1} = view;
    varargout{2} = 0;
    return;
  end
end


%%-------------------------------
function userId = checkForUser(userNick);
userId = mysql(['SELECT id FROM users WHERE username="',userNick,'"']);
if(max(size(userId))>1) % More than one user found
  userId = userId(1);
  myWarnDlg('More than one user with this username found. Using  the first one.');
  return;
elseif(min(size(userId))==0) % No such user in a database
  Answer = questdlg('There''re no users with this username in the database. Do you want to create a new record?',...
      'New record','Cancel','OK','Cancel');
  if(strcomp(Answer,'Cancel'))
    userId = 0;
    myWarnDlg('You''re listed as a GUEST user');
  else
    ResultFlag = 0;
    while(ResultFlag==0)
      answer=inputdlg({'First name:','Last name:','Organization:','E-mail:','Username:'}...
        ,'Create a new user',1,{'','','','',userNick});
      if(isempty(answer)) % Cancel button
        userId = 0;
        myWarnDlg('You''re listed as a GUEST user');
        return;
      end
      listedEmail = mysql(['SELECT id FROM users WHERE email="',answer{4},'"']);
      listedNick = mysql(['SELECT id FROM users WHERE username="',answer{5},'"']);
      if(~isempty(listedEmail))
        myWarnDlg('This e-mail is already in the database. Try again.');
      elseif(~isempty(listedNick))
        myWarnDlg('This username is already in the database. Try again.');
      else
        ResultFlag=1;
      end;
    end
    mysql(['INSERT INTO users (firstName,lastName,organization,email,username,notes) VALUES("',...
      answer{1},'","',answer{2},'","',answer{3},'","',answer{4},'","',answer{5},...
      '","mrLoadRet creation")']);
    disp(['New user ',answer{5},' might be created.']);
  end
  return;
else % Normal situation - one user found
  return;
end