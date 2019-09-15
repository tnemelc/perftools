classdef roiAnalyzerToolCtc < roiAnalyzerTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        
        %% load ctc set instead of image series
        function obj = loadImSeries(obj)
            for k = 1 : length(obj.isKS);
                serieName = obj.isKS{k};
                imSerie = loadmat(fullfile(obj.dataPath, 'dataPrep', serieName, 'ctcSet'));
                tAcq = loadmat(fullfile(obj.dataPath, 'dataPrep', serieName, 'tAcq'));
                obj.imSerieMap = mapInsert(obj.imSerieMap, serieName, imSerie);
                obj.imSerieTimeAcqMap = mapInsert(obj.imSerieTimeAcqMap, serieName, tAcq);
            end%for
        end
    end
    
end

