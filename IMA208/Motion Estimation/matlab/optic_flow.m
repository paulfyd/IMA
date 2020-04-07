%% TP Motion estimation
clear all; close all; clc
 
%% Read two images from a video sequence
k = 4; h = 5;
im1 = readFrame('flower_cif.y',k);
im2 = readFrame('flower_cif.y',h);
%% Show images
figure(1); image(uint8(im1)); colormap(gray(256)); axis image; axis off
figure(2); image(uint8(im2)); colormap(gray(256)); axis image; axis off

%% Block-matching initialization
brow = 16; bcol=16; search_radius =13;
tic
mvf_ssd =  me_ssd(im2, im1, brow, bcol, search_radius);
toc
mc_ssd = fracMc(im1,mvf_ssd);
psnr_ssd = psnr(im2,mc_ssd);

%% Optical flow
alpha = 100; ite = 100;
tic
uInitial = mvf_ssd(:,:,2); vInitial=mvf_ssd(:,:,1);
[u, v] = HS(im2, im1, alpha, ite, uInitial, vInitial,0);
toc
% Display the mvf
mvf_hs(:,:,1) = v; mvf_hs(:,:,2) = u;
displayMVF(im1,mvf_hs,4);

% Compute the PSNR
mc_hs = fracMc(im1,mvf_hs);
psnr_hs = psnr(im2,mc_hs);

%% Compare results
fprintf('PSNR SSD %5.2f\nPSNR H-S %5.2f\n',psnr_ssd, psnr_hs);

