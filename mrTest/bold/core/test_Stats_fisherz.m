function test_Stats_fisherz
%Validate fisherz calculation
%
%   test_Stats_fisherz()
% 
% Tests: fisherz
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_Stats_fisherz()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2011

% Generate random numbers between 0 and 1:
r = rand(1000);

z = fisherz(r); 
z_another_way = atanh(r);

% Test that you get the same result for both ways of calculating Z: 
assertAlmostEqual(z,z_another_way,1e-10)
% Test that the inversion does what it's supposed to do: 
assertAlmostEqual(r, fisherzinv(z),1e-10)
% Test that the inversion can also be done using tanh: 
assertAlmostEqual(r, tanh(z), 1e-10)

