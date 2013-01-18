function diff_vol = dtiSmoothAnisoPM(vol, num_iter, delta_t, kappa, option, voxel_spacing)
%ANISODIFF2D Conventional anisotropic diffusion
%   DIFF_VOL = ANISODIFF3D(VOL, NUM_ITER, DELTA_T, KAPPA, OPTION, VOXEL_SPACING) perfoms 
%   conventional anisotropic diffusion (Perona & Malik) upon a stack of gray scale images.
%   A 3D network structure of 26 neighboring nodes is considered for diffusion conduction.
% 
%       ARGUMENT DESCRIPTION:
%               VOL      - gray scale volume data (MxNxP).
%               NUM_ITER - number of iterations. 
%               DELTA_T  - integration constant (0 <= delta_t <= 3/44).
%                          Usually, due to numerical stability this 
%                          parameter is set to its maximum value.
%               KAPPA    - gradient modulus threshold that controls the conduction.
%               OPTION   - conduction coefficient functions proposed by Perona & Malik:
%                          1 - c(x,y,z,t) = exp(-(nablaI/kappa).^2),
%                              privileges high-contrast edges over low-contrast ones. 
%                          2 - c(x,y,z,t) = 1./(1 + (nablaI/kappa).^2),
%                              privileges wide regions over smaller ones.
%          VOXEL_SPACING - 3x1 vector column with the x, y and z dimensions of
%                          the voxel (milimeters). In particular, only cubic and 
%                          anisotropic voxels in the z-direction are considered. 
%                          When dealing with DICOM images, the voxel spacing 
%                          dimensions can be extracted using MATLAB's dicominfo(.).
% 
%       OUTPUT DESCRIPTION:
%               DIFF_VOL - (diffused) volume with the largest scale-space parameter.
% 
%   Example
%   -------------
%   vol = randn(100,100,100);
%   num_iter = 4;
%   delta_t = 3/44;
%   kappa = 70;
%   option = 2;
%   voxel_spacing = ones(3,1);
%   diff_vol = anisodiff3D(vol, num_iter, delta_t, kappa, option, voxel_spacing);
%   figure, subplot 121, imshow(vol(:,:,50),[]), subplot 122, imshow(diff_vol(:,:,50),[])
% 
% See also anisodiff1D, anisodiff2D.

% References: 
%   P. Perona and J. Malik. 
%   Scale-Space and Edge Detection Using Anisotropic Diffusion.
%   IEEE Transactions on Pattern Analysis and Machine Intelligence, 
%   12(7):629-639, July 1990.
% 
%   G. Grieg, O. Kubler, R. Kikinis, and F. A. Jolesz.
%   Nonlinear Anisotropic Filtering of MRI Data.
%   IEEE Transactions on Medical Imaging,
%   11(2):221-232, June 1992.
% 
%   MATLAB implementation based on Peter Kovesi's anisodiff(.):
%   P. D. Kovesi. MATLAB and Octave Functions for Computer Vision and Image Processing.
%   School of Computer Science & Software Engineering,
%   The University of Western Australia. Available from:
%   <http://www.csse.uwa.edu.au/~pk/research/matlabfns/>.
% 
% Credits:
% Daniel Simoes Lopes
% ICIST
% Instituto Superior Tecnico - Universidade Tecnica de Lisboa
% danlopes (at) civil ist utl pt
% http://www.civil.ist.utl.pt/~danlopes
%
% May 2007 original version.

% Convert input volume to double.
vol = double(vol);

% Useful variables.
[rows cols pags] = size(vol);

% PDE (partial differential equation) initial condition.
diff_vol = vol;
clear vol

% Center voxel distances.
x = voxel_spacing(1);
y = voxel_spacing(2);
z = voxel_spacing(3);
dx = 1;
dy = 1;
dz = z/x;
dd = sqrt(dx^2+dy^2);
dh = sqrt(dx^2+dz^2);
dc = sqrt(dd^2+dz^2);

% 3D convolution masks - finite differences.
h1 = zeros(3,3,3); h1(2,2,2) = -1; h1(2,2,1) = 1;
h2 = zeros(3,3,3); h2(2,2,2) = -1; h2(2,2,3) = 1;
h3 = zeros(3,3,3); h3(2,2,2) = -1; h3(2,1,2) = 1;
h4 = zeros(3,3,3); h4(2,2,2) = -1; h4(2,3,2) = 1;
h5 = zeros(3,3,3); h5(2,2,2) = -1; h5(3,2,2) = 1;
h6 = zeros(3,3,3); h6(2,2,2) = -1; h6(1,2,2) = 1;

