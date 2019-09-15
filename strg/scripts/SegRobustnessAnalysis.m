% SegRobustnessAnalysis.m
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
% date: 14-Nov-2018


function [arg3, arg4] = SegRobustnessAnalysis(arg1, arg2)
clear variables;
    patientSet = {
        '0001_ARGE', '0002_FACL', '0003_CHAL', ...
        '0004_JUMI', '0005_COJE', '0006_THRO', ...
        '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
        '0015_ROJE', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0022_HODO', '0024_IBOU', ...
        '0027_CRCH', '0029_HURO', '0030_MARE', ...
        '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
        '0042_BELA', '0045_TICH', '0048_BUJA', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO', '1003_GAJE', ...
        '1004_GEMI'};

    sliceKS = {'base', 'mid', 'apex'};
    
    
    r = xml2struct('D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\0000_Results\STRGRobustness.xml');
    r = r.patients;
    for k = 1 : length(patientSet)
        curPat = patientSet{k}; curPat = curPat(6 : end);
        for n = 1 : length(sliceKS)
            curSlice = sliceKS{n};
            meanDice.(curSlice)(k) =  str2double(r.(curPat).STRG.(curSlice).mean.Text);
        end
    end

end