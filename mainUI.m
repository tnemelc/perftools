%> @file mainUI.m
%> @brief: entry point of perfTool software. This function loads
%> main and plugins configuration and starts UI main window.
%
%> @author: C.Daviller
%> @date: 14-Feb-2017 

 function  mainUI()
clc
close all; clear all;


mainConfig = xml2struct(fullfile(getenv('perfusionTool'), 'config', 'mainConfig.xml'));
pluginConfig = xml2struct(mainConfig.mainConfig.pluginConfigPath.Text);
nbPlugins =  numel(pluginConfig.pluginList.plugin);

%% debug path
setGlobalDebugPath(mainConfig.mainConfig.debugPath.Text);

%% HMI
fm = figureMgr.getInstance();
hFig = fm.newFig('deconvTool');
fm.resize('deconvTool', 3, 3);
set( gcf, 'toolbar', 'figure' )

lin = 0.95;
col = 0.1 : (0.9 - 0.1) / nbPlugins : 0.9;

%% setRibon
setRibon();

%% inner function
%> @brief create plugins lancher buttons from config files
%> @param focusedBnStr 
     function bn = setRibon(focusedBnStr)
         for k = 1 : nbPlugins
             tooltipStr =  sprintf('version: %s\nbrief: %s\nauthor: %s',...
                                pluginConfig.pluginList.plugin{k}.version.Text, ...
                                pluginConfig.pluginList.plugin{k}.brief.Text, ...
                                pluginConfig.pluginList.plugin{k}.author.Text);
             bn.(pluginConfig.pluginList.plugin{k}.name.Text) = ...
             uicontrol('Style', 'pushbutton',...
                 'Units','normalized',...
                 'Position', [col(k) lin (0.9 - 0.1) / nbPlugins 0.05],...
                 'String', pluginConfig.pluginList.plugin{k}.name.Text,...
                 'Callback', {@initPluginCb, pluginConfig.pluginList.plugin{k}}, ...
                 'TooltipString', tooltipStr);
         end
         if nargin
             set(bn.(focusedBnStr), 'BackgroundColor', ones(1,3) * 0.7);
         end
     end

%% callback 
%> @brief  plugin launcher callback function
%> @param pluginInfo plugin data struct required for plugin to be launched
     function initPluginCb(~, ~, pluginInfo)
         fm.closeAllBut('deconvTool');
         clf(hFig);
         setRibon(pluginInfo.name.Text);
         fUI = eval([pluginInfo.UIClass.Text '.getInstance()']);
         fUI = fUI.initialize(hFig, pluginInfo, mainConfig.mainConfig);
     end%initPluginCb

end