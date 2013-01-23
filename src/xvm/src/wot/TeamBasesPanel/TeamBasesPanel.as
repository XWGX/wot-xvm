/**
 * @author ilitvinov
 */

import wot.TeamBasesPanel.CapConfig;
import wot.utils.Utils;

/**
* Creates and manages CaptureBar instances.
*/

class wot.TeamBasesPanel.TeamBasesPanel extends net.wargaming.ingame.TeamBasesPanel
{
    public function TeamBasesPanel() 
    {
        Utils.TraceXvmModule("TeamBasesPanel");
        super();
    }
    
    function add(id, sortWeight, capColor, title, points)
    {
        if (CapConfig.enabled)
        {
            /**
            * null, null args somehow allow to set XVM-specific vals
            * at the very first moment capture bar appears.
            * 
            * Passing original values make text properties original
            * at that first moment.
            */
            super.add(id, sortWeight, capColor, null, null);
            /**
            * This array is defined at parent original WG class.
            * start() is XVMs method at CaptureBar class.
            */
            captureBars[indexByID[id]].start(points, capColor);
        }
        else
        {
            super.add(id, sortWeight, capColor, title, points);
        }
    }
    
  /**
   * Called when point becomes fully captured.
   */
   function setCaptured(id, title)
   {
       if (CapConfig.enabled)
       {
           /**
            * No need to define behavior. updateProgress() handles full capture.
            * Leave empty.
            */
       }
       else
       {
           super.setCaptured(id, title);
       }
   }
}
