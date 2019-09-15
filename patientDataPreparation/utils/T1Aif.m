% T1Aif.m
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
% date: 06-Sep-2017


function t1Map = T1Aif(pdScanAvg, imSerie, mask, t1Vect)
if ~nargin
    T1AifUI();
    return;
end
% td is locked to 21.5ms
td = 21.5e-3;
[H, W, T] = size(imSerie);
t1Map = zeros(H, W);

for k = 1 : T
    fprintf('processing image %d\n', k);
    for l = 1 : H
        for m = 1 : W
            if mask(l, m)
                if pdScanAvg(l, m) == 0
                    t1Map(l, m, k) = 0;
                else
                    Sth  = theoSignal(td, pdScanAvg(l, m), t1Vect);
                    Sdiff = abs(imSerie(l, m, k) - Sth);
                    %                         fm.newFig('signal difference'); plot(t1Vect, (imSerie(l, m, k) / pdScanAvg(l, m))); hold all; plot(t1Vect, Sdiff);
                    %                         legend('ST1/SPD', 'abs((ST1/SPD) - (num/den))');
                    t1Map(l, m, k) = t1Vect( Sdiff == min(Sdiff));
                end
            end
        end
    end
end

    function sTheo = theoSignal(td, S0, t1)
        sTheo = S0 .* (1 - exp(-td ./ t1));
    end
end