import flash.geom.Point;
import wot.utils.Config;

class wot.Minimap.model.MapConfig
{
    public static function get enabled():Boolean    {
        return Config.s_config.minimap.enabled;    }
    
    public static function get iconScale():Number    {
        return Config.s_config.minimap.iconScale;    }
    
    public static function get isDeadPermanent():Boolean    {
        return Config.s_config.minimap.isDeadPermanent;    }
        
    public static function get nickShrink():Number    {
        return Config.s_config.minimap.nickShrink;    }
        
    public static function get formatAlly():String    {
        return Config.s_config.minimap.format.ally;    }
    public static function get formatEnemy():String    {
        return Config.s_config.minimap.format.enemy;    }
    public static function get formatSquad():String    {
        return Config.s_config.minimap.format.squad;    }
    public static function get formatOneself():String    {
        return Config.s_config.minimap.format.oneself;    }
        
    public static function get cssAlly():String    {
        return Config.s_config.minimap.css.ally;    }
    public static function get cssEnemy():String    {
        return Config.s_config.minimap.css.enemy;    }
    public static function get cssSquad():String    {
        return Config.s_config.minimap.css.squad;    }
    public static function get cssOneself():String    {
        return Config.s_config.minimap.css.oneself;    }
        
    public static function get textOffset():Point    {
        return new Point(Config.s_config.minimap.textOffsetX, Config.s_config.minimap.textOffsetY);}
}