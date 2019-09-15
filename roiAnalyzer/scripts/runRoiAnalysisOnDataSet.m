% runRoiAnalysisOnDataSet.m
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
% date: 17-Apr-2018 


 function runRoiAnalysisOnDataSet()
 rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering';
 
 PatientList =  {
        '0001_ARGE', '0002_FACL', '0003_CHAL', ...
        '0004_JUMI', '0005_COJE', '0006_THRO', ...
        '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
        '0015_ROJE', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0022_HODO', '0024_IBOU', ...
        '0027_CRCH', '0029_HURO', '0030_MARE', ...
        '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
        '0042_BELA', '0045_TICH', '0048_BUJA', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO', '1003_GAJE'};
 
    tic
 for k = 1 : length(PatientList)
     toolOptions.dataPath = fullfile(rootPath, PatientList{k});
     roiAnlzrTool = kMeanStrgRoiAnalyzerTool();
     roiAnlzrTool = roiAnlzrTool.prepare(toolOptions);
     roiAnlzrTool = roiAnlzrTool.run();
     
     savePath = fullfile(rootPath, PatientList{k}, 'roiAnalyzer', 'strg');
     savePatientResults(roiAnlzrTool, savePath);

 end
 fprintf('done in %dsec\n', round(toc));
 
 
 
 end
 
 function savePatientResults(roiAnlzrTool, savePath)
     try
         xml.root.date = date;
         xml.root.aif.ticFoot = roiAnlzrTool.getAifFeature('footPos');
         xml.root.aif.baselineLength = roiAnlzrTool.getAifFeature('footDate');
         xml.root.aif.firstPassEndDate = roiAnlzrTool.getAifFeature('firstPassEndDate');
         isKS = roiAnlzrTool.getSeriesKS();
         for k = 1 : length(isKS)
             isName = isKS{k};
             roisMask = roiAnlzrTool.getRoisMask(isName);
             xml.root.(isName).nbRoi = max(roisMask(:));
             peakValMask = roiAnlzrTool.getFeaturesMask('roiTicPeakVal', isName);
             ttpMask = roiAnlzrTool.getFeaturesMask('roiTicTtp', isName);
             aucMask = roiAnlzrTool.getFeaturesMask('roiTicAuc', isName);
             maxSlopeMask = roiAnlzrTool.getFeaturesMask('roiTicMaxSlope', isName);
             maxSlopePosMask = roiAnlzrTool.getFeaturesMask('roiTicMaxSlopePos', isName);
             delayMask = roiAnlzrTool.getFeaturesMask('roiTicDelay', isName);

             for m = 1 : max(roisMask(:))
                 val = peakValMask(roisMask == m);
                 xml.root.(isName).roi{m}.peakVal = val(1);
                 val = ttpMask(roisMask == m);
                 xml.root.(isName).roi{m}.ttp = val(1);
                 val = aucMask(roisMask == m);
                 xml.root.(isName).roi{m}.auc = val(1);
                 val = maxSlopeMask(roisMask == m);
                 xml.root.(isName).roi{m}.maxSlope = val(1);
                 val = maxSlopePosMask(roisMask == m);
                 xml.root.(isName).roi{m}.maxSlopePos = val(1);
                 val = delayMask(roisMask == m);
                 xml.root.(isName).roi{m}.delay = val(1);
             end
         end
         struct2xml(xml, fullfile(savePath, 'summary.xml'));
     catch e
         rethrow(e);
     end
 end%saveCb(obj)