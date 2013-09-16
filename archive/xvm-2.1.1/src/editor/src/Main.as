﻿import components.GroupComponent;

import helpers.ConfigHelper;

import mx.collections.HierarchicalData;
import mx.controls.ColorPicker;
import mx.utils.ObjectUtil;

import utils.UIUtils;

private var dp:Array;

private var activeBehaviors:Array;
private function PopulateValue(path:String):*
{
	var paths:Array = activeBehaviors.map(
		function(o:*, i:int, a:Array):String { return String(o) + "/" + path; });
	var activeValues:Array = [];
	for each (var path:String in paths)
		activeValues.push(ConfigHelper.GetConfigValue(config, path));

	if (activeValues.length > 0)
	{
		var ok:Boolean = true;
		var value:* = activeValues.pop();
		for each (var v:* in activeValues)
		{
			if (v != value)
			{
				ok = false;
				break;
			}
		}
		return ok ? value : undefined;
	}
}

private function ChangeValue(xmlpaths:Array, value:*):void
{
	//d.text += "ChangeValue()\n";
	try
	{
		for each (var path:String in xmlpaths)
			ConfigHelper.SetConfigValue(config, path, value);
	}
	catch (ex:Error)
	{
		d.text += "ChangeValue(): " + ex.toString() + "\n";
	}
	//d.text = ObjectUtil.toString(config) + "\n";
}

private function ChangeMarkerValue(xmlpath:String, value:*):void
{
	d.text += "ChangeMarkerValue(" + xmlpath + "," + String(value) + ")\n";
	try
	{
		var paths:Array = getActiveBehaviors().map(
			function(o:*, i:int, a:Array):String { return String(o) + "/" + xmlpath; });

		ChangeValue(paths, value);
		RefreshMarkers();
	}
	catch (ex:Error)
	{
		d.text += "ChangeMarkerValue(): " + ex.toString() + "\n";
	}
}

// recursively find all active behaviors
private function getActiveBehaviors(comps:Array = null):Array
{
	if (comps == null)
		comps = [null, gPlayer, gStatus, gView, gElements];

	var comp:GroupComponent = comps.pop() as GroupComponent;

	if (comp == null)
		return [ "behaviors" ];

	var active:Array = comp.getActivePaths();

	var res:Array = [];
	for each (var r:String in getActiveBehaviors(comps))
	{
		for each (var a:String in active)
		  res.push(r + "/" + a);
	}

	return res;
}