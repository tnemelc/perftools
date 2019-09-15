% xmlPatientRoiMbf2csv.m
% brief: gather MBF calculated by deconvPatientsRoiList and restores them input
% in csv format
%
%
%
% keywords:
% author: C.Daviller
% date: 22-Nov-2018 


 function [arg3, arg4] = xmlPatientRoiMbf2csv(arg1, arg2)

    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\0000_Results';
    root = xml2struct('D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\0000_Results\deconvPatientRoiList.xml');
    
    lesionPatientSet = {
            '0001_ARGE', '0002_FACL', '0003_CHAL', ...
            '0004_JUMI', '0005_COJE', '0006_THRO', ...
            '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
            '0015_ROJE', '0018_SALI', '0019_GRIR', ...
            '0021_CUCH', '0022_HODO', '0024_IBOU', ...
            '0027_CRCH', '0029_HURO', '0030_MARE', ...
            '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
            '0042_BELA', '0048_BUJA', '0049_POAI', ...
            '0050_BRFR', '0052_CLYV', '1001_BODA', ...
            '1002_NEMO'};

    
    patientSet = lesionPatientSet;

    
    baseMbfStr = '';
    midMbfStr = '';
    apexMbfStr = '';
    for k = 1 : length(patientSet)
        baseMbfStr = sprintf('%s;%s', baseMbfStr, root.patients.(patientSet{k}(6:end)).base.mbf.Text);
        midMbfStr = sprintf('%s;%s', midMbfStr, root.patients.(patientSet{k}(6:end)).mid.mbf.Text);
        apexMbfStr = sprintf('%s;%s', apexMbfStr, root.patients.(patientSet{k}(6:end)).apex.mbf.Text);
    end
    
    
    fid = fopen(fullfile(rootPath, 'deconvPatientRoiList.csv'), 'w');
    try
        fprintf(fid, '%s\n,%s\n,%s\n', baseMbfStr, midMbfStr, apexMbfStr);
    catch
        logger.getInstance().err('error writting file');
    end
    
    fclose(fid);
    system(sprintf('D:\\Programmes\\Notepad++\\notepad++.exe %s &', fullfile(rootPath, 'deconvPatientRoiList.csv')));
end