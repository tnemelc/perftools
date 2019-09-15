% convFermi.m
% brief: 
%
%
% references:
%
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
% keywords:
% author: C.Daviller
% date: 19-Dec-2017 

function [ctc, residue] = convFermi(p, tSim, aifSim)

% if 0 == matlabpool('size')
%     matlabpool('open', '8');
% end
A = p(1); k = p(2); t0 = p(3); td = p(4);

ctc = zeros(1, numel(tSim));
% residue =  2 ./ (1 + exp( (2 * (bf / bv) * log(2)) * (tSim - td - t0))) .*  (tSim >= td); % neyrand
% k = p(2);
residue =  A .* (  1 ./ ( 1 + exp(k * (tSim - td - t0)) ) ) .*  (tSim >= td); % mjh

parfor l = 2 : numel(tSim)
    ctc(l) = trapz(tSim(1 : l), aifSim(1 : l) .* residue(l : -1 : 1));
end
%figure(10); plot(sg); pause(0.01);
end