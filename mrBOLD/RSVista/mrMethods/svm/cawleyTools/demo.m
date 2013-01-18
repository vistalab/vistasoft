% DEMO
%
% Demonstrate the use of the Support Vector Machine toolbox to distinguish
% examples of Versicolour from Setosa and Virginica varieties of Iris, given
% petal width an length attributes.  The data is taken from the well known
% Iris benchmark [1], available from the UCI Repository of Machine Learning
% Databases (http://www.ics.uci.edu/~mlearn/MLRepository.html).
%
% [1] R. A. Fisher,
%     "The use of multiple measurements in taxonomic problems",
%     Annual Eugenics, 7(2), pp 179-188, 1936.

%
% File        : demo.m
%
% Date        : Saturday 16th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Test harness for object oriented implementation of Vapnik's
%               linear support vector machine (SVM) [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 16/08/1999 - v1.00
%               13/09/2000 - v1.01 minor changes to comments etc
%               13/09/2000 - v1.02 updated to use gateway method svc/train
%               16/09/2000 - v1.10 added xi-alpha estimate of l-o-o error
%               24/11/2000 - v1.11 minor bug-fix for loading iris data under
%                                  all operating systems.
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

clf;

clear classes all;

% load some data

fprintf(1,'loading training data...\n');

iris = load('data/iris.txt');

x = iris(:,3:4);
y = 2*(iris(:,5) == 2)-1;

% define useful constants

l = size(x,1);

% display data

fprintf(1,'displaying data...\n');

plot(x(find(y==1),1)',x(find(y==1),2)','bs',x(find(y==-1),1)',x(find(y==-1),2)','go')
axis(axis + [-0.1 +0.1 -0.1 +0.1])
legend('class one','class two',0);
drawnow;

% create tutor

fprintf(1,'creating tutor...\n');

kernel = rbf(0.5);
C      = 1.0;
tutor  = smosvctutor;

% train support vector machine

fprintf(1,'training support vector machine...\n');

net = train(svc, tutor, x, y, C, kernel);

net = fixduplicates(net, x, y);

net2 = strip(net);

% display support vectors

fprintf(1,'displaying support vectors...\n');

sv = getsv(net2);

hold on
plot(sv(:,1)',sv(:,2)','k+');
legend('class one','class two','support vector',0);
hold off

fprintf(1, 'there are %d support vectors\n', getnsv(net2));

% compute correctness

fprintf(1,'correctness = %4.1f%%\n', 100*sum(sign(fwd(net2,x))==y)/l);

% display decision boundary

fprintf(1,'displaying decision boundary...\n');

a     = axis;
[X,Y] = meshgrid(a(1):0.05:a(2),a(3):0.05:a(4));
X2    = [reshape(X,prod(size(X)),1) reshape(Y,prod(size(X)),1)];
z     = fwd(net2,X2);
z     = reshape(z,size(X));

hold on
contour(X,Y,z,[+1 +1],'b');
contour(X,Y,z,[+0 +0],'r');
contour(X,Y,z,[-1 -1],'g');
legend('class one','class two','support vector','class one margin','decision boundary','class two margin',0);
hold off

% highlight estimated leave-one-out errors

e = xialpha(net);

i = find(e);

fprintf(1,'l-o-o correctness >= %4.1f%%\n', 100*correctness(e));

hold on
plot(x(i,1)', x(i,2)', 'rx');
legend('class one','class two','support vector','class one margin','decision boundary','class two margin','l-o-o error',0);
hold off

% all done

fprintf(1,'bye bye...\n');

% bye bye...
