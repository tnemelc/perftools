% fitFermiFFTUI.m
% brief: 
% fitFermiFFT User Interface
% author: C.Daviller
% date: 10-Jan-2018 


 function  fitFermiFFTUI()
    clc;   
%     model = '2CXM';
    model = 'FtKpsVpVe';
    
    params.Fp =    4;%mL/min/g
    params.PS = 0.94;%mL/min/g
    params.vp = 0.1;%mL/g
    params.ve = 0.3;%mL/g
    
    td = 1;%unit: sample
    
    aif = loadmat('D:\02_Matlab\Data\SignalSimulation\aifShaper\aifSimu.mat');
    t = (0 : length(aif) - 1) .* 0.7;
    
    switch model
        case '2CXM'
            [ct, residue] = TwoCXM(aif, t, params, false, true);
        case 'FtKpsVpVe'
            [ct, ~] = DceTool_Model_FtKpsVpVe_LM([params.Fp / 60, params.PS / 60, params.vp, params.ve], t, aif);
            residue = zeros(1, length(ct));
            ct = ct';
    end
    
    ct = [ct(1:td)  ct(1 : end - td)];
    
    figureMgr.getInstance().newFig('fitFermiFFTUI');
    subplot(2, 1, 1); hold all;
    plot(t, aif, 'color', [0.2 0.6 0.2]);
    plot(t, ct, '+', 'color', [1 0.5 0]);
    
    subplot(2, 1, 2); hold on;
    plot(t, residue .* params.Fp / 60, '+', 'color', [0 0 0.8]);
    
    %% fit
    %     F  k   t0
    p0 = [5, 30, 2];
    
    tSim = t(1) : (t(2) - t(1)) * 0.01 : t(end);
    aifSim = interp1(t, aif, tSim, 'linear', 'extrap');
    ctSim  = interp1(t, ct,  tSim, 'linear', 'extrap');
    
    [mbf, mbv, fitCt, r] = fitFermiFFT(aifSim, tSim, ctSim, p0);
    subplot(2, 1, 1);
    plot(tSim(1 : length(fitCt)), fitCt, 'color', [1 0.5 0]);
    
    subplot(2, 1, 2);
    plot(tSim, r, 'color', [0 0 0.8]);
    cprintf('DGreen', 'fitFermiFFTUI results:\n');
    cprintf('DGreen','\tmbf: %f mL/min/g\n\tmbv: %f mL/g\n', mbf * 60, mbv);
end