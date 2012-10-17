﻿package preview
{

import com.greensock.OverwriteManager;
import com.greensock.plugins.*;

import preview.*;
import preview.damage.*;

import utils.*;

/*
 * XVM() instance creates corresponding marker
 * each time some player gets in line of sight.
 * Instantiated 14 times at normal round start.
 * Destructed when player get out of sight.
 * Thus may be instantiated ~50 times and more.
 */

public class Xvm extends XvmBase
{
    /**
     * .ctor()
     * @param	proxy Parent proxy class (for placing UI Components)
     */
    function Xvm(proxy:Marker)
    {
        super(); // gfx.core.UIComponent
        _proxy = proxy;

        // initialize TweenLite
        OverwriteManager.init(OverwriteManager.AUTO);
        TweenPlugin.activate([AutoAlphaPlugin, BevelFilterPlugin, BezierPlugin, BezierThroughPlugin, BlurFilterPlugin,
            CacheAsBitmapPlugin, ColorMatrixFilterPlugin, ColorTransformPlugin, DropShadowFilterPlugin, EndArrayPlugin,
            FrameBackwardPlugin, FrameForwardPlugin, FrameLabelPlugin, FramePlugin, GlowFilterPlugin,
            HexColorsPlugin, QuaternionsPlugin, RemoveTintPlugin, RoundPropsPlugin, ScalePlugin, ScrollRectPlugin,
            SetSizePlugin, ShortRotationPlugin, TintPlugin, TransformMatrixPlugin, VisiblePlugin, VolumePlugin]);
    }

    /**
     * IVehicleMarker implementation
     */

    /**
     * @see IVehicleMarker
     */
    function init(vClass, vIconSource, vType, vLevel, pFullName,
        curHealth, maxHealth, entityName, speaking, hunt, entityType)
    {
        m_playerFullName = pFullName; // alex

        trace("Xvm::init(): " + entityName + ", " + entityType);

        m_defaultIconSource = vIconSource; // ../maps/icons/vehicle/contour/usa-M48A1.png
        m_source = vIconSource;
        m_entityName = entityName; // ally, enemy, squadman, teamKiller
        m_entityType = entityType; // ally, enemy
        m_maxHealth = maxHealth;

        m_vname = vType; // AMX50F155
        m_level = vLevel;
        m_speaking = speaking;

        m_isDead    = curHealth <= 0; // -1 for ammunition storage explosion
        m_curHealth = curHealth >= 0 ? (curHealth) : (0);

        vehicleState = new VehicleState(new VehicleStateProxy(this));

        healthBarComponent = new HealthBarComponent(new HealthBarProxy(this));
        clanIconComponent = new ClanIconComponent(new ClanIconProxy(this));
        contourIconComponent = new ContourIconComponent(new ContourIconProxy(this));
        levelIconComponent = new LevelIconComponent(new LevelIconProxy(this));
        vehicleTypeComponent = new VehicleTypeComponent(new VehicleTypeProxy(this), vClass /*mediumTank*/, hunt);
        damageTextComponent = new DamageTextComponent(new DamageTextProxy(this));

        // Create clan icon and place to mc.
        clanIconComponent.m_clanIcon.source = m_entityType == "enemy" ? new Resources.IMG_clan2() : new Resources.IMG_clan1();

        // Initialize states and creating text fields
        initializeTextFields();

        // Draw marker
        XVMUpdateStyle();
    }

    /**
     * @see IVehicleMarker
     */
    function update()
    {
        trace("Xvm::update()");
        XVMUpdateStyle();
    }

    /**
     * @see IVehicleMarker
     */
    function setEntityName(value)
    {
        trace("Xvm::setEntityName(" + value + ")");
        if (value == m_entityName)
            return;
        m_entityName = value;
        initializeTextFields();
        XVMUpdateStyle();
    }

    /**
     * @see IVehicleMarker
     */
    function updateHealth(newHealth:Number, flag:Number, damageType:String):void
    {
        /*
         * newHealth:
         *  1497, 499, 0 and -1 in case of ammo blow up
         * flag - int:
         * 0 - "FROM_UNKNOWN", 1 - "FROM_ALLY", 2 - "FROM_ENEMY", 3 - "FROM_SQUAD", 4 - "FROM_PLAYER"
         *
         * damageType - string:
         *  "attack", "fire", "ramming", "world_collision", "death_zone", "drowning", "explosion"
         */

        //Logger.add("Xvm::updateHealth(" + flag + ", " + damageType + ", " + newHealth +")");

        m_isDead = newHealth <= 0;

        var delta: Number = newHealth - m_curHealth;
        m_curHealth = m_isDead ? 0 : newHealth; // fixes "-1"

        if (delta < 0) // Damage has been done
        {
            // markers{ally{alive{normal
            var vehicleStateCfg:Object = vehicleState.getCurrentConfig();

            healthBarComponent.updateState(vehicleStateCfg);
            healthBarComponent.showDamage(vehicleStateCfg, newHealth, m_maxHealth, -delta);

            damageTextComponent.showDamage(vehicleStateCfg.damageText, newHealth, -delta, flag, damageType);
        }

        XVMUpdateDynamicTextFields();
    }

    /**
     * @see IVehicleMarker
     */
    function updateState(newState, isImmediate)
    {
        trace("Xvm::updateState(" + newState + ", " + isImmediate + "): " + vehicleState.getCurrentState());

//        if (!initialized)
//            ErrorHandler.setText("updateState: !initialized");

        m_isDead = newState == "dead";

        XVMUpdateStyle();
    }

    /**
     * @see IVehicleMarker
     */
    function showExInfo(show)
    {
        //trace("Xvm::showExInfo()");
        if (m_showExInfo == show)
            return;
        m_showExInfo = show;

        XVMUpdateStyle();
    }

    /**
    * MAIN
    */

    function XVMUpdateDynamicTextFields()
    {
        try
        {
            if (textFields)
            {
                var st = vehicleState.getCurrentState();
                for (var i in textFields[st])
                {
                    var tf = textFields[st][i];
                    //tf.field.text = formatDynamicText(tf.format, m_curHealth);
                    //tf.field.textColor = formatDynamicColor(tf.color, m_curHealth);
                    tf.field.htmlText = "<textformat leading='-2'><p class='xvm_markerText'>" +
                        formatDynamicText(tf.format, m_curHealth) + "</p></textformat>";
                    tf.field._alpha = formatDynamicAlpha(tf.alpha, m_curHealth);
                }
            }
        }
        catch (e)
        {
//            ErrorHandler.setText("ERROR: XVMUpdateDynamicTextFields():" + String(e));
        }
    }

    function initializeTextFields()
    {
        //trace("Xvm::initializeTextFields()");
        try
        {
            // cleanup
            if (textFields)
            {
                for (var st in textFields)
                {
                    for (var i in textFields[st])
                    {
                        var tf = textFields[st][i];
                        tf.field.removeTextField();
                        tf.field = null;
//                        delete tf;
                    }
                }
            }

            textFields = { };
            var allStates = vehicleState.getAllStates();
            for (var stid in allStates)
            {
                var st = allStates[stid];
                var cfg = vehicleState.getConfig(st);

                // create text fields
                var fields: Array = [];
                for (var i in cfg.textFields)
                {
                    if (cfg.textFields[i].visible)
                    {
                        //if (m_team == "ally")
                        //    Logger.addObject(cfg.textFields[i], m_vname + " " + m_playerFullName + " " + st);
                        //if (m_team == "enemy")
                        //    Logger.addObject(cfg.textFields[i], m_vname + " " + m_playerFullName + " " + st);
                        fields.push(createTextField(cfg.textFields[i]));
                    }
                }
                textFields[st] = fields;
            }
        }
        catch (e)
        {
//            ErrorHandler.setText("ERROR: initializeTextFields():" + String(e));
        }
    }

    function XVMUpdateStyle()
    {
        //trace("XVMUpdateStyle: " + m_playerFullName + m_vname + " " + " scale=" + proxy.marker._xscale);
        try
        {
            //var start = new Date(); // for debug

            var cfg = vehicleState.getCurrentConfig();

            // Vehicle Type Marker
            vehicleTypeComponent.updateState(cfg);

            // Contour Icon
            contourIconComponent.updateState(cfg);

            // Level Icon
            levelIconComponent.updateState(cfg);

            // Action Marker
//            actionMarkerComponent.updateState(cfg);

            // Clan Icon
            clanIconComponent.updateState(cfg);

            // Damage Text
            damageTextComponent.updateState(cfg);

            // Health Bar
            healthBarComponent.updateState(cfg);

            // Text fields
            if (textFields)
            {
                var st = vehicleState.getCurrentState();
                for (var i in textFields)
                {
                    for (var j in textFields[i])
                        textFields[i][j].field._visible = (i == st);
                }
            }

            // Update Colors and Values
            XVMUpdateDynamicTextFields();
        }
        catch (e)
        {
//            ErrorHandler.setText("ERROR: XVMUpdateStyle():" + String(e));
        }
    }
}

}
