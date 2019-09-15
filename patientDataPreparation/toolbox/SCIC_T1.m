% SCIC_T1.m
% brief: processes Surface Coil Inhomogeneity Correction (SCIC) based on
% PDScans acquired before perfusion image serie acquisition.
%
%
% references: Theory-Based Signal Calibration with Single-Point 
% T1 Measurements for First-Pass Quantitative Perfusion MRI Studies1
% Alexandru Cernicanu, PhD, Leon Axel, MD, PhD
%
%
% input:
% pdScans: PWI acquisition serie (HxWxTime)
% imSerie: TWI acquisition serie (HxWxTime)
% acqParam: struct gathering acquisition of pdscans an image serie
% acqParam.tr : repetition time (s)
%   acqParam.td : time delay between end of RF and RO initiation (s)
%   acqParam.faPD : PWI scans flip angle (rad)
%   acqParam.faT1 : TWI scans flip angle (rad)
%   acqParam.f : fraction of M0 that remains along the direction of the
%               static magnetic field, B0, after application of the saturation pulse
%   acqParam.n : number of flip angle shots
% 
% t1Vect: vector of t1 values to perform the search
% mask (optional) : region where to preocess correction and T1 mapping. If
% no mask, all image will be processed (drastic increase of processing
% time)
%
% output:
% t1Map: T1 map
% Sth: theoretical normalized signal lookup table acoording 
%
% keywords: T1map, Surface Coil Inhomogeneity correction, SCIC, T1 mapping
% author: C.Daviller
% date: 28-Aug-2017  


function [t1Map, Sth] = SCIC_T1(pdScans, imSerie, acqParam, t1Vect, mask)
if ~nargin
    SCIC_T1UI();
    return;
end
    [H, W, T] = size(imSerie);
    if nargin < 5
        mask = ones(H, W);
    end
    fm = figureMgr.getInstance();
    Sth  = theoSignal(acqParam, t1Vect);
    
    % alternatively a scaling factor can of sin(faT1)/sin(faPD) can be
    % applied to the normalized T1-weighted images, enabling analysis of
    % an image signal S, normalized to unity
    pdScanAvg = mean(pdScans, 3) .* (sin(acqParam.faT1) ./ sin(acqParam.faPD));
    t1Map = zeros(H, W);
    fprintf('processing image   ');
    for k = 1 : T
        fprintf('\b\b%02d', k);
        for l = 1 : H
            for m = 1 : W
                if mask(l, m)
                    if pdScanAvg(l, m) == 0
                        t1Map(l, m, k) = 0;
                    else
                        Sdiff = abs((imSerie(l, m, k) / pdScanAvg(l, m)) - Sth);
%                         fm.newFig('signal difference'); plot(t1Vect, (imSerie(l, m, k) / pdScanAvg(l, m))); hold all; plot(t1Vect, Sdiff);
%                         legend('ST1/SPD', 'abs((ST1/SPD) - (num/den))');
                        t1Map(l, m, k) = t1Vect( Sdiff == min(Sdiff));
                    end
                end
            end
        end
    end
    fprintf('\n');
    
    %%inner functions
    function Stheo = theoSignal(p, t1)
        En = ( 1 - exp(-p.tr ./ t1) ) .* ( ( 1 - ( (exp(-p.tr ./ t1) .* cos(p.faT1)) .^ (p.n - 1)) ) ./ ...
                                           ( 1 -   exp(-p.tr ./ t1) .* cos(p.faT1)) );
        
        num = (1 - (1 - p.f) .* exp(-p.td ./ t1)) .* ( ( exp(-p.tr ./ t1) .* cos(p.faT1) ) .^ (p.n - 1) ) + En;
        
        Ed = ( 1 - exp(-p.tr ./ t1)) .*  ( ( 1 - ( (exp(-p.tr ./ t1) .* cos(p.faPD)) .^ (p.n - 1)) )./ ...
                                           ( 1 -  exp(-p.tr ./ t1) * cos(p.faPD)));
        
        den =  (exp(-p.tr ./ t1) .* cos(p.faPD)) .^ (p.n - 1) + Ed;
        
        Stheo = num ./ den;
        
%         fm.newFig('signal evol'); hold all; plot(t1, num); plot(t1, den); plot(t1, Stheo);
%         legend('S_T_1', 'S_P_D', 'S Normalized');
%         xlabel('t1 (s)');
    end

end