function Im_data = partial_k(d,frac_ks,RO,PE)
% Matlab code to generate image from partial k-space acquisition
fraction = frac_ks;

W_ramp = [2*ones(1,(1-fraction)*PE) 2:-1/(0.5*(2*fraction-1)*PE):1/(0.5*(2*fraction-1)*PE) zeros(1,(1-fraction)*PE)];
W_symm = [zeros(1,(1-fraction)*PE) ones(1,uint8((2*fraction-1)*PE)) zeros(1,(1-fraction)*PE)];

W_ramp_2d = repmat(W_ramp, RO, 1);
W_symm_2d = repmat(W_symm, RO, 1);



        data = d;

        M_preweight1 = data.*W_ramp_2d;
        m_preweight1 = ifft2c(M_preweight1);

        M_s1 = data.*W_symm_2d;
        m_s1 = ifft2c(M_s1);
        p1 = exp(-i*(angle(m_s1)));

        im1(:,:) = real(p1.*m_preweight1);
        %im = im(N:-1:1,:);
        %IM(:,:,p,k) = im1(1:1:RO,:);


Im_data=im1;