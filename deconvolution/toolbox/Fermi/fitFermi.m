% fitFermi.m
% brief: 
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% author: C.Daviller
% date: 04-Nov-2016 


function  [mbfOpt, mbvOpt, ct_fit, residue, delay] = fitFermi(ca, time, ct, p0)
if ~nargin
    fitFermiUI();
    return;
end
if ~exist('p0', 'var')
    %bf    bv   td  t0(residue shoulder)
    p0 = [1e-9,     1e-9,  1, 1];
end

lb = [  0,   0,  0 + p0(3),         0];
ub = [0.07, 0.3, 3 + p0(3), 3];

%oversample data for convolution reasons
% dtSim = (time(2) - time(1)) / 20;
dtSim = (time(2) - time(1)) / 5;
tSim = time(1) : dtSim : time(end);
ca_Sim = interp1(time, ca, tSim, 'linear', 'extrap');
ct_Sim = interp1(time, ct, tSim, 'linear', 'extrap');

opts = optimset('Display','off');
%F = @(p0, time) localConvFermi(p0, tSim, ca_Sim);
F_fft = @(p0, time) localConvFermi_fft(p0, tSim, ca_Sim);

%[popt, ~,~,~,~] = lsqcurvefit(F, p0, tSim, ct_Sim, lb, ub);
[popt_fft, ~,~,~,~] = lsqcurvefit(F_fft, p0, tSim, ct_Sim, lb, ub, opts);


% mbfOpt = popt(1); mbvOpt = popt(2);
mbfOpt = popt_fft(1); mbvOpt = popt_fft(2);
delay = popt_fft(3);
%[ctFit, residue]= localConvFermi([mbfOpt, mbvOpt, popt(3), popt(4)], tSim, ca_Sim);
[ctFit_fft, residue]= localConvFermi_fft([popt_fft(1), popt_fft(2), popt_fft(3), popt_fft(4)], tSim, ca_Sim);
%figure; plot(time, ct, '--'); hold all; plot(tSim, ctFit,'o');plot(tSim, ctFit_fft, '+');


ct_fit = interp1(tSim, ctFit_fft, time, 'linear', 'extrap');
residue = interp1(tSim, residue, time, 'linear', 'extrap');
end

function [ct_fit, residue]= localConvFermi(p, time, ca)

% if 0 == matlabpool('size')
%     matlabpool('open', '8');
% end
 
bf = p(1); bv = p(2); td = p(3); t0 = p(4);

ct_fit = zeros(1, numel(time));
residue =  2 ./ (1 + exp( (2 * (bf / bv) * log(2)) * (time - td - t0))) .*  (time >= td); % neyrand
% residue =  (  1 ./ ( 1 + exp((bf / bv) * (tSim - td - t0)) ) ).*  (tSim >= td); % mjh

parfor k = 2 : numel(time)
    ct_fit(k) = bf * trapz(time(1 : k), ca(1 : k) .* residue(k : -1 : 1));
end
%figure(10); plot(sg); pause(0.01);
end

function [sg, residue] = localConvFermi_fft(p, time, aif)
    bf = p(1); bv = p(2); td = p(3); t0 = p(4);

    dt = time(2) - time(1);
    
    %     sg = zeros(1, numel(tSim));
    residue =  2 ./ (1 + exp( (2 * (bf / bv) * log(2)) * (time - td - t0))) .*  (time >= td); % neyrand

    % residue =  (  1 ./ ( 1 + exp((bf / bv) * (tSim - td - t0)) ) ).*  (tSim >= td); % mjh
    aifLen = numel(aif);
    residueLen = numel(residue);
    sg = ifft(fft(aif, aifLen + residueLen) .* fft(bf .* residue, aifLen + residueLen), 'symmetric');
    sg = dt .* sg(1 : length(time));
    
end