h7 = zeros(3,3,3); h7(2,2,2) = -1; h7(3,1,1) = 1;
h8 = zeros(3,3,3); h8(2,2,2) = -1; h8(2,1,1) = 1;
h9 = zeros(3,3,3); h9(2,2,2) = -1; h9(1,1,1) = 1;
h10 = zeros(3,3,3); h10(2,2,2) = -1; h10(3,2,1) = 1;
h11 = zeros(3,3,3); h11(2,2,2) = -1; h11(1,2,1) = 1;
h12 = zeros(3,3,3); h12(2,2,2) = -1; h12(3,3,1) = 1;
h13 = zeros(3,3,3); h13(2,2,2) = -1; h13(2,3,1) = 1;
h14 = zeros(3,3,3); h14(2,2,2) = -1; h14(1,3,1) = 1;

h15 = zeros(3,3,3); h15(2,2,2) = -1; h15(3,1,2) = 1;
h16 = zeros(3,3,3); h16(2,2,2) = -1; h16(1,1,2) = 1;
h17 = zeros(3,3,3); h17(2,2,2) = -1; h17(3,3,2) = 1;
h18 = zeros(3,3,3); h18(2,2,2) = -1; h18(1,3,2) = 1;

h19 = zeros(3,3,3); h19(2,2,2) = -1; h19(3,1,3) = 1;
h20 = zeros(3,3,3); h20(2,2,2) = -1; h20(2,1,3) = 1;
h21 = zeros(3,3,3); h21(2,2,2) = -1; h21(1,1,3) = 1;
h22 = zeros(3,3,3); h22(2,2,2) = -1; h22(3,2,3) = 1;
h23 = zeros(3,3,3); h23(2,2,2) = -1; h23(1,2,3) = 1;
h24 = zeros(3,3,3); h24(2,2,2) = -1; h24(3,3,3) = 1;
h25 = zeros(3,3,3); h25(2,2,2) = -1; h25(2,3,3) = 1;
h26 = zeros(3,3,3); h26(2,2,2) = -1; h26(1,3,3) = 1;

