function motcomp = fracMc(ref,mvf,outofbound)
%fracMc Motion compensation with fractional MV and image extension
% motcomp = mc(ref,mvf);
% REF reference frame
% MVF motion vector field (see me for the vector format)
% MOTCOMP motion-compensated prediction
%
%  motcomp = fracMc(ref,mvf,extension)
% An image extension can be specified in order to manage out-of-image
% vectors. Default value is 'rep' for replication. You can use 'symmetric'
% and 'inpainting' (high complexity)
%
% (C) 2008 Marco Cagnazzo - TELECOM ParisTech
% See also: mc, me
%
if nargin<3
    outofbound=20;
end
[rows cols] = size(ref);
[mc_c mc_r] = meshgrid(1:cols,1:rows);
mc_r_tmp = mc_r + mvf(:,:,1);
mc_c_tmp = mc_c + mvf(:,:,2);

if isa(outofbound,'numeric'),
    extension = outofbound;
    ref =  padarray(ref,[extension extension],'symmetric','both');
else
    min_row = abs(min(mc_r_tmp(:)));
    max_row = max(mc_r_tmp(:))-rows;
    min_col = abs(min(mc_c_tmp(:)));
    max_col = max(mc_c_tmp(:))-cols;
    extension = round(max([min_row max_row min_col max_col]))+1;
    
    switch lower(outofbound)
        case {'rep','replicate','replicated'}
            ref =  padarray(ref,[extension extension],'replicate','both');
        case {'sym','symm','symmetric'}
            ref =  padarray(ref,[extension extension],'symmetric','both');
        case {'circ',  'circular'}
            ref =  padarray(ref,[extension extension],'circular','both');
        case {'inp' 'inpaint' 'inpainting'}
            rgb_ref_extended =  inpaintExt(ref, extension);
            yuv_ref_extended = double(rgb2ycbcr(uint8(rgb_ref_extended)));
            ref = yuv_ref_extended(:,:,1);
        otherwise
            warning('MCFRAC:EXT','Unrecognized image extension for out-of-boundary vectors. Using default replicated extension');
            ref =  padarray(ref,[extension extension],'replicate','both');
    end
end

[colMeshGrid rowMeshGrid] = meshgrid(1:cols+2*extension,1:rows+2*extension);

mc_r = mc_r_tmp + extension;
mc_c = mc_c_tmp + extension;

motcomp =  interp2(colMeshGrid, rowMeshGrid, ref, mc_c, mc_r, 'linear',mean(mean((ref))));
