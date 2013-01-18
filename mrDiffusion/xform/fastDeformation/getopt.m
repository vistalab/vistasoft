function [erg,arg] = getopt(str,default,varargin)
%JM-16-mar-00
% [erg,arg] = getoption('dummy',default,'a',a,...,'dummy',dummyval,...,'z',z)
% erg = dummyval,
% arg = getoption('dummy','a',a,...,'z',z)
%
% (c) 2000 - Jan Modersitzki

  j   = max(find(strcmp(varargin,str)));
  if isempty(j),
    erg = default;
    arg = varargin;
  else
    erg = varargin{j+1};
    if j == length(varargin),
      arg = {varargin{1:j-1}};
    else
      arg = {varargin{1:j-1},varargin{j+2:end}};
    end;
  end;

  
  
  if ~strcmp(str,'getoptout'),
    out = getopt('getoptout',0,arg{:});
    if out, showopt(str,erg); end;
  end;
  
function showopt(str,erg)

  fprintf('%-20s ',str);
    
  if isnumeric(erg),

    if size(erg) == [1,1],
      if round(erg)==erg,
	fprintf('%d\n',erg);
      else
	fprintf('%12.6e\n',erg);
      end;
      
    else
      fprintf('is %dx%d\n',size(erg));
    end;
  
  elseif isstr(erg),

    fprintf('%s\n',erg);
    
  end;
  
return;
%----------------------------------------------------------------------
