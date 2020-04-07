function P=psnr(i1,i2)
%PSNR psnr between a couple of images
% 	P = PSNRS(image1,image2)
% 	It computes the psnr between a couple of gray level images
%   It returns NaN is the images have not the same size
%   (c) Marco CAGNAZZO 2004,2011


P = NaN;
if isequal(size(i1),size(i2))
      err=sum(sum( (i1-i2).^2));
	  err=err/numel(i1);
      P=10*log10(255^2/err);
else
    fprintf('Images have different sizes!\n');
end
