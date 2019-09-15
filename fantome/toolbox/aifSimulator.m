% aifSimulator.m
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
% keywords: DataPrep, aif, clinical
% author: C.Daviller
% date: 13-Dec-2017  


 function [arg3, arg4] = aifSimulator(opt);%A1, A2, A3, A4, T1, T2, T3, T4, sigma1, sigma2, s, w4, beta)
%  if ~nargin
% 	aifSimulatorUI();
%  return;
%  end 
 
 rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE';
 patientKS  = {'Arthaud', 'Boncompain', 'Chassard', 'Coco_jean', 'Delahais', 'Faure', 'Jurine', 'Neyme', 'Outters', 'Rivolier', 'Sarda', 'Thioliere'};

 aifTab = zeros(length(patientKS), 100);
 aifColor = [0 127 0] ./ 256;
 for k = 1 : length(patientKS)
        patientName = char(patientKS(k));
        tmp = loadmat(fullfile(rootPath, patientName, 'dataPrep\Aif\aifCtcFit.mat'));
        pkPos(k) = find(tmp == max(tmp), 1, 'first');
        aifTab(k, 1:length(tmp)) = tmp;  
 end

 %find the greatest TTP
 pkPosDiff = max(pkPos) - pkPos;
 %shift aif to synchronize them on their peaks by zero padding
 for k = 1 : length(patientKS)
     tmp = zeros(1, 100);
     tmp(pkPosDiff(k) + 1 : pkPosDiff(k) + 70) = aifTab(k, 1:70);
     aifTab(k, :) = tmp;   
 end
 
 for k = 1 : 100
     upBnd(k) = max(aifTab(:, k));
     meanAif(k) = mean(aifTab(:, k));
     lwBnd(k) = min(aifTab(:, k));
 end
 

 
 %get target syncronization patient time acq vector

 tAcq = loadmat(fullfile(rootPath, char(patientKS(find(pkPosDiff == 0))), 'dataPrep\Aif\tAcq.mat'));
 tSim = 0 : 0.01 : tAcq(end);
 figureMgr.getInstance().newFig('aifSimu');
 fillPlot(tAcq', lwBnd(1:length(tAcq))', upBnd(1:length(tAcq))', aifColor);
 hold on; plot(tAcq, meanAif(1:length(tAcq)), 'o', 'color', aifColor);
 xlabel('time (s)'); ylabel('[Gd] mmol/L');
 
 
 
 F = @(p, tSimu) ( max(meanAif(:)) .* exp(-(tSimu - p(2)).^2 / (2 * p(3)^2)) + ...
                   p(4) .* exp(-(tSimu - p(5)).^2 / (2 * p(6)^2)) ) ; 
               
 %cost function
 weightVector = ones(1, length(tAcq));
 costFunction = @(A, tSimu) weightVector.*(yourModelFunction(A) - y);
 
 
 p0 = [max(meanAif(:)), tAcq(meanAif == max(meanAif(:))), 3, max(meanAif(:))/10, 45, 10];
 plw = [max(lwBnd(:)), tAcq(meanAif == max(meanAif(:))) - 2, 0.1, max(meanAif(:))/15, 35, 0.01];
 pup = [max(upBnd(:)), tAcq(meanAif == max(meanAif(:))) + 2, 5, max(meanAif(:))/5, 60, 15];
 
 
% plot(tAcq, p0(1) .* exp(-(tAcq - p0(2)).^2 / (2 * p0(3)^2)));
% plot(tAcq, p0(4) .* exp(-(tAcq - p0(5)).^2 / (2 * p0(6)^2)));
%  f2 = opt.A2 .* exp(-(tSim - opt.T2).^2 / (2 * opt.sigma2^2)) ;
 
 [popt, resnorm,~,exitflag, output] = lsqcurvefit(F, p0, tSim, interp1(tAcq, meanAif(1:length(tAcq)), tSim, 'linear', 'extrap'), plw, pup);
 
 aifOptim =  F(popt, tSim);
 
 
% %  %simulate AIF
%  f1 = opt.A1 .* exp(-(tSim - opt.T1).^2 / (2 * opt.sigma1^2)) ;
%  f2 = opt.A2 .* exp(-(tSim - opt.T2).^2 / (2 * opt.sigma2^2)) ;
%  f3 = opt.A3 .* exp(-opt.beta.*(tAcq - opt.T3))./ (1 + exp(-opt.s.*(tAcq - opt.T3)));
%  f4 = opt.A4 .* abs(sin((tAcq - opt.T4) .* opt.w4)) .* (tAcq >= opt.T4);
%  aifSimu = f1 + f2;% + f3 + f4;

 plot(tSim, aifOptim, '--', 'color', [0 127 0] ./ 256 );
%  hold on; plot(tAcq, aifSimu, '--r');
%  
 
  optParam.A1 = popt(1); optParam.T1 = popt(2); optParam.sigma1 =  popt(3);
  optParam.A2 = popt(4); optParam.T2 = popt(5); optParam.sigma2 =  popt(6);
  root.optimalParam = optParam;
  struct2xml(root, 'D:\02_Matlab\Data\SignalSimulation\aifShaper\aifParams.xml');
  savemat('D:\02_Matlab\Data\SignalSimulation\aifShaper\aifSimu', interp1(tSim, aifOptim, tAcq, 'linear', 'extrap'));
  savemat('D:\02_Matlab\Data\SignalSimulation\aifShaper\tAcq', tAcq);
  savemat('D:\02_Matlab\Data\SignalSimulation\aifShaper\opt', optParam);

end