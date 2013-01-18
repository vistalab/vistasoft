function out = dlmreadMixedDataType(f_name, readList)
%
% [varargout] = dlmreadMixedDataType(f_name, readList)
%
% Extracts data columnwise from a file and tries to .
% Column separators might be any whitespace char.
%
% Input:
% f_name:  
% readList: a string in which the number and type of each
%           column to read is specified values separated by spaces:
%           s1 for a string from the first column
%           n2 for a numeric value from the second column
% Output:   out is a cell array of same size as the number of
%           columns to read. the columns are in the same order
%           as specified in readList.
%
% EXAMPLE: [dum1,dum2] = dm('cap33.all',['s2 n1']);
%          reads from file 'cap33.all' the first two columns
%          and interprets the first as a string and the
%          second as a number. The order is reversed
%
% HISTORY
%   2001.12.01 RFD (bob@white.stanford.edu) wrote it, based on code from
%   Jochem Rieger.


%parse the string 
%first strip whitespaces
readList = readList(find(~isspace(readList)));
cols=str2num(strvcat([readList(2:2:end)]'));
types = [readList(1:2:end-1)];
nCols = length(cols);

fh_in=fopen(f_name,'r');
n_lines = 0;
out=cell(nCols,1);
while (feof(fh_in)==0),
  %we want the readline starting and ending with a separator
  linBuf =[' ' fgetl(fh_in) ' '];
  if length(linBuf) > 2
  %parse the line reduce multiple separators to one
  sepIdx=find(isspace(linBuf));
  multSep=sepIdx(find(([sepIdx(2:end)-sepIdx(1:end-1)]==1)));
  linBuf(multSep)=[];
  %get the udated list of separators
  sepIdx=find(isspace(linBuf))+1;
  %append the
  for k=1:nCols
    switch  types(k)
     case 'n'
      out{k}=[out{k} str2double(linBuf(sepIdx(cols(k)):sepIdx(cols(k)+1)-2))];
     case 's'
      out{k}=strvcat(out{k},linBuf(sepIdx(cols(k)):sepIdx(cols(k)+1)-2));
     otherwise
      error('Unknown datatype')
    end %switch
  end %for
end %if
end %while
fclose(fh_in);