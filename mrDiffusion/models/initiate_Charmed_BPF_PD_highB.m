


function Initiat_Charmed_BPF_PD_highB






%save(Sname,'CC_Cor','Gcc','CSFcc','Wcc','Fcc','Fcc_cor1','Fcc_cor2','Fcc_cor12')
% for i=1%:5
%     dir='/white/u4/avivm/matlab/CHARMED_anlog/semntation_tisuue/';
% Sname=strcat(dir,'ns_PVCC_0',num2str(i))% could be 01 02 03 04 05 deend of what we asume G/W ratio is in white matter
% 
% load(Sname)
%S_Bvecs='/biac3/wandell4/data/reading_longitude/dti_adults/ah070508/raw/dti_g13_b800_aligned.bvecs';
S_Bvecs='/biac3/wandell4/data/reading_longitude/dti_adults/ns090519/raw/dwi_g354_b10000_aligned.bvecs';

%S_Bvals='/biac3/wandell4/data/reading_longitude/dti_adults/ah070508/raw/dti_g13_b800_aligned.bvals';
S_Bvals='/biac3/wandell4/data/reading_longitude/dti_adults/ns090519/raw/dwi_g354_b10000_aligned.bvals';


%S_Raw='/biac3/wandell4/data/reading_longitude/dti_adults/ah070508/raw/dti_g13_b800_aligned.nii.gz';
S_Raw='/biac3/wandell4/data/reading_longitude/dti_adults/ns090519/raw/dwi_g354_b10000_aligned.nii.gz';

% dt6_path='/biac3/wandell4/data/reading_longitude/dti_adults/ns090519/dti40';
% 
% relax_DirDat = '/biac3/wandell5/data/relaxometry/ns_090512/trilin_nss_1';
% f = niftiRead(fullfile(relax_DirDat,'f.nii.gz'));
% BFP=f.data;
% 
% BPF=Fcc_cor12(CC_Cor);
% G=Gcc(CC_Cor);
% W=Wcc(CC_Cor);
% C=CSFcc(CC_Cor);
%         
%          
% for ii=1:1%4
% if ii==1, BPF=Fcc(CC_Cor);end;
% if ii==2, BPF=Fcc_cor1(CC_Cor);end;
% if ii==3, BPF=Fcc_cor2(CC_Cor);end;
% if ii==4, BPF=Fcc_cor12(CC_Cor);end;

%name=strcat('nsCC_chrm_F_PD_Gama',num2str(i),'_',num2str(ii));
name=('ns_charmed__try1_2r_1h');
%dt7 = dtiRawFit_Charmed_PD_BPF_highB(S_Raw, S_Bvecs, S_Bvals, name, [], 'charmed',[],[],CC_Cor,BPF,G,W,C,dt6_path)%charmed
%dt7 = dtiRawFit_Charmed_PD_BPF_highB(S_Raw, S_Bvecs, S_Bvals, name, [], 'charmed',[],[],[],[],[],[],[],[])%charmed
%dt7 = dtiRawFit_Charmed_PD_BPF_highB(S_Raw, S_Bvecs, S_Bvals, name, [], 'charmed',[],[],CC_Cor,BPF,[],[],[])%charmed
dt7 =dtiRawFit_Charmed_highB_comp(S_Raw, S_Bvecs, S_Bvals, name, [], 'charmed',[],[],[],[],[],[],[],[],1,2)

% end;
% end;
% options =  optimset('LevenbergMarquardt','on');
% x0=[1];
% lb=[1e-6];
% ub=[5 ];
% for ii=1:1length(CC_Cor)
%     
% if W(ii)>0;
%     
%     [x1, resnorm] = lsqnonlin(@(x) GamaPD_BPD_Err(x,W(ii),G(ii),BPF(ii)),x0,lb,ub,options);
%                                                             
%     x_1(:,ii)=x1;
%     resnorm1(:,ii)=resnorm;
%    end;
% end;

