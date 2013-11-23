package net.wg.gui.lobby.profile
{
   import net.wg.infrastructure.base.meta.impl.ProfileTabNavigatorMeta;
   import net.wg.infrastructure.base.meta.IProfileTabNavigatorMeta;
   import scaleform.clik.controls.Button;
   import flash.display.MovieClip;
   import net.wg.gui.components.advanced.ButtonBarEx;
   import net.wg.gui.lobby.profile.components.ResizableViewStack;
   import scaleform.clik.events.IndexEvent;
   import net.wg.gui.events.ViewStackEvent;
   import net.wg.infrastructure.interfaces.IDAAPIModule;
   import net.wg.data.Aliases;
   import scaleform.clik.data.DataProvider;
   import scaleform.clik.constants.InvalidationType;


   public class ProfileTabNavigator extends ProfileTabNavigatorMeta implements IProfileTabNavigatorMeta
   {
          
      public function ProfileTabNavigator() {
         this._sectionsDataUtil = new SectionsDataUtil();
         super();
      }

      private static const OFFSET_INVALID:String = "layoutInv";

      private static const INIT_DATA_INV:String = "initDataInv";

      public var btnTemplate:Button;

      public var templatesHolder:MovieClip;

      public var bar:ButtonBarEx;

      public var viewStack:ResizableViewStack;

      private var initData:ProfileMenuInfoVO;

      private var _sectionsDataUtil:SectionsDataUtil;

      private var _centerOffset:int = 0;

      override protected function configUI() : void {
         super.configUI();
         if(this.btnTemplate)
         {
            if(this.btnTemplate.parent)
            {
               this.btnTemplate.parent.removeChild(this.btnTemplate);
            }
            this.btnTemplate = null;
         }
         if(this.templatesHolder)
         {
            if(this.templatesHolder.parent)
            {
               this.templatesHolder.parent.removeChild(this.templatesHolder);
            }
            this.templatesHolder = null;
         }
         this.viewStack.cache = true;
         this.bar.addEventListener(IndexEvent.INDEX_CHANGE,this.onTabBarIndexChanged,false,0,true);
         this.viewStack.addEventListener(ViewStackEvent.VIEW_CHANGED,this.onSectionViewShowed,false,0,true);
      }

      private function onSectionViewShowed(param1:ViewStackEvent) : void {
         var _loc2_:String = this._sectionsDataUtil.getAliasByLinkage(param1.linkage);
         if(!isFlashComponentRegisteredS(_loc2_))
         {
            registerFlashComponentS(IDAAPIModule(param1.view),_loc2_);
         }
      }

      override protected function draw() : void {
         var _loc1_:Array = null;
         var _loc2_:uint = 0;
         var _loc3_:Array = null;
         var _loc4_:Object = null;
         var _loc5_:* = 0;
         var _loc6_:* = 0;
         super.draw();
         if((isInvalid(INIT_DATA_INV)) && (this.initData))
         {
            _loc1_ = this.initData.sectionsData;
            _loc2_ = _loc1_.length;
            _loc3_ = [];
            _loc5_ = -1;
            _loc6_ = 0;
            while(_loc6_ < _loc2_)
            {
               _loc4_ = _loc1_[_loc6_];
               _loc3_.push(
                  {
                     "label":_loc4_.label,
                     "alias":_loc4_.alias,
                     "linkage":this._sectionsDataUtil.register(_loc4_.alias),
                     "tooltip":_loc4_.tooltip
                  }
               );
               if(_loc4_.alias == Aliases.PROFILE_AWARDS)
               {
                  _loc5_ = _loc6_;
               }
               _loc6_++;
            }
            this.bar.dataProvider = new DataProvider(_loc3_);
            this.bar.selectedIndex = _loc5_;
            this.bar.selectedIndex = 0;
         }
         if(isInvalid(InvalidationType.SIZE))
         {
            invalidate(OFFSET_INVALID);
         }
         if(isInvalid(OFFSET_INVALID))
         {
            this.bar.x = Math.round(_width / 2 - this._centerOffset);
            this.viewStack.centerOffset = this._centerOffset;
         }
      }

      private function onTabBarIndexChanged(param1:IndexEvent) : void {
         this.viewStack.show(this._sectionsDataUtil.getLinkageByAlias(param1.data.alias));
      }

      public function as_setInitData(param1:Object) : void {
         this.initData = new ProfileMenuInfoVO(param1);
         invalidate(INIT_DATA_INV);
      }

      override protected function onDispose() : void {
         if(this.initData)
         {
            this.initData.dispose();
            this.initData = null;
         }
         super.onDispose();
         this.viewStack.dispose();
      }

      public function setAvailableSize(param1:Number, param2:Number) : void {
         this.viewStack.setAvailableSize(param1,param2 - this.viewStack.y);
         setSize(param1,param2);
      }

      public function set centerOffset(param1:int) : void {
         this._centerOffset = param1;
         invalidate(OFFSET_INVALID);
      }
   }

}