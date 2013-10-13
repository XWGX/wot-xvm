package net.wg.gui.cyberSport.views.unit
{
   import flash.display.MovieClip;
   import net.wg.gui.cyberSport.controls.SlotDropIndicator;
   import net.wg.gui.cyberSport.controls.GrayTransparentButton;
   import flash.text.TextField;
   import net.wg.gui.components.controls.VoiceWave;
   import scaleform.clik.events.ButtonEvent;
   import net.wg.gui.cyberSport.controls.events.CSComponentEvent;
   import net.wg.infrastructure.events.VoiceChatEvent;
   import scaleform.clik.constants.InvalidationType;
   import net.wg.gui.prebattle.squad.MessengerUtils;


   public class SlotRenderer extends SimpleSlotRenderer
   {
          
      public function SlotRenderer() {
         super();
      }

      public static const STATUS_NORMAL:String = "normal";

      public static const STATUS_CANCELED:String = "canceled";

      public static const STATUS_READY:String = "ready";

      public static const STATUS_BATTLE:String = "inBattle";

      public static const STATUS_LOCKED:String = "locked";

      public static const STATUS_COMMANDER:String = "commander";

      public static const STATUSES:Array = [STATUS_NORMAL,STATUS_CANCELED,STATUS_READY,STATUS_BATTLE,STATUS_LOCKED,STATUS_COMMANDER];

      public var statusIndicator:MovieClip;

      public var dropTargerIndicator:SlotDropIndicator = null;

      public var removeBtn:GrayTransparentButton;

      public var levelLbl:TextField;

      public var voiceWave:VoiceWave = null;

      override public function dispose() : void {
         this.removeBtn.removeEventListener(ButtonEvent.CLICK,this.onRemoveClick);
         this.removeBtn.dispose();
         vehicleBtn.removeEventListener(CSComponentEvent.CHOOSE_VEHICLE,this.onChooseVehicleClick);
         App.voiceChatMgr.removeEventListener(VoiceChatEvent.START_SPEAKING,this.speakHandler);
         App.voiceChatMgr.removeEventListener(VoiceChatEvent.STOP_SPEAKING,this.speakHandler);
         this.voiceWave.dispose();
         this.voiceWave = null;
         super.dispose();
      }

      public function highlightSlot(param1:Boolean) : void {
         this.dropTargerIndicator.alpha = index > 0 && (param1)?1:0;
      }

      override protected function configUI() : void {
         super.configUI();
         this.voiceWave.visible = App.voiceChatMgr.isVOIPEnabledS();
         App.voiceChatMgr.addEventListener(VoiceChatEvent.START_SPEAKING,this.speakHandler);
         App.voiceChatMgr.addEventListener(VoiceChatEvent.STOP_SPEAKING,this.speakHandler);
         this.removeBtn.addEventListener(ButtonEvent.CLICK,this.onRemoveClick);
         vehicleBtn.addEventListener(CSComponentEvent.CHOOSE_VEHICLE,this.onChooseVehicleClick);
      }

      override protected function draw() : void {
         super.draw();
         if(InvalidationType.DATA)
         {
            if(slotData)
            {
               this.setStatus(slotData.playerStatus);
               this.levelLbl.text = String(slotData.selectedVehicleLevel);
               this.levelLbl.alpha = slotData.selectedVehicleLevel?1:0.33;
               if(!slotData.isClosed)
               {
                  if(slotData.isCommanderState)
                  {
                     this.removeBtn.visible = index > 0 && (slotData.player);
                  }
                  else
                  {
                     this.removeBtn.visible = (slotData.player) && (slotData.player.isSelf);
                  }
                  this.statusIndicator.visible = true;
               }
               else
               {
                  this.removeBtn.visible = false;
                  this.statusIndicator.visible = false;
               }
               if(slotData.player)
               {
                  this.setSpeakers(slotData.player.isPlayerSpeaking,true);
               }
            }
            this.updateVoiceWave();
         }
      }

      override protected function initControlsState() : void {
         super.initControlsState();
         this.setStatus(0);
         this.levelLbl.mouseEnabled = false;
         this.removeBtn.visible = false;
         this.levelLbl.visible = true;
         this.levelLbl.text = "0";
         this.levelLbl.alpha = 0.33;
      }

      private function setStatus(param1:int) : String {
         var _loc2_:String = STATUS_NORMAL;
         if(index == 0)
         {
            _loc2_ = STATUS_COMMANDER;
         }
         else
         {
            if(param1 < STATUSES.length && (param1))
            {
               _loc2_ = STATUSES[param1];
            }
         }
         this.statusIndicator.gotoAndStop(_loc2_);
         return _loc2_;
      }

      private function onRemoveClick(param1:ButtonEvent) : void {
         var _loc2_:Number = (slotData) && (slotData.player)?slotData.player.databaseID:-1;
         dispatchEvent(new CSComponentEvent(CSComponentEvent.LEAVE_SLOT_REQUEST,_loc2_));
      }

      private function onChooseVehicleClick(param1:CSComponentEvent) : void {
         param1.preventDefault();
         param1.stopImmediatePropagation();
         if(((slotData) && (slotData.player)) && (slotData.player.isSelf) && !slotData.player.readyState)
         {
            dispatchEvent(new CSComponentEvent(CSComponentEvent.CHOOSE_VEHICLE,slotData.player.databaseID));
         }
      }

      private function speakHandler(param1:VoiceChatEvent) : void {
         this.onPlayerSpeak(param1.getAccountDBID(),param1.type == VoiceChatEvent.START_SPEAKING);
      }

      public function onPlayerSpeak(param1:Number, param2:Boolean) : void {
         if((slotData) && (slotData.player) && param1 == slotData.player.databaseID)
         {
            this.setSpeakers(param2);
         }
      }

      protected function updateVoiceWave() : void {
         this.voiceWave.visible = App.voiceChatMgr.isVOIPEnabledS();
         this.voiceWave.setMuted((slotData) && (slotData.player)?MessengerUtils.isMuted(slotData.player):false);
      }

      protected function setSpeakers(param1:Boolean, param2:Boolean=false) : void {
         if(param1)
         {
            param2 = false;
         }
         if(this.voiceWave  is  VoiceWave)
         {
            this.voiceWave.setSpeaking(param1,param2);
         }
      }
   }

}