function output = relaxMtFitFunc(x, m, W_B, W_F, T2_B, R1, S0, t_m, t_s, t_r);
% function output = relaxMtFitFunc(x, m, W_B, W_F, T2_B, R1, S0, t_m, t_s, t_r);
% inputs:
%       x = [k, f] where k is the cross-relaxation rate constant defined
%           for the transition from free pool (F) to bound pool (B), f is the
%           fraction of bound spins expressed in terms of concentrations as f =
%           [B]/([B]+[F])
%       m: MT(:,ii) ??
%
%       W_B: Effective saturation rate of the bound pool
%            W_B(ii) = pi*(w1rms^2)*lorentzian (delta(ii), T2_B);% eqtn (2)
%       W_F: 1/R1_F .* Effective saturation rate of the free pool 
%            W_F = (w1rms./(2*pi*delta)).^2/.055; --> eqtn(3)./R1_F
%            w1rms = 2400; % omega-1 RMS --> ???? where does this number
%            come from???
%       T2_B: T2 relaxation time of Bound pool, units= seconds
%           T2_B = 11e-6; "average-brain" [YY (2004), pg 411, column2, paragraph 1]
%       R1: observed relaxation rate (measured in the independent
%           experiment) [YY(2004), pg 411, column 1, parag 2]
%           nz = T1>0;
%           R1 = zeros(size(T1)); 
%           R1(nz) = 1./T1(nz);
%       S0: Synthetic reference image computed by equation (6) using PD(protein Density) and
%           R1 maps.
%       t_m: duration of an off-resonance RF pulse  
%           t_m = 8e-3; %bese 8e-3
%       t_s: delay time BEFORE an exitation RF pulse
%           t_s = 5e-3; %bese 5e-3
%       t_r: delay time AFTER an exitation RF pulse
%           t_r = 19e-3; %bese 19e-3
%   Output:
%       output: ??? m/S0 - M_z(:,1)./m_norm(1);
%
%    Example:
%       output=relaxMtFitFunc(x, MT(:,ii), W_B, W_F, T2_B, R1(ii),S0(ii), t_m, t_s, t_r)
%

% C : diagonal matrix = diag(cos(alpha),1) corresponding to instant
% rotation of the magnetization Mz_F by an excitation pulse with a flip
% angle alpha
% cos(10*pi/180) = 0.984807753012
% *** FIX THIS: mt flip angle is hard-coded.
C = [ 0.984807753012 0;
            0        1 ];

k = x(1); % the k-parameter is passed through x
f = x(2); % the f-parameter is passed through x

%T2_B = 11e-6; %bese 11e-6

R1_B = 1; %bese 1
% Compute this term just one to save some cycles
kf = k*(1-f)/f;
R1_F = R1 - k*(R1_B - R1)/(R1_B - R1 + kf); % eqtn (4)
%W_F = R1_F*(w1rms./(2*pi*delta)).^2/.055; %bese .055
W_F = R1_F*W_F;

R = [ (-R1_F - k)     (kf)    ; 
           (k)    (-R1_B - kf) ];

A = R1_F*R1_B + R1_F*kf + R1_B*k;
E_s = expm(R*t_s); % relaxation during delays before (t_s) an exitation RF pulse
E_r = expm(R*t_r); % relaxation during delays after (t_r) an exitation RF pulse

I = eye(2); %identity matrix

for ii = 1:length(W_B);
  W = [-W_F(ii), 0;
       0,   -W_B(ii)];
  E_m = expm((R + W)*t_m);% off-resonance saturation by an RF pulse w/ duration t_m 
  D = A + (R1_F + k)*W_B(ii) + (R1_B + kf)*W_F(ii) + W_B(ii)*W_F(ii);
  M_eq = [1-f f]';
  M_ss = 1/D*[(1-f)*(A + R1_F*W_B(ii)) f*(A + R1_B*W_F(ii))]';
  term_1 = inv(I - E_s*E_m*E_r*C);
  %if (rcond(term_1)<1e-4), output = +Inf; return; end;
  term_2 = (E_s*E_m*(I-E_r) + I-E_s)*M_eq;
  term_3 = E_s*(I-E_m)*M_ss;
  M_z(ii,:) = term_1*(term_2 + term_3);
end

% Ova mozebi e nepotrebno, zasto m_norm treba da se zameni so S0 
E_m = expm((R)*t_m); 
D = A;
M_eq = [1-f f]';
M_ss = 1/D*[(1-f)*(A) f*(A)]';
term_1 = inv(I - E_s*E_m*E_r*C);
term_2 = (E_s*E_m*(I - E_r) + I-E_s)*M_eq;
term_3 = E_s*(I-E_m)*M_ss; %na pocetok treba E_s?
m_norm = term_1*(term_2 + term_3);
result = m/S0 - M_z(:,1)./m_norm(1);
%output = sum(result.^2);
output = result;

return;
