function string = motionCompPrintTab(tab)
%
%    gb 05/07/05
%
%    string = motionCompPrintTab(tab)
%
% Creates a string of the values of a matrix. It is generally used to print
% out the values of the output matrix of the function motionCompMeanMSE (or
% motionCompMeanMI)
%
% Type sprintf(motionCompPrintTab(tab)) to have a nice diplay of the
% values. This can be stored into a text file.
%

string = '';
n1 = size(tab,1);
n2 = size(tab,2);

for i = 1:n1
    for j = 1:n2
        value = num2str(tab(i,j));
        string = [string value];
        for k = 10:-1:length(value)
            string = [string ' '];
        end
    end
    string = [string '\n\n'];
end
        