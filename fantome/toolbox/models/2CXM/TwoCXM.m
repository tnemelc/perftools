% 2CXM.m
% brief: 
% 2CXM model 
% notation is based on Sourbron2012 paper
%
% references:
% Jacquez J A 1985 Compartmental Analysis in Biology and Medicine 2nd edn (Ann Arbor,MI: University of Michigan Press)
% Sourbron 2012, Tracer kinetic modelling in MRI: estimating perfusion and capillary permeability
% input:
% ca: AIF ctc
% param: stucture containing 
%     Fp: plasmaFlow ()
%     PS: permeability surface
%     vp: unitary plasmatic volume 
%     ve: unitary ees volume
% output:
%
% c: ...
% cp: ...
%
%
% keywords: perfusion, 2CXM, model, 2-compartments exchange, CMRI
% author: C.Daviller
% date: 16-Aug-2017  


 function [ct, residue, cp, ce] = TwoCXM(ca, time, params, dispFlag, jSimRunFlag)
 if ~nargin
	TwoCXMUI();
 return;
 end 
 
 if (nargin < 4)
     return;
 elseif (nargin < 5)
    jSimRunFlag = false;
 end

 %% init
 
 Fp = params.Fp / 60;
 PS = params.PS / 60;
 vp = params.vp;
 ve = params.ve;
 
 T = (vp + ve) / Fp; % mean time transit (MTT)
 Tc = vp / Fp; % capillary MTT
 Te = ve / PS; % ees MTT
 
 
 sig_p = ( (T + Te) + sqrt( (T + Te)^2 - 4 * Tc * Te ) ) / ( 2 * Tc * Te );
 sig_m = ( (T + Te) - sqrt( (T + Te)^2 - 4 * Tc * Te ) ) / ( 2 * Tc * Te ); 
 
 % generate residu function
 residue  = ( (T * sig_p - 1) * sig_m * exp(-time * sig_m) + (1 - T * sig_m) * sig_p * exp(-time * sig_p) ) / (sig_p - sig_m);
 
 % time vector
 dt = (time(2) - time(1)) / 50;
 tSim = time(1) : dt : time(end);
 
 % oversample AIF and residue
 caSim =      interp1(time, ca, tSim, 'linear', 'extrap');
 residueSim  = ( (T * sig_p - 1) * sig_m * exp(-tSim * sig_m) + (1 - T * sig_m) * sig_p * exp(-tSim * sig_p) ) / (sig_p - sig_m);
 
 

 %% ctc generation
% ct_trpz = zeros(1, numel(tSim)); 
% for k = 2 : numel(tSim)
%     ct_trpz(k) =  Fp * trapz(tSim(1 : k), caSim(1 : k) .* residueSim(k : -1 : 1));
% end
% ct_trpz = interp1(tSim, ct_trpz, time, 'linear', 'extrap');

convolutionLen = numel(caSim) + numel(residueSim);
ct_fft = ifft(fft(caSim, convolutionLen) .* fft(Fp .* residueSim, convolutionLen), 'symmetric');
ct_fft = dt .* ct_fft(1 : length(tSim));

% ct_conv = dt .* conv(caSim, Fp .* residueSim);

ct = interp1(tSim, ct_fft, time, 'linear', 'extrap');

lgdLst = {};
 if dispFlag
     
     figureMgr.getInstance().newFig('TwoCXM: result'); %hold off;
     clf;
     subplot(211);
     plot(time, ca, 'color', [0.2 0.6 0.2]); hold all;  lgdLst = [lgdLst 'Ca'];
     
    % plot(time, ct, 'b'); lgdLst = [lgdLst 'ct ()'];
     %plot(tSim, ct_fft, 'c'); lgdLst = [lgdLst 'ct (fft conv)'];
     
     %plot(time, ct_trpz, 'k'); lgdLst = [lgdLst 'ct (trpz conv)'];
     
     
%      plot((0 : length(ct_conv) - 1) * dt, ct_conv, '+y'); lgdLst = [lgdLst 'ct (classical conv)'];
     
     subplot(212);
     plot(tSim, Fp .* residueSim);
     legend({'residue'}, 'fontsize', 24);
     xlabel('temps (s)', 'fontsize', 20);
     ylabel('A.U', 'fontsize', 20);
 end

 
%% jSim
% ca = zeros(1, numel(time));
% ca(20) = 0.0378;
if jSimRunFlag
    jSimWrapper.getInstance().prepareProject('Comp2FlowExchangeCtcGen', caSim, tSim);
    paramOut = { 'Ct' , 'Fp', 'Cp', 'Cisf', 'Cout'};
    p.Fp   = params.Fp;
    p.Vp   = params.vp;
    p.Visf = params.ve;
    p.PSc  = params.PS;
    
    out = jSimWrapper.getInstance().simulate(p, paramOut);
    
    if dispFlag
        figureMgr.getInstance().newFig('TwoCXM: result'); hold off;
        subplot(211);
        % plot(tSim, ct_jSim, ':');
        plot(out.Ct__1,  p.Vp .* out.Cp + p.Visf .* out.Cisf, 'color', 'b'); lgdLst = [lgdLst 'Ct (jSim)'];
        plot(out.Cp__1,  out.Cp, '--', 'color', [1 0.4 0]); lgdLst = [lgdLst 'Cp (jSim)'];
        plot(out.Cisf__1, out.Cisf, '--', 'color', 'c'); lgdLst = [lgdLst 'Ce (jSim)'];
        
        
%         legend('ca', 'ct(matlab)', 'ct (jSim)');
        legend(lgdLst);
        title(sprintf('Fp=%.002f, Vp=%.02f, Ve=%.02f, PS=%.02f', params.Fp, params.vp, params.ve, params.PS), 'fontsize', 24);
        legend(lgdLst, 'fontsize', 24);
        xlabel('temps (s)', 'fontsize', 20);
        ylabel('signal (A.U)', 'fontsize', 20);
    end
    dif = sum(abs(interp1(out.Ct__1, out.Ct, time, 'linear', 'extrap') - ct));
    ct = interp1(out.Ct__1, p.Vp .* out.Cp + p.Visf .* out.Cisf, time, 'linear', 'extrap');
end
 subplot(211); xlim([0 50]); ylim([0 1e-3]); subplot(212); xlim([0 50]); ylim([0 0.07]);
end