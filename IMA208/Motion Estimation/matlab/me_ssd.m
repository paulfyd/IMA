function [mvf prediction] = me_ssd(cur, ref, brow, bcol, search, lambda)
%ME BMA full search Motion estimation
%   mvf = me(cur, ref, brow, bcol, search);
%
%   A regularization constraint can be used
%   mvf = me(cur, ref, brow, bcol, search, lambda);
%   In this case the function minimize SAD(v)+lambda*error(v)
%   where error(v) is the difference between the candidate vector v and the
%   median of its avalaible neighbors.
%
%   [mvf prediction] = me(...)
%   returns the motion-compensated prediction.
% 
%(C) 2008-2011 Marco Cagnazzo - TELECOM ParisTech
% See also: mc, fracMc
%
[rows cols]=size(cur);
extension = search;

if ~exist('lambda','var')
    lambda = 0;
end

ref_extended =  padarray(ref,[extension extension],'replicate','both');

       
prediction = zeros(size(cur));
lambda = lambda * brow*bcol;

mvf = zeros(rows,cols,2);
% Non-regularized search
if lambda==0,
    % MB scan
    for r=1:brow:rows,
        for c=1:bcol:cols,
            % current MB selection
            B=cur(r:r+brow-1,c:c+bcol-1);
            % Initializations
%             dcolmin=0; drowmin=0;
%             costMin=inf; Rbest = zeros(size(B));
            dcolmin=0; drowmin=0;
            R=ref_extended(r+extension:r+brow-1+extension, ...
                c+extension:c+bcol-1+extension);
            err = B-R;  costMin=  err(:)'*err(:);
            Rbest = R;

            % loop on candidate vectors
            for dcol=-search:search,
                for drow=-search:search,
                    % Reference MB
                    R=ref_extended(r-drow+extension:r-drow+brow-1+extension, ...
                        c-dcol+extension:c-dcol+bcol-1+extension);
                    err = B-R;
                    cost=  err(:)'*err(:);
                    if (cost<costMin)
                        costMin=cost;
                        dcolmin=dcol;
                        drowmin=drow;
                        Rbest = R;
                    end;                   
                end; % loop over drow
            end; % loop over dcol
            % Save the MVF
            mvf(r:r+brow-1,c:c+bcol-1,1)=drowmin;
            mvf(r:r+brow-1,c:c+bcol-1,2)=dcolmin;
            prediction (r:r+brow-1,c:c+bcol-1)=Rbest;
        end; % loop over c
    end; % loop over r
else
    for r=1:brow:rows,
        for c=1:bcol:cols,
            % Current MB
            B=cur(r:r+brow-1,c:c+bcol-1);
            % Initializations
            dcolmin=0; drowmin=0;
            costMin=inf; Rbest = zeros(size(B));
            % neighbours
            pV = computePredictor();
            % loop on candidate vectors
            for dcol=-search:search,
                for drow=-search:search,
                    % Reference MB
                    R=ref_extended(r-drow+extension:r-drow+brow-1+extension, ...
                        c-dcol+extension:c-dcol+bcol-1+extension);
                    err = B-R;                   
                     cost=  err(:)'*err(:)+ lambda * sqrt((drow-pV(1)).^2+(dcol- pV(2)).^2);
                    if (cost<costMin)
                        costMin=cost;
                        dcolmin=dcol;
                        drowmin=drow;
                        Rbest = R;
                    end;                   
                end; % loop over drow
            end; % loop over dcol
            % Save the MVF
            mvf(r:r+brow-1,c:c+bcol-1,1)=drowmin;
            mvf(r:r+brow-1,c:c+bcol-1,2)=dcolmin;
            prediction (r:r+brow-1,c:c+bcol-1)=Rbest;
        end; % loop over c
    end; % loop over r
end

mvf = -mvf; % <<-- per compatibilita con standard


    function  pV = computePredictor()
        %cols=size(mvf,2);
        if (r<brow)&&(c<bcol),
            pV = initVector();
        elseif r<brow  %prima riga
            pV = (mvf(r,c-bcol,:));
        elseif c<bcol % prima colonna
            pV = (mvf(r-brow,c,:));
        else %interno
            if c>= cols-bcol %ultima colonna
                vC = (mvf(r-brow,c-bcol,:));
            else %non ultima colonna
                vC = (mvf(r-brow,c+bcol,:));
            end
            vA = (mvf(r,c-bcol,:));
            vB = (mvf(r-brow,c,:));
            pV = median([vA(:), vB(:), vC(:)],2);
        end
        pV=pV(:);
    end

    function pV = initVector()
        step = 8; cont = 4*step;
        REF = gauss2d(ref,50);
        CUR = gauss2d(cur,50);
        CUR = CUR(cont+1:step:end-cont,cont+1:step:end-cont);
        [ROWS COLS]=size(CUR);
        SSDMIN = inf;
        pV=[0 0];
        for globR = -cont:cont,
            for globC = -cont:cont,
                RR = REF(cont+1-globR:step:cont-globR+ROWS*step, ...
                    cont+1-globC:step:cont-globC+COLS*step);
                SSD = sum(sum((RR-CUR).^2));
                if SSD<SSDMIN,
                    SSDMIN=SSD;
                    pV(1)=globR;
                    pV(2)=globC;
                end
            end
        end        
    end
end