% Anisotropic diffusion.
for t = 1:num_iter

    % Finite differences. [imfilter(.,.,'conv') can be replaced by convn(.,.,'same')]
    % Due to possible memory limitations, the diffusion
    % will be calculated at each page/slice of the volume.
    for p = 1:pags-2
        diff3pp = diff_vol(:,:,p:p+2);
        aux = imfilter(diff3pp,h1,'conv'); nabla1 = aux(:,:,2);
        aux = imfilter(diff3pp,h2,'conv'); nabla2 = aux(:,:,2);
        aux = imfilter(diff3pp,h3,'conv'); nabla3 = aux(:,:,2);
        aux = imfilter(diff3pp,h4,'conv'); nabla4 = aux(:,:,2);
        aux = imfilter(diff3pp,h5,'conv'); nabla5 = aux(:,:,2);
        aux = imfilter(diff3pp,h6,'conv'); nabla6 = aux(:,:,2);
        aux = imfilter(diff3pp,h7,'conv'); nabla7 = aux(:,:,2);
        aux = imfilter(diff3pp,h8,'conv'); nabla8 = aux(:,:,2);
        aux = imfilter(diff3pp,h9,'conv'); nabla9 = aux(:,:,2);
        aux = imfilter(diff3pp,h10,'conv'); nabla10 = aux(:,:,2);
        aux = imfilter(diff3pp,h11,'conv'); nabla11 = aux(:,:,2);
        aux = imfilter(diff3pp,h12,'conv'); nabla12 = aux(:,:,2);
        aux = imfilter(diff3pp,h13,'conv'); nabla13 = aux(:,:,2);
        aux = imfilter(diff3pp,h14,'conv'); nabla14 = aux(:,:,2);
        aux = imfilter(diff3pp,h15,'conv'); nabla15 = aux(:,:,2);
        aux = imfilter(diff3pp,h16,'conv'); nabla16 = aux(:,:,2);
        aux = imfilter(diff3pp,h17,'conv'); nabla17 = aux(:,:,2);
        aux = imfilter(diff3pp,h18,'conv'); nabla18 = aux(:,:,2);
        aux = imfilter(diff3pp,h19,'conv'); nabla19 = aux(:,:,2);
        aux = imfilter(diff3pp,h20,'conv'); nabla20 = aux(:,:,2);
        aux = imfilter(diff3pp,h21,'conv'); nabla21 = aux(:,:,2);
        aux = imfilter(diff3pp,h22,'conv'); nabla22 = aux(:,:,2);
        aux = imfilter(diff3pp,h23,'conv'); nabla23 = aux(:,:,2);
        aux = imfilter(diff3pp,h24,'conv'); nabla24 = aux(:,:,2);
        aux = imfilter(diff3pp,h25,'conv'); nabla25 = aux(:,:,2);
        aux = imfilter(diff3pp,h26,'conv'); nabla26 = aux(:,:,2);
        
        % Diffusion function.
        if option == 1
            c1 = exp(-(nabla1/kappa).^2);
            c2 = exp(-(nabla2/kappa).^2);
            c3 = exp(-(nabla3/kappa).^2);
            c4 = exp(-(nabla4/kappa).^2);
            c5 = exp(-(nabla5/kappa).^2);
            c6 = exp(-(nabla6/kappa).^2);
            c7 = exp(-(nabla7/kappa).^2);
            c8 = exp(-(nabla8/kappa).^2);
            c9 = exp(-(nabla9/kappa).^2);
            c10 = exp(-(nabla10/kappa).^2);
            c11 = exp(-(nabla11/kappa).^2);
            c12 = exp(-(nabla12/kappa).^2);
            c13 = exp(-(nabla13/kappa).^2);
            c14 = exp(-(nabla14/kappa).^2);
            c15 = exp(-(nabla15/kappa).^2);
            c16 = exp(-(nabla16/kappa).^2);
            c17 = exp(-(nabla17/kappa).^2);
            c18 = exp(-(nabla18/kappa).^2);
            c19 = exp(-(nabla19/kappa).^2);
            c20 = exp(-(nabla20/kappa).^2);
            c21 = exp(-(nabla21/kappa).^2);
            c22 = exp(-(nabla22/kappa).^2);
            c23 = exp(-(nabla23/kappa).^2);
            c24 = exp(-(nabla24/kappa).^2);
            c25 = exp(-(nabla25/kappa).^2);
            c26 = exp(-(nabla26/kappa).^2);            
        elseif option == 2
            c1 = 1./(1 + (nabla1/kappa).^2);
            c2 = 1./(1 + (nabla2/kappa).^2);
            c3 = 1./(1 + (nabla3/kappa).^2);
            c4 = 1./(1 + (nabla4/kappa).^2);
            c5 = 1./(1 + (nabla5/kappa).^2);
            c6 = 1./(1 + (nabla6/kappa).^2);
            c7 = 1./(1 + (nabla7/kappa).^2);
            c8 = 1./(1 + (nabla8/kappa).^2);
            c9 = 1./(1 + (nabla9/kappa).^2);
            c10 = 1./(1 + (nabla10/kappa).^2);
            c11 = 1./(1 + (nabla11/kappa).^2);
            c12 = 1./(1 + (nabla12/kappa).^2); 
            c13 = 1./(1 + (nabla13/kappa).^2);
            c14 = 1./(1 + (nabla14/kappa).^2);
            c15 = 1./(1 + (nabla15/kappa).^2);
            c16 = 1./(1 + (nabla16/kappa).^2);
            c17 = 1./(1 + (nabla17/kappa).^2);
            c18 = 1./(1 + (nabla18/kappa).^2); 
            c19 = 1./(1 + (nabla19/kappa).^2);
            c20 = 1./(1 + (nabla20/kappa).^2);
            c21 = 1./(1 + (nabla21/kappa).^2);
            c22 = 1./(1 + (nabla22/kappa).^2);
            c23 = 1./(1 + (nabla23/kappa).^2);
            c24 = 1./(1 + (nabla24/kappa).^2);             
            c25 = 1./(1 + (nabla25/kappa).^2);
            c26 = 1./(1 + (nabla26/kappa).^2);             
        end

    % Discrete PDE solution.
    diff_vol(:,:,p+1) = diff_vol(:,:,p+1) + ...
                        delta_t*(...
                        (1/(dz^2))*c1.*nabla1 + (1/(dz^2))*c2.*nabla2 + ...
                        (1/(dx^2))*c3.*nabla3 + (1/(dx^2))*c4.*nabla4 + ...
                        (1/(dy^2))*c5.*nabla5 + (1/(dy^2))*c6.*nabla6 + ...
                        ...
                        (1/(dc^2))*c7.*nabla7 + (1/(dh^2))*c8.*nabla8 + ...
                        (1/(dc^2))*c9.*nabla9 + (1/(dh^2))*c10.*nabla10 + ...
                        (1/(dh^2))*c11.*nabla11 + (1/(dc^2))*c12.*nabla12 + ...
                        (1/(dh^2))*c13.*nabla13 + (1/(dc^2))*c14.*nabla14 + ...
                        ...
                        (1/(dd^2))*c15.*nabla15 + (1/(dd^2))*c16.*nabla16 + ...
                        (1/(dd^2))*c17.*nabla17 + (1/(dd^2))*c18.*nabla18 + ...
                        ...
                        (1/(dc^2))*c19.*nabla19 + (1/(dh^2))*c20.*nabla20 + ...
                        (1/(dc^2))*c21.*nabla21 + (1/(dh^2))*c22.*nabla22 + ...
                        (1/(dh^2))*c23.*nabla23 + (1/(dc^2))*c24.*nabla24 + ...
                        (1/(dh^2))*c25.*nabla25 + (1/(dc^2))*c26.*nabla26);
    end
end

return;
