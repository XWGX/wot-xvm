/**
 * XVM Test mod
 * @author Maxim Schedriviy <m.schedriviy@gmail.com>
 */
package
{
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.utils.setInterval;
    import com.xvm.Logger;
    import com.xvm.Config;
    import net.wg.infrastructure.interfaces.IView;
    import net.wg.infrastructure.events.LoaderEvent;

    [SWF(width="1", height="1", backgroundColor="#111111")]

    public class TestMod extends MovieClip
    {
        public function TestMod():void
        {
            if (stage)
            {
                init();
            }
            else
            {
                addEventListener(Event.ADDED_TO_STAGE, init);
            }
        }

        private function init(e:Event = null):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);

            // entry point

            Logger.add("testmod running, current view: " + App.containerMgr.lastFocusedView.as_alias);
            //Logger.addObject(App.containerMgr.loader, "loader");

            App.containerMgr.loader.addEventListener(LoaderEvent.VIEW_LOADED, onViewLoaded);

            //dispatchEvent(new net.wg.infrastructure.events.LoaderEvent(net.wg.infrastructure.events.LoaderEvent.VIEW_LOADED, config, token, view));


            try
            {
                //var view:IView = App.instance.containerMgr.lastFocusedView;
                //Logger.add("view: " + (view ? view.as_alias : "(null)"));
                //setInterval(function():void {
                //    view = App.instance.containerMgr.lastFocusedView;
                //    Logger.add("view: " + (view ? view.as_alias : "(null)"));
                //}, 1000);
                //wrapper.version.text = value + "   XVM " + Defines.XVM_VERSION + " (WoT " + Defines.WOT_VERSION + ")";
                //Logger.addObject(Config.config, "config", 10);
            }
            catch (e:*)
            {
                Logger.add(e.getStackTrace());
            }
        }

        private function onViewLoaded(e:LoaderEvent):void
        {
            Logger.add("View loaded: " + e.view.as_alias);
        }
    }
}
