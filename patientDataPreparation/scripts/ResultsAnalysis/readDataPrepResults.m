% readDataPrepResults.m
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
% date: 13-Dec-2017  


 function  readDataPrepResults(dataPath)
 if ~nargin
	readDataPrepResultsUI();
 return;
 end 
 
 if isempty(strfind(dataPath, 'aif'))
     
     data = loadmat(fullfile(dataPath, 'baselineLengthMap'));
     blLen = mean(data(data > 0));
     fprintf('average baseline length: %0.02f\n',  blLen);
     
     data = loadmat(fullfile(dataPath, 'baselineSigmaMap'));
     fprintf('average baseline standard devitation: %0.08f\n',  mean(data(data > 0)));
     
     data = loadmat(fullfile(dataPath, 'ctcSet'));
     tAcq = loadmat(fullfile(dataPath, 'tAcq'));
     nbAcq = find(tAcq >= blLen, 1, 'first');
     
     mask = loadmat(fullfile(dataPath, 'mask'));
     pos = find(mask > 0);
     
     for k = 1 : nbAcq
        curImg = data(:, :, k);
        values = curImg(pos(:));
        baselineAvg(k) = mean(values(:));
     end
     fprintf('average myocardium baseline standard devitation: %0.08f\n',  std(baselineAvg));
     
 else
     data = loadmat(fullfile(dataPath, 'aifCtc'));
     fprintf('aif peak value: %f\n',  max(data(:)));
 end
end