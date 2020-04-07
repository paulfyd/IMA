function   frame = readFrame(nomefile, format, k)
%READFRAME reads a frame from a raw video file
%   frame = readFrame(nomefile, k)
%   Resolution and color information are inferred from the file name
%   Explicit resoluton and color can be used with the following syntax
%   frame = readFrame(nomefile, format, k)
%   In this case the second variable is a struct
%   Resolution is specified in the following alternative ways
%   1) the name of the sequence is XXX_cif.ZZZ or XXX_qcif.ZZZ, OR
%   XXX_colsxrows.ZZZ (ex. ballet_512x384.y)
%   2) the variable FORMAT has a field called resolution which is a string
%      with value 'cif', 'qcif', 'sd' or 'hd'
%   3) the variable FORMAT has two fields called row and col
%
%   Color space is specified in the following alternative ways
%   1) the name for the sequence is XXX_YYY.y (in this case it is yuv 400)
%   or XXX_YYY.yuv (in this case it is yuv 420)
%   2) the FORMAT variable has a field called color whose value is a
%   string. It can be '400', '420' or '444'
%
%   Special case: getting a luminance image from a color video. To get
%   this, add a field 'output' to format, with value 'y'
%   
%   Examples:
% % Read a color CIF frame 
% video = 'coastguard_cif.yuv';
% yuv = readFrame(video,k);
% image(ycbcr2rgb(uint8(yuv))); % or imageYUV(yuv);
%
% % Read a luminance image from a color video
% format = struct('resolution','cif','color','420','output','y');
% yuv = readFrame(video,format,k);
% figure;
% imageYUV(yuv);
%
% % Read non-standard resolution
% format = struct('row',768,'col',1090,'color','420');
% yuv = readFrame('seq.yuv',format,k);
% figure;
% imageYUV(yuv);
%
% % Read non-standard resolution specified in file name
% yuv = readFrame('seq_512x384.yuv',k);
% figure;
% imageYUV(yuv);
%
%  See also imageYUV
% (C) 2008-2011 Marco Cagnazzo - TELECOM ParisTech
%  v.1.0.2


frame=[];
fid = fopen(nomefile,'r');
if fid < 0, fprintf('File %s does not exist.\n', nomefile); return; end;
if nargin==2,
    k = format;
    format = struct();
end

[rows cols color bytes_per_frame] = getInfo(nomefile,format);

byte_shift = bytes_per_frame * k;
if fseek(fid,byte_shift,'bof')<0,
    error('Impossible to get frame %d in file %s',k,nomefile);
end
frame (:,:,1) = transpose(fread(fid, [cols rows], 'uchar'));
if color>0,
    tmpU = fread(fid, [cols/color rows/color], 'uchar');
    tmpV = fread(fid, [cols/color rows/color], 'uchar');
    if color>1,
        [X Y]=meshgrid(2:2:rows,1:2:cols); % Griglia di campionam. di tmpU
        [XI YI]=meshgrid(1:rows,1:cols);   % Griglia desiderata
        U=interp2(X,Y,tmpU,XI,YI,'*spline');
        V=interp2(X,Y,tmpV,XI,YI,'*spline');
        frame(:,:,2) = U';
        frame(:,:,3) = V';
    else
        frame(:,:,2) = tmpU';
        frame(:,:,3) = tmpV';
    end
end
fclose(fid);
if color, needed_components  = 3; else needed_components  = 1; end
if numel(frame)<(rows*cols*needed_components)  
    error('readFrame: unexpected end of file %s',nomefile);
end



function [rows cols color bytes_per_frame cstring] = getInfo(nomefile,format)
%GETINFO resolution and color space from file name or format struct
% [rows cols color bytes_per_frame cstring] = getInfo(nomefile,format)

if nargin == 1, format = struct('empty',''); end;
    
uscore = strfind(nomefile,'_');
dot    = strfind(nomefile,'.');
inlineres = regexp(nomefile,'[0-9]+x[0-9]+','match'); 

if isfield(format, 'resolution');
    RES = format.resolution;
elseif ~isempty(uscore)
    RES = nomefile(uscore(end)+1:dot-1);
else
    RES = [];
end

if isfield(format,'row') && isfield(format,'col')
    rows = format.row;
    cols = format.col;
elseif isfield(format,'rows') && isfield(format,'cols')
    rows = format.rows;
    cols = format.cols;
elseif ~isempty(inlineres),
    xpos = strfind(inlineres,'x');
    cols = str2double(inlineres{1}(1:xpos{1}-1));
    rows = str2double(inlineres{1}(xpos{1}+1:end));
elseif ~isempty(RES)
    switch RES
        case 'cif'
            rows = 288; cols = 352;
        case 'qcif'
            rows = 144; cols = 176;
        case 'sd'
            rows = 576; cols = 704;
        case '4cif'
            rows = 576; cols = 704;
        otherwise
            fprintf('Size information not correct, using default CIF resolution\n');
            rows = 288; cols = 352;
    end
else
    fprintf('Size information not included, using default CIF resolution\n');
    rows = 288; cols = 352;
end

if isfield(format,'color');
    switch lower(format.color)
        case {400, '400'}
            bytes_per_frame = rows * cols;
            color = 0;
            cstring = '.y';
        case {420, '420'}
            bytes_per_frame = rows * cols * 1.5;
            cstring = '.yuv';
            color = 2;
        case {444, '444'}
            bytes_per_frame = rows * cols * 3;
            cstring = '.yuv';
            color = 1;
        otherwise
            fprintf('Color space information not correct into the FORMAT variable.\n');
            fprintf('Using default 4:2:0 format.\n');
            bytes_per_frame = rows * cols * 1.5;
            color = 2;
            cstring = '.yuv';
    end
else
    switch lower(nomefile(dot+1:end))
        case 'y'
            bytes_per_frame = rows * cols;
            color = 0;
        case 'yuv'
            bytes_per_frame = rows * cols * 1.5;
            color = 2;
        otherwise
            fprintf('Color space information not included into the filename.\n');
            fprintf('Using default 4:2:0 format.\n');
            bytes_per_frame = rows * cols * 1.5;
            color = 2;
    end
end

if isfield(format, 'output'),
    if isequal(format.output,'y'),
        color = 0;
    end
end      