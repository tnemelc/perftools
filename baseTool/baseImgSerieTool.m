classdef baseImgSerieTool < baseTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        isKS;
        imSerieMap;
        imSerieTimeAcqMap;
        imSeriePathMap;
    end
    
    %%
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.prepare@baseTool(opt);
            obj = obj.setSeriesKeyset();
        end%
        %%
        function obj = run(obj, ~)
            obj = obj.loadImSeries();
        end%run
        %% getters
        %%
        function srKS = getSeriesKS(obj)
            srKS = obj.isKS;
        end%getSeriesKS
        %%
        function imSerie = getImserie(obj, serieName)
            imSerie = obj.imSerieMap(serieName);
        end
        %% 
        function tAcqVect = getTAcqVector(obj, serieName)
            tAcqVect = obj.imSerieTimeAcqMap(serieName);
        end
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = setSeriesKeyset(obj)
            obj.isKS = {'base', 'mid', 'apex'};
            obj.imSeriePathMap = containers.Map(obj.isKS, ...
                {fullfile(obj.dataPath, 'base'),...
                fullfile(obj.dataPath, 'mid'),...
                fullfile(obj.dataPath, 'apex') });
            for k = 1 : 3 % remove possible inexistant directory
                if ~isdir(obj.imSeriePathMap(char(obj.isKS(k))))
                    dirName = obj.imSeriePathMap(char(obj.isKS(k)));
                    dirName(dirName == '\') = '/';
                    obj.lgr.warn(sprintf('no direrctory %s', dirName));
                    remove(obj.imSeriePathMap, char(obj.isKS(k)));
                    continue;
                end
            end
            %remove key with not existing directory
            rmSlcCount = 0;
            for k = 1 : length(obj.isKS)
                if ~obj.imSeriePathMap.isKey(char(obj.isKS(k - rmSlcCount)))
                    obj.isKS(k - rmSlcCount) =  '';
                    rmSlcCount = rmSlcCount + 1;
                end
            end
        end%setSeriesKeyset
        %%
        function obj = loadImSeries(obj)
            for k = 1 : length(obj.isKS);
                serieName = char(obj.isKS(k));
                try
                    imSerie = loadmat(fullfile(obj.dataPath, serieName), 'slcSerie.mat');
                catch
                    try 
                        imSerie = loadDcm(fullfile(obj.dataPath, serieName));
                    catch
                        imSerie = readnifti(fullfile(obj.dataPath, serieName));
                    end
                end
                obj.imSerieMap = mapInsert(obj.imSerieMap, serieName, imSerie);
            end%for
        end%loadSlcSer
        
    end%methods (Access = protected)
end

