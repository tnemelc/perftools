% deconvPatientsRoiList.m
% brief: run deconvolution on patients' ROI average time intensity curves
% only lelsion roi are processed
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
% date: 21-Nov-2018


function [arg3, arg4] = deconvPatientsRoiList(arg1, arg2)
    lgr = logger.getInstance();
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
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
    %methodKS = {'Bayesian', 'Fermi'};
    patientSet = lesionPatientSet;

    for k = 1 : length(patientSet)
        lgr.info(sprintf('patient: %s', patientSet{k}));

        curPatient =  char(patientSet(k));
        patientPath = fullfile(rootPath, curPatient);

        %
        slcKS = {'base', 'mid', 'apex'};

        for n = 1 : length(slcKS)
            lgr.info(sprintf('%s', slcKS{n}));

            roiToolOpt.dataPath = fullfile(rootPath, curPatient);
            roiTool = manualMultiRoiMapDisplayRoiAnalyzerToolCtc;
            roiTool = roiTool.prepare(roiToolOpt);
            roiTool = roiTool.run(roiToolOpt);
            nbRois = max(max(roiTool.getRoisMask(slcKS{n})));

            
            cexp = [];
            for m = 1 : nbRois
                if strncmp('lesion', roiTool.getRoiLabel(slcKS{n}, m), length('lesion'))
                    cexp(:, m) = (roiTool.getRoiAvgTic(slcKS{n}, m))';
                end
            end
            
            deconvToolOpt.timePortion = 1;
            deconvToolOpt.deconvMode = 'patient';
            deconvToolOpt.patchWidth = 1;
            deconvToolOpt.processMeasUncertainty = false;
            deconvToolOpt.aifDataPath = fullfile(patientPath, 'dataPrep', 'Aif');
            deconvToolOpt.dataPath = fullfile(rootPath, curPatient);
            deconvToolOpt.slicePath = fullfile(deconvToolOpt.dataPath, 'dataPrep', slcKS{n});


            deconvTool = deconvToolBayesian;
            deconvTool = deconvTool.prepare(deconvToolOpt);
            out = deconvTool.runCtcSetDeconvolution(cexp);
            lgr.info('bf (ml/min/g):');
            disp(out.bf.em .* 60);
            root.patients.(curPatient(6 : end)).(slcKS{n}).mbf = mean(out.bf.em .* 60);
        end
    end
    
    struct2xml(root, fullfile(rootPath, '0000_Results', 'deconvPatientRoiList.xml'));
    system(sprintf('D:\\Programmes\\Notepad++\\notepad++.exe %s &', fullfile(rootPath, '0000_Results' , 'deconvPatientRoiList.xml')));
end