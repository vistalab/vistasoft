function Y = magicwand(X, m, n, Tol, eight_or_four);
%*****************************************************************************
%                                                                             
% MAGICWAND                                                                   
%      Given an image and a pixel cooridinate, this function isolates all     
%      neighboring pixels with values within a preset tolerance. This function
%      mimics the behavoir of Adobe's Photoshop magic wand tool.              
%                                                                             
% Synopsis:                                                                   
%      Y=magicwand(X, m, n);                                                  
%              Y=output image of type uint8(logical)                          
%              X=input image of type double                                   
%              m=pixel cooridinate(row)                                       
%              n=pixel cooridinate(col)                                       
%                                                                             
%      Y=magicwand(X, m, n, Tol);                                             
%              Tol=Tolerance value for locating pixel neighbors(default=0.01) 
%                                                                             
%      Y=magicwand(X, m, n, Tol, eight_or_four);                              
%              eight_or_four=string such that if =='eigh', magicwand locates  
%              all eight-neighborhood pixels (default=four-neighborhood)      
%                                                                             
% Daniel Leo Lau                                                              
% lau@ece.udel.edu                                                            
%                                                                             
% Copyright April 7, 1997                                                     
%          
% HISTORY:
%
% June 30 2003                                                                
% ------------ 
% Adapted to   MATLAB 6.5   (sorry, no backward compatibility)
% Some changes in the main function due to the change in the definition of
% logical variables in v6.5.
%
% Yoram Tal (yoramtal123@yahoo.com)
%
%
% November 18 2003
% ------------
% Bob Dougherty (bobd@stanford.edu)  
%
% Added support for RGB images, fixed support for uint8 inputs.
%
%
% MAGICWAND is a mex file