function test_Scripts
%
%
% USAGE: Performs a very quick test on a number of short scripts used by mrBOLD
% including: 
% coords2Indices 
%
% This ensures that this functionality has not been broken or removed. 
% TODO: Generalized this test for more one-off math scripts used.
%
% INPUT: N/A
% Manually has expected input created. The function is then run with a
% known input and produces the expected output. 
%
% OUTPUT: N/A
% Errors will occur if functionality is no longer correct or the coords2Indices
% function no longer exists.

expectedAnswer = [1 5 9];

coords = [1 2 3;
          1 2 3];
realAnswer = coords2Indices(coords,[3 3]);

assertEqual(expectedAnswer,realAnswer);
