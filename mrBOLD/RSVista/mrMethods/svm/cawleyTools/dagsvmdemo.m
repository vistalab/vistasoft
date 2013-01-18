% DAGSVMDEMO
%
% Demonstrate the use of the Support Vector Machine toolbox to distinguish
% examples of Versicolour, Setosa and Virginica varieties of Iris, given
% petal and sepal width and length attributes.  The data is taken from the
% well known Iris benchmark [1], available from the UCI Repository of Machine
% Learning % Databases (http://www.ics.uci.edu/~mlearn/MLRepository.html).
%
% [1] R. A. Fisher,
%     "The use of multiple measurements in taxonomic problems",
%     Annual Eugenics, 7(2), pp 179-188, 1936.

%
% File        : dagsvmdemo.m
%
% Date        : Friday 24th November 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Test harness for object oriented implementation of Vapnik's
%               linear support vector machine (SVM) [1].  This file tests the
%               dag-svm algorithm for multi-class pattern recognition.
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 14/11/1999 - v1.00 
%
% Copyright   : (c) Dr Gavin C. Cawley, November 2000.
%
%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 2 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
%

% start from a clean slate

clear classes all;

% load some data

fprintf(1,'loading training data...\n');

iris = load('data/iris.txt');

% the data matrix contains n columns where n is the number of input variable
% each row represents a pattern and each column a variable. 
 
x = iris(:,1:4);

% the target matrix contains k columns where k is the number of classes
% each row represents a pattern and each column a class. -1 means false
% +1 means true.

k = 3;
y = [2*(iris(:,5) == 1)-1, 2*(iris(:,5) == 2)-1, 2*(iris(:,5) == 3)-1];

% create tutor

kernel = rbf(0.5);
C      = 100.0;
tutor  = smosvctutor;   % this means we use the SMO training algorithm
net    = dagsvm;        % this means we use the DAG-SVM algortihm to combine
                        % the outputs of a number of 2-class networks

net = train(net, tutor, x, y, C, kernel);

% generate confusion matrix

confusion_matrix = zeros(k);

o = fwd(net, x);

[tmp,Y] = max(y');
[tmp,O] = max(o');
 
for i=1:k

   for j=1:k

      confusion_matrix(i,j) = length(find(Y == i & O == j));      

   end

end

confusion_matrix

%fprintf(1, '\n\n total number of support vectors = %d\n\n', getnsv(net));

% all done

fprintf(1,'bye bye...\n');

% bye bye...
