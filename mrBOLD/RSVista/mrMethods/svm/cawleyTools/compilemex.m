clear mex;

% class smosvctutor

cd @smosvctutor

fprintf(1, 'recompiling method @smosvctutor/smosvctrain...\n');

mex smosvctrain.cpp InfCache.cpp LrrCache.cpp SmoTutor.cpp -lm

cd ..

% class stringmismatch

cd @rbf

fprintf(1, 'recompiling method @rbf/evaluate...\n');

mex evaluate.c -lm

cd ..

% bye bye...

