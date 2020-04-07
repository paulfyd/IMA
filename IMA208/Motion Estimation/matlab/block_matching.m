%% TP Motion estimation
display('TP Motion estimation');
clear all; close all; % clc

%% Read two images from a video sequence
display('Read two images from a video sequence');
fileName = 'flower_cif.y';
k = 4; h = 5;
im1 = readFrame(fileName,k);
im2 = readFrame(fileName,h);
%% Show images
figure(1); image(uint8(im1)); colormap(gray(256)); axis image; axis off
figure(2); image(uint8(im2)); colormap(gray(256)); axis image; axis off

%% Block-based motion estimation: SAD, SSD
display('Block-based motion estimation: SAD, SSD');

%% SSD
display('SSD');
brow =32; bcol=32; search_radius =30;
tic
mvf_ssd =  me_ssd(im2, im1, brow, bcol, search_radius);
toc
%% Show the motion vector field
display('Show the motion vector field');
displayMVF(im1,mvf_ssd,brow,brow);
%% Motion compensation: compute the MC-ed image and the PSNR
display(' Motion compensation: compute the MC-ed image and the PSNR');
mc_ssd = fracMc(im1,mvf_ssd);
psnr_ssd = psnr(im2,mc_ssd);
fprintf('PSNR SSD %5.2f\n', psnr_ssd);
 
%% Show the motion compensated image
display('Show the motion compensated image');
figure; image(uint8(mc_ssd)); colormap(gray(256)); axis image; axis off
title('Motion compensated image, SSD');

%% SAD
display('SAD');
brow = 16; bcol=16; search_radius =30;
tic
mvf_sad =  me_sad(im2, im1, brow, bcol, search_radius);
toc
%% Show the motion vector field
display('Show the motion vector field');
displayMVF(im1,mvf_sad,brow,brow);
%% Motion compensation: compute the MC-ed image and the PSNR
display('Motion compensation: compute the MC-ed image and the PSNR');
mc_sad = fracMc(im1,mvf_sad);
psnr_sad = psnr(im2,mc_sad);
fprintf('PSNR SAD %5.2f\n', psnr_sad);
%% Show the motion compensated image
figure; image(uint8(mc_sad)); colormap(gray(256)); axis image; axis off
title('Motion compensated image, SAD');


%% Block-based motion estimation: SSD+Reg
% Read two images from a different sequence
display('Block-based motion estimation: SSD+Reg');
k = 7; h = 8;
fileName = 'flower_cif.y';
im1 = readFrame(fileName,k);
im2 = readFrame(fileName,h);
%% Show images
figure; image(uint8(im1)); colormap(gray(256)); axis image; axis off
figure; image(uint8(im2)); colormap(gray(256)); axis image; axis off
%% Compute and show the non-regularized MVF
display('Compute and show the non-regularized MVF');
tic
mvf_ssd =  me_ssd(im2, im1, brow, bcol, search_radius);
toc
displayMVF(im1,mvf_ssd,brow,brow);
%% Compute and show the regularized MVF
display('Compute and show the regularized MVF');
tic
mvf_ssd_reg =  me_ssd(im2, im1, brow, bcol, search_radius,50);
toc
displayMVF(im1,mvf_ssd_reg,brow,brow);
%% Compute the motion-compensated images and the PSNRs
display('Compute the motion-compensated images and the PSNRs');
mc_ssd_reg = fracMc(im1,mvf_ssd_reg);
psnr_ssd_reg = psnr(im2,mc_ssd_reg);
fprintf('PSNR SSD REG %5.2f\n', psnr_ssd_reg);

mc_ssd = fracMc(im1,mvf_ssd);
psnr_ssd = psnr(im2,mc_ssd);
fprintf('PSNR SSD  %5.2f\n', psnr_ssd);

