% fitFermiFFT.m
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
% date: 10-Jan-2018  


 function [mbf, mbv, fitCt, r] = fitFermiFFT(aif, time, ct, p0)
     if ~nargin
         fitFermiFFTUI();
         return;
     end

     %lower and upper bounds (SI units)
     %     A        k      t0  
     lb = [0,     1e-3,   0.00];
     ub = [5,      100,     5];

     % find cutOff position as the minima between first and seconds pass
     % peaks
     cutOff = numel(aif);
     
     
     func = @(p0, time) localConvFermiFFT(p0, time, aif, cutOff);
     
     
     [popt, resnorm,~,exitflag, output] = lsqcurvefit(func, p0, time, ct(1:cutOff), lb, ub);
     [fitCt, r] = localConvFermiFFT(popt, time, aif, cutOff);
     
     
     % r(t) = F / (exp((t-t0) * k) + 1)
     % a t = 0
     % r(t = 0) = F / (exp(-t0 * k) + 1)
     %  => F = r(t = 0) * (exp(-t0 * k) + 1)
     %
     mbf = r(1) * (exp(-popt(2) * popt(1)) + 1);
     % mtt = sum r(t) = mbv / mbf
     % => mbv = mtt * mbf = sum(r(t)) * mbf
     mbv = sum(r) .* (time(2) - time(1)) * mbf;
     cprintf('DGreen', 'fitFermiFFT: optimal parameters\n');
%      cprintf('DGreen',   '\tF:  %f,\n\tk:  %f\n\tt0: %d\n\ttd: %f\n', popt(1), popt(2), popt(3), popt(4));
     cprintf('DGreen',   '\tA:  %f,\n\tk:  %f\n\tt0: %d\n\t\n', popt(1), popt(2), popt(3));
 end

 function [ctFit, r] = localConvFermiFFT(p0, time, aif, cutOff)
     
     dt = time(2) - time(1);
     %residue function (causal) Jerosch-Herold
     A = p0(1); k = p0(2); t0 = p0(3); %td = p0(4); 
     
     r = (A ./ (exp((time - t0) * k)  + 1)) .* (time >= 0);
     residueLen = numel(r);
     aifLen = numel(aif);
     
     totalLen = residueLen + aifLen; 
     ctFit = ifft(fft(aif, totalLen) .* fft(r, totalLen), 'symmetric');
     ctFit = dt .* ctFit(1 : cutOff);
 end%localConvFermiFFT
 
 function cutOffPos = localFindCutOff(aif)
    maxPos = find(aif == max(aif(:)));
    %maxPosRecirc = maxPos + find(aif(maxPos : end) == max(aif(maxPos : end)));
    cutOffPos = floor(maxPos + find(aif(maxPos : end) == min(aif(maxPos : end))) * 1.0);
 end%localFindCutOff